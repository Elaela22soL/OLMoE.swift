# AWS Lambda to enable logging to S3

- [Requirements](#requirements)
- [Setup](#setup)
  - [AWS CLI and SAM CLI](#aws-cli-and-sam-cli)
  - [Environment Variables](#environment-variables)
- [Build](#build)
- [Testing and Local Invoke](#testing-and-local-invoke)
- [Deploy](#deploy)

# Requirements
- Python 3.11
- AWS Account with configured credentials
- AWS CLI
- AWS SAM CLI (aws-sam-cli)
- Docker
- S3 Bucket to store chat traces

# Setup

## AWS CLI and SAM CLI

1. Install [AWS CLI](https://aws.amazon.com/cli/)
2. Log in and configure the default profile for the AWS CLI.
3. Install either Docker or OrbStack
4. Install SAM CLI:

```sh
pip install --upgrade aws-sam-cli
```

## Environment variables

1. Create an .env.json file by copying the provided example JSON file:
```sh
cp .env.example.json .env.json
```

2. The following environment variables need to be set in the `.env.json` file:

|Variable|Data Type|Default|Description|
|---|---|---|---|
|`BucketName`|String|None|The name of the S3 bucket where the shared conversation traces will be stored.|
|`S3LogPrefix`|String|"logs"|The prefix for log files in the S3 bucket.|
|`S3SharePrefix`|String|"share"|The prefix for shared files in the S3 bucket.|
|`CertificateAsBytes`|String|None|Apple App Attestation Root CA, added to `.env.json` as a single line of text without comments or newlines.|
|`AppId`|String|None|The application ID in the format `{DEVELOPMENT_TEAM_ID}.{PRODUCT_BUNDLE_IDENTIFIER}`. To obtain these values, open file `OLMoE.swift.xcodeproj/project.pbxproj` and search for `DEVELOPMENT_TEAM`, you'll find a 10 characters long alphanumeric id i.e, ABC1234567. Search for `PRODUCT_BUNDLE_IDENTIFIER`, you should have a bundle identifier in this format: com.domain.app_name. Your `AppId` environment variable value is the concatenation of these two ids joined by a period. For example: "ABC1234567.com.domain.app_name"|
|`HmacShaKey`|String|None|The HMAC SHA key for signing Apple Attest challenges.|
|`Env`|String|"prod"|The environment (e.g., `prod` or `dev`).|
|`MaxRequestSizeBytes`|Integer|50KB|The maximum allowed request size in bytes.|                                                                                                               |

## Build

1. Before deploying or invoking the lambda locally you need to build using SAM CLI:
```sh
sam build
```

Alternatively, if you are using vscode press `Cmd + Shift + B` to build

2. Then make sure package dependencies are installed by running:
```sh
pip install -r src/requirements.txt -t .aws-sam/build
```
Install packages only once, run again if you make changes to `src/requirements.txt`

# Testing and Local invoke

This projects implements [Apples Attestation](https://developer.apple.com/documentation/devicecheck/establishing-your-app-s-integrity) to establish application integrity to ensure that requests our lambda receives come from legitimate instances of our app.

[![attest/challenge flow](https://github.com/user-attachments/assets/d532612b-41de-4cf6-af8b-c443a94686b9)](https://developer.apple.com/documentation/devicecheck/establishing-your-app-s-integrity)

There are two execution paths for the lambda that can be tested separately

1. Get the Attest Challenge

If you are using vscode, you can simply run the Test tasks with `Cmd + Shift + P` -> `Run Task` -> `Test GetChallenge`

Or manually run:
```shell
sam local invoke OlmoeAttestS3LoggingFunction -e tests/get_challenge.json --parameter-overrides $(cat .env.test.json | jq -r 'to_entries | map("\(.key)=\(.value|tostring)") | .[]')
```

2. Share conversation trace

`Cmd + Shift + P` -> `Run Task` -> `Test ShareTrace`

Manual execution:
```shell
sam local invoke OlmoeAttestS3LoggingFunction -e tests/prod_attest.json --parameter-overrides $(cat .env.test.json | jq -r 'to_entries | map("\(.key)=\(.value|tostring)") | .[]')
```

# Deploy

First make sure to build the lambda before deploying. Then if you have not deployed before, that means you don't have a samconfig.toml file, you will need to deploy using the `--guided` flag:

. Then:
```sh
sam deploy --guided --parameter-overrides $(cat .env.json | jq -r 'to_entries | map("\(.key)=\(.value|tostring)") | .[]')
```

After that, a `samconfig.toml` is generated, you can now deploy changes to the source code normally:

`Cmd + Shift + P` -> `Run Task` -> `Deploy Lambda`

Manual execution:
```sh
sam deploy --parameter-overrides $(cat .env.json | jq -r 'to_entries | map("\(.key)=\(.value|tostring)") | .[]')
```
