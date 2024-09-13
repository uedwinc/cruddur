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

## 2. Setup Cognito Post Confirmation Lambda

We need to implement a custom authorizer for cognito. This is necessary because in setting up the user table (seed.sql), it requires a cognito user id. This will help verify a user at sign-up.

1. Create a Lambda function python file, [cruddur-post-confirmation.py](../aws/lambdas/cruddur-post-confirmation.py)

2. Create a CloudFormation lambda [template](../aws/cfn/lambda/template.yaml) to deploy the lambda fuction. 

- Paste the [cruddur-post-confirmation.py](../aws/lambdas/cruddur-post-confirmation.py) code as in-line code in the template. 

- Remember to reference the ARN from the lambda layer setup from the previous section. We used the one for us-east-2 from https://github.com/jetbridge/psycopg2-lambda-layer

- Set variable to 'CONNECTION_URL' and value as the "PROD_CONNECTION_URL" value.

- For VPCConfig, specify the network protocol details in the VPC where RDS was created since that will contain the security group with Postgres port opened.

## 3. Provision Cognito User Pool

- Create a [CloudFormation template](../aws/cfn/cognito/template.yaml) to deploy a Cognito user pool

- Write a [deployment script](../bin/cfn/cognito) for it

- Run the script to deploy Cognito user pool

```sh
chmod u+x /bin/cfn/cognito

bash /bin/cfn/cognito
```

- Execute the change-set on the console

### Install AWS Amplify

> This is not necessary as everything has been packaged with the code. If you do these, it may lead to version changes and incompatibility.

- See documentation: https://docs.amplify.aws/react/build-a-backend/auth/

```sh
cd frontend-react-js

npm i aws-amplify --save
```

- This adds `aws-amplify` to `package.json` and modifies `package-lock.json`

### Configure Amplify

1. We need to hook up our cognito pool to our code in the [App.js](../frontend-react-js/src/App.js) file

```js
import { Amplify } from 'aws-amplify';

Amplify.configure({
  "AWS_PROJECT_REGION": process.env.REACT_APP_AWS_PROJECT_REGION,
  "aws_cognito_region": process.env.REACT_APP_AWS_COGNITO_REGION,
  "aws_user_pools_id": process.env.REACT_APP_AWS_USER_POOLS_ID,
  "aws_user_pools_web_client_id": process.env.REACT_APP_CLIENT_ID,
  "oauth": {},
  Auth: {
    // We are not using an Identity Pool
    // identityPoolId: process.env.REACT_APP_IDENTITY_POOL_ID, // REQUIRED - Amazon Cognito Identity Pool ID
    region: process.env.REACT_APP_AWS_PROJECT_REGION,           // REQUIRED - Amazon Cognito Region
    userPoolId: process.env.REACT_APP_AWS_USER_POOLS_ID,         // OPTIONAL - Amazon Cognito User Pool ID
    userPoolWebClientId: process.env.REACT_APP_CLIENT_ID,   // OPTIONAL - Amazon Cognito Web Client ID (26-char alphanumeric string)
  }
});
```

2. Next, we need to configure the following as environment variables for frontend-react-js in the docker-compose file

```
REACT_APP_AWS_PROJECT_REGION
REACT_APP_AWS_COGNITO_REGION
REACT_APP_AWS_USER_POOLS_ID
REACT_APP_CLIENT_ID
```

To do this, we will Create `.env` files to hold our environment variables

- First, we need to store the env variables in `env.erb` files: [backend-flask.env.erb](../erb/backend-flask.env.erb) and [frontend-react-js.env.erb](../erb/frontend-react-js.env.erb)

- Next, we need to create ruby scripts that generate the envs: [/bin/backend/generate-env](../bin/backend/generate-env) and [/bin/frontend/generate-env](../bin/frontend/generate-env)

- When these files are run, they generate a `.env` file. We'll ignore that in `.gitignore`

- Give execute permission to the `generate-env` files

```sh
chmod u+x /bin/backend/generate-env
chmod u+x /bin/frontend/generate-env
```
- Add commands to generate-env at startup in `.gitpod.yml` file

```sh
ruby $THEIA_WORKSPACE_ROOT/bin/frontend/generate-env

ruby $THEIA_WORKSPACE_ROOT/bin/backend/generate-env
```

- In the docker-compose file, reference generated env file path as `env_file`

> Every other form of Cognito implementation (backend and frontend) has been done in the code. Including server side implementation like passing along the access_token, server side verification of the json web token (jwt) generated

For server side verification of the json web token (jwt) generated, we needed to:

- Add `Flask-AWSCognito` to [requirements.txt](../backend-flask/requirements.txt)

- `cd` into `backend-flask` and do `pip install -r requirements.txt`

- From the instructions (https://github.com/cgauge/Flask-AWSCognito), we need to set the following env variables in backend-flask of docker-compose

```yml
AWS_COGNITO_USER_POOL_ID: "us-east-2_xMATXNbsI"
AWS_COGNITO_USER_POOL_CLIENT_ID: "6lii3ennqt31pr8a1clgihnmbc"
```

- So add them to the [backend-flask.env.erb](../erb/backend-flask.env.erb) file

- The instrumentation for jwt verification is through the [cognito_jwt_token.py](../backend-flask/lib/cognito_jwt_token.py) file

- Doc: https://github.com/cgauge/Flask-AWSCognito/blob/master/flask_awscognito/services/token_service.py

---

In Develpment, you can do the following:

- Try to sign in to get an unauthorized (username and password error) error

- You can try to manually create a user on the AWS cognito console (you should get an email from cognito to verify that user) and sign in with the user details

- If it requires force-change-password, you can run this command on the cli to bypass
```sh
aws cognito-idp admin-set-user-password --username andrewbrown --password Testing1234! --user-pool-id us-east-2_xMATXNbsI --permanent
```
- Try to inspect the crudder homepage after signin to see. Under the `Elements` > `Console` section, you'll see `Attributes`, which should contain your `email`, `email_verified` status, and `sub` value.

- Go to cognito console and manually enter required attributes (name and prefered username). Then refresh cruddur to confirm.

- After confirmation, delete the manually created user from cognito and sign out from cruddur

- Try signing up on cruddur frontend

- This should give you a confirm email page. Also go to cognito userpool under users to see that it is waiting for confirmation.

- Check you email for verification code and confirm. On the cognito console, you will also see that it is confirmed.

- Now, it requires signin after verification so sign-in on cruddur

- Also, test to see if resend verification option works

- Try to use the forget password option at signin

- Check email for password reset code

- Enter reset code and new password. Then proceed to signin.

- Sign into cruddur and view docker-compose backend logs to confirm authentication

- On cruddur, a certain section was added as mockup for only authenticated users and shouldn't be seen when signed out.

---