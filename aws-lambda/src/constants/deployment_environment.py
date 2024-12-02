import os
from enum import Enum

class DeploymentEnvironment(Enum):
    PROD = "prod"
    DEV = "dev"
    TEST = "test"

    @classmethod
    def from_env(cls, default="prod"):
        """
        Reads the specified environment variable and converts it to an Environment enum.
        Falls back to the default if the variable is not set or invalid.
        """
        env_value = os.environ.get('ENV', default)
        try:
            return cls(env_value)  # Convert to enum
        except ValueError:
            return cls(default)