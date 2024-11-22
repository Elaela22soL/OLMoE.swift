import os
import json
from dataclasses import dataclass, field
import boto3  # type: ignore
import uuid
from datetime import datetime
from attestation import verify_attest

from pyattest.configs.apple import AppleConfig
from pyattest.attestation import Attestation, PyAttestException

# Initialize S3 client
s3 = boto3.client("s3")

# Configure these variables
BUCKET_NAME = os.environ['BUCKET_NAME']
S3_LOG_PREFIX = os.environ['S3_LOG_PREFIX']
S3_SHARE_PREFIX = os.environ['S3_SHARE_PREFIX']

with open("chat_template.html", "r") as f:
    CHAT_TEMPLATE = f.read()

@dataclass
class Message:
    role: str
    content: str

    def __post_init__(self):
        assert self.role in ["system", "user", "assistant"], "Invalid role"
        assert self.content is not None, "Content is required"

    def to_dict(self):
        return {
            "role": self.role,
            "content": self.content,
        }


@dataclass
class Trace:
    created: int
    model: str
    messages: list[Message]

    # default is to have server assign ID and object
    id: str = field(default_factory=lambda: str(uuid.uuid4()))
    object: str = "chat.trace"

    # we will derive this from the model if not provided
    system_fingerprint: str | None = None

    # these two are for compatibility with the openai format
    choices: list[dict] = field(default_factory=list)
    usage: dict = field(default_factory=dict)

    def __post_init__(self):
        assert len(self.messages) > 0, "Messages are required"
        self.messages = [Message(**message) for message in self.messages]

        self.system_fingerprint = self.system_fingerprint or self.model

        assert isinstance(self.created, int), "Created must be an int"
        try:
            datetime.fromtimestamp(self.created)
        except (ValueError, TypeError, OverflowError):
            raise ValueError(f"Invalid timestamp: {self.created}")

        assert isinstance(self.choices, list), "Choices must be a list"
        assert all(isinstance(choice, dict) for choice in self.choices), "Each choice must be a dict"
        assert isinstance(self.usage, dict), "Usage must be a dict"
        assert isinstance(self.model, str), "Model must be a string"
        assert isinstance(self.id, str), "ID must be a string"
        assert isinstance(self.object, str), "Object must be a string"
        assert isinstance(self.system_fingerprint, str), "System fingerprint must be a string"

    @classmethod
    def from_dict(cls, log: dict):
        return cls(**log)

    def to_dict(self):
        return {
            "messages": [message.to_dict() for message in self.messages],
            "created": self.created,
            "model": self.model,
            "id": self.id,
            "object": self.object,
            "system_fingerprint": self.system_fingerprint,
            **({"choices": self.choices} if self.choices else {}),
            **({"usage": self.usage} if self.usage else {}),
        }


def lambda_handler(event, context):
    try:
        key_id = event.get('key_id')
        attestation_object = event.get('attestation_object')
        
        if not verify_attest(key_id, attestation_object):
            return {"statusCode": 500, "body": json.dumps({"outcome": "failure", "error": "Attestation verification failed"})}
        
        body = { k:v for k,v in event.items() if k not in ['key_id', 'attestation_object'] }

        # Extract logs from the event
        parsed_log = Trace.from_dict(body)
        url = write_to_s3(parsed_log)
        status_code = 200
        body = {
            "outcome": "success",
            "error": None,
            "url": url,
        }
    except Exception as e:
        status_code = 500
        body = {
            "outcome": "failure",
            "error": f"{type(e).__name__}: {e}",
            "url": None,
        }

    return {"statusCode": status_code, "body": json.dumps(body)}


def write_to_s3(log: Trace):
    # Get the date from the log timestamp
    date_prefix = datetime.fromtimestamp(log.created).date().strftime("%Y%m%d")
    data_key = f"{S3_LOG_PREFIX}/{log.system_fingerprint}/{date_prefix}/{log.id}.json"
    # Convert batch to JSON string
    s3.put_object(Bucket=BUCKET_NAME, Key=data_key, Body=json.dumps(log.to_dict()), ContentType="application/json")

    # render html
    html = CHAT_TEMPLATE.replace("[[ADD_JSON_HERE]]", json.dumps(log.to_dict()))
    html_key = f"{S3_SHARE_PREFIX}/{log.system_fingerprint}/{date_prefix}/{log.id}.html"
    s3.put_object(Bucket=BUCKET_NAME, Key=html_key, Body=html, ContentType="text/html")

    return f"https://{BUCKET_NAME}.s3.amazonaws.com/{html_key}"
