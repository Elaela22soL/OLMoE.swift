# AWS Lambda to enable logging to S3

## Setup

1. Install AWS CLI
2. Configure AWS CLI with your profile; in this case, `llm`
3. Install Docker
4. Install SAM CLI:

```sh
pip install --upgrade aws-sam-cli
```

## Set environment variables

```sh
cp .env.example.json .env.json
```

Copy and paste env vars from 1Password into `.env.json`

## Run locally

First, build the image:

```sh
AWS_PROFILE=llm sam build
```

or if you are using vscode press `Cmd + Shift + B`

Then, run the lambda locally:

```shell
AWS_PROFILE=llm sam local invoke OlmoeAttestS3LoggingFunction -e tests/prod_attest.json --parameter-overrides $(cat .env.json | jq -r 'to_entries | map("\(.key)=\(.value|tostring)") | .[]')
```

If you are using vscode, you can simply run the Test tasks with `Cmd + Shift + P` -> "Run Task"

## Deploy

First make sure to build the lambda before deploying. THen if you have not deployed before, that means you don't have a samconfig.toml file, you will need to deploy using the `--guided` flag:

. Then:
```sh
AWS_PROFILE=llm sam deploy --guided --parameter-overrides $(cat .env.json | jq -r 'to_entries | map("\(.key)=\(.value|tostring)") | .[]')
```

After that, a `samconfig.toml` is generated, you can now deploy changes to the source code normally:

```sh
AWS_PROFILE=llm sam deploy --parameter-overrides $(cat .env.json | jq -r 'to_entries | map("\(.key)=\(.value|tostring)") | .[]')
```

Alternatively you can simply call the vscode task to deploy

## API Gateway Spec

You can log traces from any application using the API Gateway endpoint.

- **Method**: POST
- **URL**: <https://ziv3vcg14i.execute-api.us-east-1.amazonaws.com/prod>
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

## Example request with cURL

```sh
export API_KEY="YOUR_API_KEY"
export API_URL="https://ziv3vcg14i.execute-api.us-east-1.amazonaws.com/prod"

curl -X POST ${API_URL} \
    -H "x-api-key: ${API_KEY}" \
    -H "Content-Type: application/json" \
    -d '{"model": "model-name-here", "created": 1818857600, "messages": [{"role": "user", "content": "Hello, how are you?"}, {"role": "assistant", "content": "I am well, thanks! What can I help you with today?"}]}'
```
