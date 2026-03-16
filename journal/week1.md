# Setting Up and Architecture

## Architecture Design using Lucidchart

![Cruddur Architecture](/_docs/assets/cruddur-architecture.png)

## Setting up Gitpod

1. Launch the github repo on gitpod

2. First install aws cli in the workspace directory following standard procedure here for linux: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html

3. Configure AWS using environmental variables: https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-envvars.html

4. Persist the environment variables using:

```sh
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

6. Next, configure gitpod with some startup tasks. These include, installing aws-cli, aws-sam, etc.

7. Setup Gitpod to use TOML configuration files for CloudFormation

- Use CFN-TOML (https://github.com/teacherseat/cfn-toml) to execute Toml Configuration for Bash scripts using CloudFormation. This allows us to store bash script variables and CloudFormation parameters in a `.toml` file

- Add cfn-toml installation to `.gitpod.yml` file to always run at startup

```sh
gem install cfn-toml
```

## Setup CloudFormation

- Create a new directory to hold cloudformation templates: aws/cfn/
- Add file: template.yaml

- You can use this command to validate template syntax:
```sh
aws cloudformation validate-template --template-body file:///workspace/aws-bootcamp-cruddur-2023/aws/cfn/template.yaml
```

---
- You can also use cfn-lint to validate template:

Install: `pip install cfn-lint`
Check: `cfn-lint`
To validate a file: `cfn-lint -t /workspace/aws-bootcamp-cruddur-2023/aws/cfn/template.yaml`

- Add the command to install cfn-lint in _.gitpod.yml_
---

- There is also CloudFormation guard, a policy-as-code evaluation tool, used to write rules and validate JSON- and YAML-formatted data such as CloudFormation Templates, K8s configurations, and Terraform JSON plans/configurations against those rules.
- To install: cargo install cfn-guard
  - Add to .gitpod.yml

- Create the following policy as code guard files: aws/cfn/task-definition.guard

- Read-up on cfn-guard and try to implement it********************************************************

---

- You can use application composer or cloudformation designer to generate cfn template

- Create new directory and file: bin/cfn/cluster
- The _--no-execute-changeset_ flag in the deployment command allows you to manually review and authorize changes before they are created.
- Go to CloudFormation > Stacks > cluster-name
  - Under 'Change set' tab, click into the change set and click 'Execute change set'

- You can go to Cloudtrail and see logs of all the events in CloudTrail > Event history > event-name

//You can use Stacksets on CloudFormation console to deploy across multiple regions and accounts//

- Create an s3 bucket to contain all of our artifacts for CloudFormation and adjust bin/cfn/cluster to use the bucket

```sh
aws s3 mk s3://cfn-artifacts
export CFN_BUCKET="cfn-artifacts"
gp env CFN_BUCKET="cfn-artifacts"
```
> Remember bucket names are unique





First create an s3 bucket for all your CloudFormation templates

```sh
aws s3api create-bucket \
  --bucket crd-cfn-artifacts \
  --region us-east-2 \
  --create-bucket-configuration LocationConstraint=us-east-2
```

## Setup Billing

### 1. Using CloudFormation

1. Create the [budget template](/aws/cfn/budget/template.yaml) and the [alarm template](/aws/cfn/alarm/template.yaml).

2. Run the following commands to deploy:

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

3. Go to the CloudFormation console and execute the changeset to deploy the resources (this is only because we added the `--no-execute-changeset` flag) in the deployment command. You can remove to deploy directly.

- Make sure to either confirm SNS subscription for billing-alarm on the console or open the mail received for the subscription and confirm.

![sns-subscribe](/images/sns-subscribe.png)

### 2. Using the CLI

#### Configure budget and notification

1. Follow examples here: https://docs.aws.amazon.com/cli/latest/reference/budgets/create-budget.html#examples

2. Create [budget.json](/aws/json/budget.json) and [budget-notifications-with-subscribers.json](/aws/json/budget-notifications-with-subscribers.json)

3. Confirm AWS_ACCOUNT_ID env variable is set

4. Run the following command

```sh
aws budgets create-budget \
  --account-id $AWS_ACCOUNT_ID \
  --budget file://aws/json/budget.json \
  --notifications-with-subscribers file://aws/json/budget-notifications-with-subscribers.json
```
5. Confirm on the console

#### Configure CloudWatch Alarm

1. First create an SNS Topic

```sh
aws sns create-topic --name billing-alarm
```

- This will return a TopicARN

2. Next, we'll create a subscription by supplying the TopicARN and our Email

```sh
aws sns subscribe \
  --topic-arn TopicARN \
  --protocol email \
  --notification-endpoint your@email.com
```

3. You can either confirm subscription for SNS on the Amazon SNS console or open the mail received for the subscription and confirm.

4. Create an [alarm-config.json](/aws/json/alarm-config.json) file

- Follow doc here: https://repost.aws/knowledge-center/cloudwatch-estimatedcharges-alarm

5. Run the following command to create the alarm:

```sh
aws cloudwatch put-metric-alarm --cli-input-json file://aws/json/alarm-config.json
```

6. Go to Cloudwatch to confirm