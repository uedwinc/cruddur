# DynamoDB and Serverless Caching

## Setup DynamoDB Locally

Add the setup process in docker-compose:

```yaml
services:
  dynamodb-local:
    # https://stackoverflow.com/questions/67533058/persist-local-dynamodb-data-in-volumes-lack-permission-unable-to-open-databa
    # We needed to add user:root to get this working.
    user: root
    command: "-jar DynamoDBLocal.jar -sharedDb -dbPath ./data"
    image: "amazon/dynamodb-local:latest"
    container_name: dynamodb-local
    ports:
      - "8000:8000"
    volumes:
      - "./docker/dynamodb:/home/dynamodblocal/data"
    working_dir: /home/dynamodblocal
```

Example of using DynamoDB local: https://github.com/100DaysOfCloud/challenge-dynamodb-local

### Using DynamoDB local

1. First, do `docker compose up` to run all containers

2. Create a table

```sh
aws dynamodb create-table \
  --endpoint-url http://localhost:8000 \
  --table-name Music \
  --attribute-definitions \
      AttributeName=Artist,AttributeType=S \
      AttributeName=SongTitle,AttributeType=S \
  --key-schema AttributeName=Artist,KeyType=HASH AttributeName=SongTitle,KeyType=RANGE \
  --provisioned-throughput ReadCapacityUnits=1,WriteCapacityUnits=1 \
  --table-class STANDARD
```

2. Create an Item

```sh
aws dynamodb put-item \
  --endpoint-url http://localhost:8000 \
  --table-name Music \
  --item \
      '{"Artist": {"S": "No One You Know"}, "SongTitle": {"S": "Call Me Today"}, "AlbumTitle": {"S": "Somewhat Famous"}}' \
  --return-consumed-capacity TOTAL  
```

3. List Tables

```sh
aws dynamodb list-tables --endpoint-url http://localhost:8000
```

4. Get Records

```sh
aws dynamodb scan --table-name Music --query "Items" --endpoint-url http://localhost:8000
```

### References

https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/DynamoDBLocal.html
https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Tools.CLI.html

## Setup DynamoDB on AWS

### Create an Amazon DynamoDB Table (OPTION A)

1. Create a new [CloudFormation template file](../aws/cfn/ddb/template.yaml).

2. Write [a bash script](../bin/cfn/ddb) to run the template

3. Give execute permission and run the script to deploy the resources:

```sh
chmod u+x /bin/cfn/ddb/template.yaml

./bin/cfn/ddb/template.yaml
```

4. Execute the change set on the console

### Implementation of DynamoDB Locally

Docs for DynamoDB with boto3 SDK: 
- https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/dynamodb.html
- https://docs.aws.amazon.com/code-library/latest/ug/python_3_dynamodb_code_examples.html

#### Create table

- In **/ddb/schema-load**, provision script to create table

- Give execute permission to the script

```sh
chmod u+x /bin/ddb/schema-load
```

- Run schema-load

```sh
./bin/ddb/schema-load
```

- This should return information about the table

#### List tables

- In **/ddb/list-table**, provision script to list tables

- Give execute permission to the script

```sh
chmod u+x /bin/ddb/list-tables
```

- Now, run the script to return the list of tables:

```sh
./bin/ddb/list-tables
```

#### Drop table

- In **/ddb/drop**, provision script to drop specified table

- Give execute permission to the script

```sh
chmod u+x /bin/ddb/drop
```

- Now, run the script to drop the specified table:

```sh
./bin/ddb/drop cruddur-messages
```

  NOTE:
  - We need to run mysql: Create database, load schema and enter seed data
  - Edit `/db/seed` to include email values
  ```sh
  ./bin/db/setup
  ```

#### Create mock data in table

- In **/ddb/seed**, provision python script to create mock data in table

- Give execute permission to the script

```sh
chmod u+x /bin/ddb/seed
```

- Now, run the script

```sh
./bin/ddb/seed
```

- This should seed data into the local database

#### Show the contents of the cruddur-messages

- In **/ddb/scan**, provision python script to show the contents of the cruddur-messages

- Give execute permission to the script

```sh
chmod u+x /bin/ddb/scan
```

- Now, run the script

```sh
./bin/ddb/scan
```

#### Run the following

```sh
chmod u+x /bin/ddb/patterns/get-conversation
./bin/ddb/patterns/get-conversation

chmod u+x /bin/ddb/patterns/list-conversations
./bin/ddb/patterns/list-conversations
```

#### List users

1. On the terminal, you can list users using cli command:

```sh
aws cognito-idp list-users --user-pool-id=enter-cognito-user-pool-id-here
```

2. We want to implement this in /bin/cognito/list-users using an sdk script:

- Set the cognito user pool id as env variable:

```sh
export AWS_COGNITO_USER_POOL_ID=""

gp env AWS_COGNITO_USER_POOL_ID=""
```

- Update this in the docker-compose file (replace the hard coded value with reference to env)

- Give execute permission to the 'list-users' script

```sh
chmod u+x /bin/cognito/list-users
```

- Run the script

```sh
./bin/cognito/list-users
```

#### Update cognito user ids

- Now that we can list out the users, we need to create a new script to update the cognito user ids in our database

- In "bin/db/", create a new file 'update_cognito_user_ids'

- Give execute permission to the 'update_cognito_user_ids' script

```sh
chmod u+x /bin/db/update_cognito_user_ids
```

- Update /db/setup to execute the `update_cognito_user_ids` script

- Make sure the database is running (docker-compose), then run the 'setup' script

```sh
./bin/db/setup
```

- If there is an issue with the 'update_cognito_user_ids' step, try to run it alone

- You can connect to sql database to confirm the cognito user id is updated:

```sh
./bin/db/connect
\x auto
SELECT * FROM users;
```

- Load cruddur homepage and see if it returns correctly

- To check if the messages section of cruddur is working, let's seed data into dynamodb

```sh
./bin/ddb/schema-load

./bin/ddb/seed
```

- Now, set the endpoint_url for ddb in docker-compose

```yml
      AWS_ENDPOINT_URL: "http://dynamodb-local:8000"
```

- Restart docker compose

- Now, check the messages section of cruddur

- On cruddur, try to create a message

- Now, in the message section with the newly added user, try to send a message on cruddur

