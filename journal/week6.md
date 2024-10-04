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

