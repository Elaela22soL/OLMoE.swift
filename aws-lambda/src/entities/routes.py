
from enum import Enum
from typing import Dict, Any

class Route(Enum):
    WRITE_TRACE_TO_S3 = "write_trace_to_s3"
    GENERATE_CHALLENGE = "generate_challenge"

class LambdaRouter:
    @staticmethod
    def route(event: Dict[str, Any]) -> Route:
        if 'attestation_object' not in event:
            return Route.GENERATE_CHALLENGE
        return Route.WRITE_TRACE_TO_S3