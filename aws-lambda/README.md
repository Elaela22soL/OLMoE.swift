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
sam build
```

Then, run the lambda locally:

```shell
AWS_PROFILE=llm sam local invoke S3LoggingFunction -e tests/test_event.json
```
