from dataclasses import dataclass
from constants.response_messages import ResponseMessages

@dataclass
class Message:
    role: str
    content: str

    def __post_init__(self):
        assert self.role in ["system", "user", "assistant"], ResponseMessages.INVALID_MESSAGE_FORMAT.value
        assert self.content is not None, ResponseMessages.INVALID_MESSAGE_FORMAT.value

    def to_dict(self):
        return {
            "role": self.role,
            "content": self.content,
        }
