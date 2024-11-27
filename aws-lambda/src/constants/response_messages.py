"""
This enum class contains all the response messages that are used in the lambda functions.
"""
from enum import Enum
from typing import Dict, Any

class ResponseMessages(Enum):
    # Success messages
    OUTCOME_SUCCESS = "success"

    # Error messages
    OUTCOME_FAILURE = "failure"
    INVALID_MESSAGE_FORMAT = "Invalid message format"
    INVALID_TRACE_FORMAT = "Invalid trace format"
    ERROR_VERIFYING_ATTESTATION = "Error verifying attestation"
    ERROR_PARSING_ATTESTATION = "Error while parsing attestation object"
    INVALID_REQUEST_BODY = "Invalid request body"
    INVALID_KEY_ID = "Invalid key_id"
    FAILED_TO_GENERATE_CHALLENGE = "Failed to generate challenge"
    ATTESTATION_VERIFICATION_FAILED = "Attestation verification failed"

    @classmethod
    def format(cls, message: 'ResponseMessages', **kwargs: Dict[str, Any]) -> str:
        """Format message with dynamic values"""
        return message.value.format(**kwargs)
