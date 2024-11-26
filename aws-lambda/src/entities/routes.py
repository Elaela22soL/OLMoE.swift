
from enum import Enum
from typing import Dict, Any

class Route(Enum):
    WRITE_TRACE_TO_S3 = "write_trace_to_s3"
    ISSUE_CHALLENGE = "issue_challenge"

class LambdaRouter:
    @staticmethod
    def get_route(event: Dict[str, Any]) -> Route:
        if 'attestation_object' not in event:
            return Route.ISSUE_CHALLENGE
        return Route.WRITE_TRACE_TO_S3