"""
Module for defining the Route enum and LambdaRouter class.
"""
from enum import Enum
from typing import Dict, Any


class Route(Enum):
    WRITE_TRACE_TO_S3 = "write_trace_to_s3"
    ISSUE_CHALLENGE = "issue_challenge"


class LambdaRouter:
    """
    Class for routing requests to the appropriate handler.
    """
    @staticmethod
    def get_route(event: Dict[str, Any]) -> Route:
        """
        Get the route for the request.

        Args:
            event (Dict[str, Any]): The event data containing the request information.

        Returns:
            Route: The route enum value.
        """
        if 'attestation_object' not in event:
            return Route.ISSUE_CHALLENGE
        return Route.WRITE_TRACE_TO_S3
