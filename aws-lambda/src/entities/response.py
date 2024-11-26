from dataclasses import dataclass
import json
from typing import Optional

@dataclass
class ApiResponse:
    """Standardized API response handler"""
    status_code: int = 200
    body: dict = None

    def to_dict(self) -> dict:
        response = {
            "statusCode": self.status_code,
            "body": json.dumps(self.body or {})
        }
        return response

    @classmethod
    def success(cls, data: Optional[dict] = None) -> dict:
        body = {"outcome": "success"}
        if data:
            body.update(data)
        return cls(
            status_code=200,
            body=body
        ).to_dict()

    @classmethod
    def error(cls, message: str = "", status_code: int = 500) -> dict:
        return cls(
            status_code=status_code,
            body={"outcome": "failure", "error": message}
        ).to_dict()