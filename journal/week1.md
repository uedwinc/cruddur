# Setting Up and Architecture

## Architecture Design using Lucidchart

![Cruddur Architecture](/_docs/assets/cruddur-architecture.png)

## Setting up Gitpod

1. Launch the github repo on gitpod

2. First install aws cli in the workspace directory following standard procedure here for linux: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html

3. Configure AWS using environmental variables: https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-envvars.html

4. Persist the environment variables using:

  ```
  gp env AWS_ACCESS_KEY_ID="your-access-key-id"
  gp env AWS_SECRET_ACCESS_KEY="your-secret-access-key"
  gp env AWS_DEFAULT_REGION="your-region"
  ```

5. Confirm configuration with some basic cli commands:

- To enable aws cli auto-promt, use `aws --cli-auto-prompt`

- To see user info, use `aws sts get-caller-identity`

- To get only a section, say Account, `aws sts get-caller-identity --query Account`

- To remove the parenthesis `aws sts get-caller-identity --query Account --output text`

- If you want to add this to environment variables, use `export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)`

- You can save to gitpod env variables using `gp env AWS_ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"`

- See https://awscli.amazonaws.com/v2/documentation/api/latest/reference/index.html for other cli queries

6. Next, configure gitpod with some startup tasks. Create and update the `.gitpod.yml` file with the following code to install aws-cli:

```
tasks:
  - name: aws-cli
    env:
      AWS_CLI_AUTO_PROMPT: on-partial
    before: |
      cd /workspace
      curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
      unzip awscliv2.zip
      sudo ./aws/install
      cd $THEIA_WORKSPACE_ROOT
```

## Setup Billing

### 1. Using CloudFormation

1. First create an s3 bucket for all your CloudFormation templates

```sh
aws s3api create-bucket \
  --bucket crd-cfn-artifacts \
  --region us-east-2 \
  --create-bucket-configuration LocationConstraint=us-east-2
```

2. Create the [budget template](/aws/cfn/budget/template.yaml) and the [alarm template](/aws/cfn/alarm/template.yaml).

3. Run the following commands to deploy:

```sh
aws cloudformation deploy \
  --stack-name crd-budget \
  --s3-bucket crd-cfn-artifacts \
  --s3-prefix budget \
  --region $AWS_DEFAULT_REGION \
  --template-file /workspace/cruddur/aws/cfn/budget/template.yaml \
  --no-execute-changeset \
  --tags group=cruddur-budget
```

```sh
aws cloudformation deploy \
  --stack-name crd-alarm \
  --s3-bucket crd-cfn-artifacts \
  --s3-prefix alarm \
  --region $AWS_DEFAULT_REGION \
  --template-file /workspace/cruddur/aws/cfn/alarm/template.yaml \
  --no-execute-changeset \
  --tags group=cruddur-alarm
```

4. Go to the CloudFormation console and execute the changeset to deploy the resources (this is only because we added the `--no-execute-changeset` flag) in the deployment command. You can remove to deploy directly.

- Make sure to either confirm SNS subscription for billing-alarm on the console or open the mail received for the subscription and confirm.

