import uuid
from dataclasses import dataclass, field
from datetime import datetime

from .message import Message

@dataclass
class Trace:
    created: int
    model: str
    messages: list[Message]

    # default is to have server assign ID and object
    id: str = field(default_factory=lambda: str(uuid.uuid4()))
    object: str = "chat.trace"

    # we will derive this from the model if not provided
    system_fingerprint: str | None = None

    # these two are for compatibility with the openai format
    choices: list[dict] = field(default_factory=list)
    usage: dict = field(default_factory=dict)

    def __post_init__(self):
        assert len(self.messages) > 0, "Invalid trace format"
        self.messages = [Message(**message) for message in self.messages]

        self.system_fingerprint = self.system_fingerprint or self.model

        assert isinstance(self.created, int), "Invalid trace format"
        try:
            datetime.fromtimestamp(self.created)
        except (ValueError, TypeError, OverflowError):
            raise ValueError(f"Invalid timestamp: {self.created}")

        assert isinstance(self.choices, list), "Invalid trace format"
        assert all(isinstance(choice, dict) for choice in self.choices), "Invalid trace format"
        assert isinstance(self.usage, dict), "Invalid trace format"
        assert isinstance(self.model, str), "Invalid trace format"
        assert isinstance(self.id, str), "Invalid trace format"
        assert isinstance(self.object, str), "Invalid trace format"
        assert isinstance(self.system_fingerprint, str), "Invalid trace format"

    @classmethod
    def from_dict(cls, log: dict):
        return cls(**log)

    def to_dict(self):
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