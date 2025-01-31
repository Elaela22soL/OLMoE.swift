"""
Module for defining the Message class.
"""
from dataclasses import dataclass
from constants.response_messages import ResponseMessages


@dataclass
class Message:
    """
    Represents a message in a conversation.
    """
    role: str
    content: str

    def __post_init__(self):
        """
        Validate the message role and content.
        """
        assert self.role in [
            "system", "user", "assistant"], ResponseMessages.INVALID_MESSAGE_FORMAT.value
        assert self.content is not None, ResponseMessages.INVALID_MESSAGE_FORMAT.value

    def to_dict(self):
        """
        Convert the message to a dictionary.
        """
        return {
            "role": self.role,
            "content": self.content,
        }
