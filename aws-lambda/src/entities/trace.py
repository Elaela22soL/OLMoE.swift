"""
Module for defining the Trace class.
"""
import uuid
from dataclasses import dataclass, field
from datetime import datetime
from constants.response_messages import ResponseMessages

from .message import Message


@dataclass
class Trace:
    """
    Represents a trace of a conversation.
    """
    created: int
    model: str
    messages: list[Message]

    # Default is to have server assign ID and object
    id: str = field(default_factory=lambda: str(uuid.uuid4()))
    object: str = "chat.trace"

    # Derived from the model if not provided
    system_fingerprint: str | None = None

    # These two are for compatibility with the openai format
    choices: list[dict] = field(default_factory=list)
    usage: dict = field(default_factory=dict)

    def __post_init__(self):
        """
        Validate the trace data.
        """
        assert len(self.messages) > 0, ResponseMessages.INVALID_TRACE_FORMAT.value
        self.messages = [Message(**message) for message in self.messages]

        self.system_fingerprint = self.system_fingerprint or self.model

        assert isinstance(
            self.created, int), ResponseMessages.INVALID_TRACE_FORMAT.value
        try:
            datetime.fromtimestamp(self.created)
        except (ValueError, TypeError, OverflowError) as exc:
            raise ValueError(
                ResponseMessages.INVALID_TRACE_FORMAT.value) from exc

        assert isinstance(
            self.choices, list), ResponseMessages.INVALID_TRACE_FORMAT.value
        assert all(isinstance(choice, dict)
                   for choice in self.choices), ResponseMessages.INVALID_TRACE_FORMAT.value
        assert isinstance(
            self.usage, dict), ResponseMessages.INVALID_TRACE_FORMAT.value
        assert isinstance(
            self.model, str), ResponseMessages.INVALID_TRACE_FORMAT.value
        assert isinstance(
            self.id, str), ResponseMessages.INVALID_TRACE_FORMAT.value
        assert isinstance(
            self.object, str), ResponseMessages.INVALID_TRACE_FORMAT.value
        assert isinstance(self.system_fingerprint,
                          str), ResponseMessages.INVALID_TRACE_FORMAT.value

    @classmethod
    def from_dict(cls, log: dict):
        """
        Create a Trace object from a dictionary.

        Args:
            log (dict): The dictionary containing the trace data.

        Returns:
            Trace: The Trace object.
        """
        return cls(**log)

    def to_dict(self):
        """
        Convert the Trace object to a dictionary.
        """
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
