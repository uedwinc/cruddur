# Reconnect Database

- Go to api.cruddur.com/api/health-check (This should show success) but api.cruddur.com/api/activities/home (This should show internal server error. If it shows debug mode error, then you need to fix that)

- May not be applicable, but if debug mode is shown, you may need to change sth in app.py, then push a new prod image and run the service stack to apply

- Compose up to startup locally

- Internal server error is because we don't have the database seeded with information

+ Update env variable PROD_CONNECTION_URL to reflect the new database name

- Upon up port 5432 for gitpod in the database security group (make sure the description is GITPOD). Use ./bin/rds/update-sg-rule to update security group rule for our specific gitpod IP. There are a number of envs you will need to change in the script.

- You can now connect to the prod database: `./bin/db/connect prod`
- Exit

- Schema load for prod: `./bin/db/schema-load prod`

- You can run migrate locally for production using `CONNECTION_URL=PROD_CONNECTION_URL ./bin/db/migrate`
- You can connect again and use postgres commands from before to see tables

- You may need to change the CONNECTION_URL set in env variables of post confirmation lambda to reflect the new cfn cluster
- On the console, under the post confirmation lambda, manually point the vpc to the new cfn created vpc. Create a new security group (in a new tab) (name: CognitoLambdaSG) (description: For the Lambda that needs to connect to postgres) with no inbound rules and attach it to the vpc. Select the public subnets. 
- Go to the database security group and allow postgres port access from that newly created security group (description: COGNITOPOSTCONF)

- In cognito, delete all previous users

- Now, try to signup on cruddur.com
- Then sign-in
- Make a Crud

- Try to signup as another user or even multiples

**Refactor app.py into separate modules**

- Create the following files: backend-flask/lib/rollbar.py, backend-flask/lib/xray.py, backend-flask/lib/honeycomb.py, backend-flask/lib/cors.py, backend-flask/lib/cloudwatch.py, backend-flask/lib/helpers.py

- Create a new folder: backend-flask/routes
- Create the following files: backend-flask/routes/activities.py, backend-flask/routes/users.py, backend-flask/routes/messages.py, backend-flask/routes/general.py
- Refactor backend-flask/app.py

- Create file: backend-flask/db/sql/activities/reply.sql

- Run `migration`

```sh
./bin/generate/migration reply_to_activity_uuid_to_string
```
- Thi should generate out a migration file as backend-flask/db/migrations/16844665640237772_reply_to_activity_uuid_to_string.py (may not be exact)

- Modify the file to https://github.com/omenking/aws-bootcamp-cruddur-2023/blob/week-x/backend-flask/db/migrations/16844665640237772_reply_to_activity_uuid_to_string.py

- Run the migration
```sh
./bin/db/migrate
```

- Create file: backend-flask/db/sql/activities/show.sql

- Create the following files: frontend-react-js/src/components/FormErrors.js, frontend-react-js/src/components/FormErrors.css, frontend-react-js/src/components/FormErrorItem.js

- Create files: frontend-react-js/src/lib/Requests.js

- Create files: frontend-react-js/src/pages/ActivityShowPage.js, frontend-react-js/src/pages/ActivityShowPage.css
- Create files: frontend-react-js/src/components/Replies.js, frontend-react-js/src/components/Replies.css

- Create file: frontend-react-js/src/components/ActivityShowItem.js

- Run migration against production:
```sh
CONNECTION_URL=$PROD_CONNECTION_URL ./bin/db/migrate
```

- Rollout the backend using the CICD pipeline. Create pull request to merge changes to prod branch and trigger pipeline build for the backend.
- Confirm CodePipeline is successfull

- For the frontend:

- Run the static build
```sh
./bin/frontend/static-build
```
- Run the sync
```sh
./bin/frontend/sync
```

- Go to CloudFront > Distributions, under Invalidations tab, check that a new one is in progress

///
N.B - target group for frontend if exists is not going to be used
///

///
- We may need to update the ddb table name in a couple places. Not sure but eg ddb.py, erb file, cfn for service. Again, this may just be what he did in order to be able to run production in local environment
///

> Create a machine-user with permissions to read and write from dynamodb

- Create the following cfn files: aws/cfn/machine-user/template.yaml, aws/cfn/machine-user/config.toml

- Create the execution script: bin/cfn/machineuser
- Give execute permission
- Run the script
- Execute changeset on cloudformation

- Go to IAM > Users > cruddur-machine-user and generate credentials
- Give the user cli access

- Go to AWS Systems Manager
- Edit and update the previously created access and secret key ID for cruddur/backend-flask/... credentials (You can create a different machine user for the codebuild if you want)