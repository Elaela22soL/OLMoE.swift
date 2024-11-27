from dataclasses import dataclass

@dataclass
class Message:
    role: str
    content: str

    def __post_init__(self):
        assert self.role in ["system", "user", "assistant"], "Invalid message format"
        assert self.content is not None, "Invalid message format"

    def to_dict(self):
        return {
            "role": self.role,
            "content": self.content,
        }
