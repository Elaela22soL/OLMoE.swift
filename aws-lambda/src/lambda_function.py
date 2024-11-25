import os
import json
import secrets
import hashlib
import hmac
from datetime import datetime
import base64
import boto3  # type: ignore
from attestation import verify_attest

from entities.trace import Trace
from entities.routes import LambdaRouter, Route

# Initialize S3 client
s3 = boto3.client("s3")

# Configure these variables
BUCKET_NAME = os.environ['BUCKET_NAME']
S3_LOG_PREFIX = os.environ['S3_LOG_PREFIX']
S3_SHARE_PREFIX = os.environ['S3_SHARE_PREFIX']

with open("chat_template.html", "r") as f:
    CHAT_TEMPLATE = f.read()

def lambda_handler(event, context):
    try:
        route = LambdaRouter.route(event)

        match route:
            case Route.GENERATE_CHALLENGE:
                return generate_challenge(event)
            case Route.WRITE_TRACE_TO_S3:
                return write_to_s3(event)
            case _:
                return {
                    "statusCode": 500,
                    "body": json.dumps({
                        "outcome": "failure",
                        "error": "Invalid request body"
                    })
                }
    except Exception as e:
        return {
            "statusCode": 500,
            "body": json.dumps({
                "outcome": "failure",
                "error": f"{type(e).__name__}: {e}"
            })
        }

    # return {"statusCode": status_code, "body": json.dumps(body)}

def generate_challenge(event):
    """Generate a challenge for the given key_id"""
    key_id = event.get('key_id')
    if not key_id or not isinstance(key_id, str):
        return {
            "statusCode": 400,
            "body": json.dumps({"error": "Invalid key_id"})
        }

    try:
        random_bytes = secrets.token_bytes(32)
        secret_key = os.environ.get('HMAC_SHA_KEY')
        message = f"{key_id}:{random_bytes.hex()}".encode('utf-8')

        # Generate HMAC
        hmac_obj = hmac.new(
            key=secret_key.encode('utf-8'),
            msg=message,
            digestmod=hashlib.sha256
        )
        challenge = hmac_obj.hexdigest()
        challenge_base64 = base64.b64encode(bytes.fromhex(challenge)).decode('utf-8')

        return {
            "statusCode": 200,
            "body": json.dumps({
                "challenge": challenge_base64
            })
        }
    except Exception:
        return {
            "statusCode": 500,
            "body": json.dumps({
                "error": "Failed to generate challenge"
            })
        }


def write_to_s3(event):
    key_id = event.get('key_id')
    attestation_object = event.get('attestation_object')

    if not verify_attest(key_id, attestation_object):
            return {"statusCode": 500, "body": json.dumps({"outcome": "failure", "error": "Attestation verification failed"})}
        
    body = { k:v for k,v in event.items() if k not in ['key_id', 'attestation_object'] }

    # Extract logs from the event
    log = Trace.from_dict(body)
    
    # Get the date from the log timestamp
    date_prefix = datetime.fromtimestamp(log.created).date().strftime("%Y%m%d")
    data_key = f"{S3_LOG_PREFIX}/{log.system_fingerprint}/{date_prefix}/{log.id}.json"
    # Convert batch to JSON string
    s3.put_object(Bucket=BUCKET_NAME, Key=data_key, Body=json.dumps(log.to_dict()), ContentType="application/json")

    # render html
    html = CHAT_TEMPLATE.replace("[[ADD_JSON_HERE]]", json.dumps(log.to_dict()))
    html_key = f"{S3_SHARE_PREFIX}/{log.system_fingerprint}/{date_prefix}/{log.id}.html"
    s3.put_object(Bucket=BUCKET_NAME, Key=html_key, Body=html, ContentType="text/html")

    return {
        "statusCode": 200,
        "body": json.dumps({
            "outcome": "success",
            "error": None,
            "url": f"https://{BUCKET_NAME}.s3.amazonaws.com/{html_key}",
        })
    }