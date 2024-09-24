import json
import traceback
from dataclasses import dataclass, field
import boto3
import uuid
from datetime import datetime

# Initialize S3 client
s3 = boto3.client("s3")

# Configure these variables
BUCKET_NAME = "olmo-interactions-share"
S3_LOG_PREFIX = "logs"
S3_SHARE_PREFIX = "share"

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
class Metadata:
    # this is something like "iPhone15,2"
    device_id: str
    timestamp: datetime
    model_id: str
    server_id: str = field(default_factory=lambda: str(uuid.uuid4()))

    def __post_init__(self):
        assert self.device_id is not None, "Device ID is required"
        assert self.server_id is not None, "Server ID is required"
        assert self.timestamp is not None, "Timestamp is required"
        self.timestamp = datetime.fromisoformat(self.timestamp)
        assert self.model_id is not None, "Model ID is required"

    def to_dict(self):
        return {
            "device_id": self.device_id,
            "server_id": self.server_id,
            "model_id": self.model_id,
            "timestamp": self.timestamp.isoformat(),
        }


@dataclass
class LogEntry:
    messages: list[Message]
    metadata: Metadata

    def __post_init__(self):
        assert len(self.messages) > 0, "Messages are required"
        self.messages = [Message(**message) for message in self.messages]
        self.metadata = Metadata(**self.metadata)

    @classmethod
    def from_dict(cls, log: dict):
        return cls(**log)

    def to_dict(self):
        return {
            "messages": [message.to_dict() for message in self.messages],
            "metadata": self.metadata.to_dict(),
        }


def lambda_handler(event, context):
    try:
        # Extract logs from the event
        logs = event.get("logs", [])
        parsed_logs = [LogEntry.from_dict(log) for log in logs]
        url = write_to_s3(parsed_logs)
        status_code = 200
        body = json.dumps(
            {
                "outcome": "success",
                "error": None,
                "url": url,
            }
        )
    except Exception as e:
        status_code = 500
        body = json.dumps(
            {
                "outcome": type(e).__name__,
                "error": f"{str(e)}: {traceback.format_exc()}",
                "url": None,
            }
        )

    return {"statusCode": status_code, "body": body}


def write_to_s3(logs: list[LogEntry]):
    # Generate a unique filename
    for log in logs:
        # Get the date from the log timestamp
        date_prefix = log.metadata.timestamp.date().strftime("%Y%m%d")
        data_key = f"{S3_LOG_PREFIX}/{date_prefix}/{log.metadata.server_id}.json"
        # Convert batch to JSON string
        s3.put_object(
            Bucket=BUCKET_NAME, Key=data_key, Body=json.dumps(log.to_dict()), ContentType="application/json"
        )

        # render html
        html = CHAT_TEMPLATE.replace("[[ADD_JSON_HERE]]", json.dumps(log.to_dict()))
        html_key = f"{S3_SHARE_PREFIX}/{date_prefix}/{log.metadata.server_id}.html"
        s3.put_object(Bucket=BUCKET_NAME, Key=html_key, Body=html, ContentType="text/html")

        return f"https://{BUCKET_NAME}.s3.amazonaws.com/{html_key}"
