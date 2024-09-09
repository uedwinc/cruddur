# App Containerization

This can either be done on containers individually or multiple containers using docker-compose

## Containerize Individually

### 1. Containerize Backend

- Build the [Dockerfile](../backend-flask/Dockerfile) (run from /cruddur working directory)

```sh
docker build -t backend-flask ./backend-flask
```

- Run the container

```sh
docker run --rm -p 4567:4567 -it -e FRONTEND_URL='*' -e BACKEND_URL='*' -d backend-flask
```

- Access the backend url link from the ports tab on Gitpod and Confirm on the browser (add `/api/activities/home` endpoint)

> We haven't setup authentication so the backend returns cognito error as shown below:

![back](/images/back.png)

### 2. Containerize Frontend

- Go to the frontend directory and run `npm install` (This has already been done. Won't be running this to avoid any unknown package upgrade)

- Build the [Dockerfile](../frontend-react-js/Dockerfile) (run from /cruddur working directory)

```sh
docker build -t frontend-react-js ./frontend-react-js
```

- Run container

```sh
docker run -p 3000:3000 -d frontend-react-js
```

- Open Gitpod port link in browser:

![front](/images/front.png)

## Containerize using Docker Compose

1. `cd` into the working directory containing the [docker-compose](../docker-compose.yml) file

2. Right click on the docker-compose file and click 'Compose up' or do `docker compose up` on the terminal

3. Open the ports and launch on browser

> Note that the docker-compose file include setup for postgres and dynamodb local, as well as aws-xray

# Adding DynamoDB Local and Postgres

We are going to use Postgres and DynamoDB local in future labs.
We can bring them in as containers and reference them externally.

We have the following integrated into the existing docker compose file:

## 1. Postgres

```yaml
services:
  db:
    image: postgres:13-alpine
    restart: always
    environment:
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=password
    ports:
      - '5432:5432'
    volumes: 
      - db:/var/lib/postgresql/data
volumes:
  db:
    driver: local
```

To install the postgres client into Gitpod

```sh
  - name: postgres
    init: |
      curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc|sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/postgresql.gpg
      echo "deb http://apt.postgresql.org/pub/repos/apt/ `lsb_release -cs`-pgdg main" |sudo tee  /etc/apt/sources.list.d/pgdg.list
      sudo apt update
      sudo apt install -y postgresql-client-13 libpq-dev
```

## 2. DynamoDB Local

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

# Working with the Databases

First, do `docker compose up` to run all containers

## Using DynamoDB local

1. Create a table

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

**References**

- https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/DynamoDBLocal.html

- https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Tools.CLI.html

## Using Postgres

- After installing the postgres client, you can create a database user using:

```sh
psql -U postgres --host localhost
```

- Now, you can run the following postgres commands:

```
\t
\d
\dl
\l
```

- Finally, do `\q` to quit