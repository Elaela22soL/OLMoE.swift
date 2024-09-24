# AWS Lambda to enable logging to S3


## Setup

1. Install AWS CLI
2. Configure AWS CLI with your profile; in this case, `llm`
3. Install Docker
4. Install SAM CLI:

```shell
pip install --upgrade aws-sam-cli
```

## Run locally

First, build the image:

```shell
AWS_PROFILE=llm sam build
```

Then, run the lambda locally:

```shell
AWS_PROFILE=llm sam local invoke S3LoggingFunction -e tests/test_event.json
```

## Deploy

If you have not deployed before, you will need to deploy:

```shell
AWS_PROFILE=llm sam deploy --guided
```

After that, you can deploy changes with:

```shell
AWS_PROFILE=llm sam deploy
```

## API Gateway Spec

You can log traces from any application using the API Gateway endpoint.

- **Method**: POST
- **URL**: https://ziv3vcg14i.execute-api.us-east-1.amazonaws.com/prod
- **Body**:

```json
{
  "$schema": "http://json-schema.org/draft-04/schema#",
  "type": "object",
  "required": ["model", "created", "messages"],
  "properties": {
    "model": {
      "type": "string",
      "description": "The model name"
    },
    "created": {
      "type": "integer",
      "description": "Unix timestamp of when the trace was created"
    },
    "system_fingerprint": {
      "type": "string",
      "description": "The fingerprint of the system. If not provided, the model will be used."
    },
    "id": {
      "type": "string",
      "description": "The ID of the trace. If not provided, the server will assign a random UUID by the endpoint. Must be unique across all traces with the same fingerprint."
    },
    "object": {
      "type": "string",
      "default": "chat.trace",
      "description": "The object type. Defaults to `chat.trace`."
    },
    "messages": {
      "type": "array",
      "items": {
        "type": "object",
        "required": ["role", "content"],
        "properties": {
          "role": {
            "type": "string",
            "enum": ["system", "user", "assistant"],
            "description": "The role should be one of system, user, or assistant."
          },
          "content": {
            "type": "string",
            "description": "The content of the message."
          }
        }
      },
      "description": "An array of message objects."
    },
    "choices": {
      "type": "object",
      "description": "Field for compatibility with OpenAI's API."
    },
    "usage": {
      "type": "object",
      "description": "Field for compatibility with OpenAI's API."
    }
  }
}
```
