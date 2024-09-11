# Decentralized Authentication

Using Amazon Cognito

## 1. Setup Lambda Layer

[A Lambda layer is a .zip file archive that contains supplementary code or data. Layers usually contain library dependencies, a custom runtime, or configuration files.](https://docs.aws.amazon.com/lambda/latest/dg/chapter-layers.html)

Here, we will be using [psycopg2](https://pypi.org/project/psycopg2/). Psycopg is a popular PostgreSQL database adapter for the Python programming language.

### For Development

**OPTION 1:** There is a custom compiled psycopg2 C library for Python. Due to AWS Lambda missing the required PostgreSQL libraries in the AMI image, we needed to compile psycopg2 with the PostgreSQL libpq.so library statically linked libpq library instead of the default dynamic link.

This is found at https://github.com/AbhimanyuHK/aws-psycopg2

You can package this into a layer and create following these instructions:

- https://docs.aws.amazon.com/lambda/latest/dg/chapter-layers.html
- https://docs.aws.amazon.com/lambda/latest/dg/python-layers.html
- https://docs.aws.amazon.com/lambda/latest/dg/adding-layers.html

Copy the layer ARN using command from https://docs.aws.amazon.com/lambda/latest/dg/adding-layers.html#finding-layer-information and refernce in your template.

**OPTION 2:** Some precompiled versions of this layer are available publicly for AWS freely to add to your function by ARN reference.

https://github.com/jetbridge/psycopg2-lambda-layer

- Just go to Layers + in the function console and add a reference for your region

Example: `arn:aws:lambda:us-east-2:898466741470:layer:psycopg2-py38:1`

> In our case, we will add this ARN reference to the CloudFormation template for creating the Lambda function.

**OPTION 3:** Alternatively you can create your own development layer by downloading the psycopg2-binary source files from https://pypi.org/project/psycopg2-binary/#files

Download the package for the lambda runtime environment: [psycopg2_binary-2.9.5-cp311-cp311-manylinux_2_17_x86_64.manylinux2014_x86_64.whl](https://files.pythonhosted.org/packages/36/af/a9f06e2469e943364b2383b45b3209b40350c105281948df62153394b4a9/psycopg2_binary-2.9.5-cp311-cp311-manylinux_2_17_x86_64.manylinux2014_x86_64.whl)

Extract to a folder, then zip up that folder and upload as a new lambda layer to your AWS account

### For Production

Follow the instructions on https://github.com/AbhimanyuHK/aws-psycopg2 to compile your own layer from postgres source libraries for the desired version.

## 2. ## Setup Cognito Post Confirmation Lambda



## Provision Cognito User Pool

