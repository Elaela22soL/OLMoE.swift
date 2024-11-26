import os
import json
from datetime import datetime
import boto3  # type: ignore

from attestation import verify_attest, generate_challenge
from entities.trace import Trace
from entities.routes import LambdaRouter, Route
from entities.response import ApiResponse

# Initialize S3 client
s3 = boto3.client("s3")

# Configure these variables
BUCKET_NAME = os.environ['BUCKET_NAME']
S3_LOG_PREFIX = os.environ['S3_LOG_PREFIX']
S3_SHARE_PREFIX = os.environ['S3_SHARE_PREFIX']

with open("chat_template.html", "r") as f:
    CHAT_TEMPLATE = f.read()

def lambda_handler(event, context):
    """
    Handle the incoming request, and route it to the appropriate handler
    """
    try:
        match LambdaRouter.get_route(event):
            case Route.ISSUE_CHALLENGE:
                return handle_issue_challenge(event)
            case Route.WRITE_TRACE_TO_S3:
                return handle_write_to_s3(event)
            case _:
                return ApiResponse.error("Invalid request body", 400)
    except Exception as e:
        return ApiResponse.error(f"{type(e).__name__}: {e}")

def handle_issue_challenge(event):
    """
    Respond to a request for a challenge
    """
    key_id = event.get('key_id')
    if not key_id or not isinstance(key_id, str):
        return ApiResponse.error("Invalid key_id", 400)

    try:
        challenge_base64 = generate_challenge(key_id)

        return ApiResponse.success({ "challenge": challenge_base64 })
    except Exception:
        return ApiResponse.error("Failed to generate challenge")

def handle_write_to_s3(event):
    """
    Respond to a request to write a trace to S3, and return a URL to the trace
    """
    key_id = event.get('key_id')
    attestation_object = event.get('attestation_object')

    if not verify_attest(key_id, attestation_object):
        return ApiResponse.error("Attestation verification failed")
        
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

    return ApiResponse.success({ "url": f"https://{BUCKET_NAME}.s3.amazonaws.com/{html_key}" })