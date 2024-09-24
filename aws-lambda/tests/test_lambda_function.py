import unittest
from unittest.mock import patch, MagicMock
import json
from src import lambda_function


class TestLambdaFunction(unittest.TestCase):
    @patch("src.lambda_function.s3")
    def test_lambda_handler(self, mock_s3):
        # Mock S3 put_object method
        mock_s3.put_object = MagicMock()

        # Test event
        test_event = {
            "logs": [
                {
                    "device_id": "device1",
                    "timestamp": 1632512345,
                    "messages": [
                        {"role": "system", "content": "You are a helpful assistant."},
                        {"role": "user", "content": "What is a LLM?"},
                    ],
                    "metadata": {"user_id": "user123", "session_id": "session456"},
                }
            ]
        }

        # Call lambda_handler
        result = lambda_function.lambda_handler(test_event, None)

        # Assert S3 put_object was called
        mock_s3.put_object.assert_called()

        # Assert the response is correct
        self.assertEqual(result["statusCode"], 200)
        self.assertEqual(json.loads(result["body"]), "Logs processed successfully")


if __name__ == "__main__":
    unittest.main()
