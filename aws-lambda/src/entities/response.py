"""
Module for defining the ApiResponse class.
"""
from dataclasses import dataclass
import json
from typing import Optional
from http import HTTPStatus
from constants.response_messages import ResponseMessages


@dataclass
class ApiResponse:
    """
    Standardized API response handler.
    """
    status_code: int = HTTPStatus.OK
    body: dict = None

    def to_dict(self) -> dict:
        """
        Convert the response to a dictionary.
        """
        response = {
            "statusCode": self.status_code,
            "body": json.dumps(self.body or {})
        }
        return response

    @classmethod
    def success(cls, data: Optional[dict] = None) -> dict:
        """
        Create a success response.

        Args:
            data (Optional[dict]): The data to include in the response.

        Returns:
            dict: The success response.
        """
        body = {"outcome": ResponseMessages.OUTCOME_SUCCESS.value}
        if data:
            body.update(data)
        return cls(
            status_code=HTTPStatus.OK,
            body=body
        ).to_dict()

    @classmethod
    def error(cls, message: str = "", status_code: int = HTTPStatus.INTERNAL_SERVER_ERROR) -> dict:
        """
        Create an error response.

        Args:
            message (str): The error message to include in the response.
            status_code (int): The HTTP status code to use for the response.

        Returns:
            dict: The error response.
        """
        return cls(
            status_code=status_code,
            body={"outcome": ResponseMessages.OUTCOME_FAILURE.value, "error": message}
        ).to_dict()
