# Setup Database with RDS Postgres

## Setup Database For Development

### Setup Postgres Locally

We will setup a local postgres docker container

Integrate the following into the docker compose file:

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

To install the postgres client, add this to Gitpod yaml file

```sh
  - name: postgres
    init: |
      curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc|sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/postgresql.gpg
      echo "deb http://apt.postgresql.org/pub/repos/apt/ `lsb_release -cs`-pgdg main" |sudo tee  /etc/apt/sources.list.d/pgdg.list
      sudo apt update
      sudo apt install -y postgresql-client-13 libpq-dev
```

### Using Postgres Locally

1. First, do `docker compose up` to run all containers

2. Connect to psql via the psql client cli tool (remember to use the host flag to specify localhost)

```sh
psql -U postgres --host localhost
```

3. Now you can run postgres commands:

**Common PSQL commands:**

```sql
\t
\d
\dl
\l
\x on -- expanded display when looking at data
\x auto -- expanded display is used automatically
\q -- Quit PSQL
\l -- List all databases
\c database_name -- Connect to a specific database
\dt -- List all tables in the current database
\d table_name -- Describe a specific table
\du -- List all users and their roles
\dn -- List all schemas in the current database
CREATE DATABASE database_name; -- Create a new database
DROP DATABASE database_name; -- Delete a database
CREATE TABLE table_name (column1 datatype1, column2 datatype2, ...); -- Create a new table
DROP TABLE table_name; -- Delete a table
SELECT column1, column2, ... FROM table_name WHERE condition; -- Select data from a table
INSERT INTO table_name (column1, column2, ...) VALUES (value1, value2, ...); -- Insert data into a table
UPDATE table_name SET column1 = value1, column2 = value2, ... WHERE condition; -- Update data in a table
DELETE FROM table_name WHERE condition; -- Delete data from a table
```

4. Do `\q` to quit

### Different Local Postgres Actions for Cruddur

#### Creating and Dropping our Database

1. We can use the createdb command to create our database:

  https://www.postgresql.org/docs/current/app-createdb.html

```sh
createdb cruddur -h localhost -U postgres

# Or just use:

create database cruddur;
```

2. To drop the database

```sql
\l --To list all databases
DROP database cruddur;
```

3. We can create the database within the PSQL client

```sql
CREATE database cruddur;
```

#### Import Script

**Add UUID Extension**

We are going to have Postgres generate out UUIDs. This helps to generate random non-serial IDs for database clients.

We'll need to use an extension called uuid-ossp (https://www.postgresql.org/docs/current/uuid-ossp.html)

```sql
CREATE EXTENSION "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "uuid-ossp"; --Use this
```

**Create the script**

Create an sql script, [schema.sql](../backend-flask/db/schema.sql). The extension will be added in the script using the `CREATE EXTENSION IF NOT EXISTS "uuid-ossp";` command.

**Import the script**

```sh
cd backend-flask

psql cruddur < db/schema.sql -h localhost -U postgres
```

#### Create a CONNECTION URI string

CONNECTION URI string is a way of providing all the details that is needed to authenticate to the server. 

Documentation: https://www.postgresql.org/docs/current/libpq-connect.html#LIBPQ-CONNSTRING

More documentation here https://stackoverflow.com/questions/3582552/what-is-the-format-for-the-postgresql-connection-string-url shows a general format: postgresql://[user[:password]@][netloc][:port][/dbname][?param1=value1&...]

```sh
CONNECTION_URL="postgresql://postgres:password@localhost:5432/cruddur"
```

We can test/confirm this using:

```sh
psql postgresql://postgres:password@localhost:5432/cruddur
```

Set this as env variable:

```sh
export CONNECTION_URL="postgresql://postgres:password@localhost:5432/cruddur"

gp env CONNECTION_URL="postgresql://postgres:password@localhost:5432/cruddur"
```

- Now, we can authenticate into the server using:

```sh
psql $CONNECTION_URL
```

#### Setup Driver for Postgres

https://www.psycopg.org/psycopg3/

https://www.psycopg.org/psycopg3/docs/basic/install.html

We'll add the following to our `requirments.txt`

```
psycopg[binary]
psycopg[pool]
```

```sh
pip install -r requirements.txt
```

#### DB Object and Connection Pool

- Instrument connection pool in [db.py](../backend-flask/lib/db.py)

- We need to add CONNECTION_URL as env var in docker-compose for our backend-flask application:

```yml
  backend-flask:
    environment:
      CONNECTION_URL: "${CONNECTION_URL}"
```

- For our case, we will do this by adding `CONNECTION_URL` to the erb variables file at [backend-flask.env.erb](../erb/backend-flask.env.erb)

- Set the `CONNECTION_URL` in docker-compose to reflect db rather than localhost IP. You can copy the full value from the env var of the backend container shell

```yml
postgresql://postgres:password@db:5432/cruddur
```

#### Bash scripts to automate some basic sql tasks

- Give execute permission and run the following files:

1. Connect to the database using [db-connect](../bin/db/connect)

2. Drop the database using [db-drop](../bin/db/drop)

3. Create a database using [db-create](../bin/db/create)

4. Load the schema into the database using [db-schema-load](../bin/db/schema-load). This will create the tables. This file actually references the [schema.sql](../backend-flask/db/schema.sql) file

5. Manually load seed data into the tables/database using [db-seed](../bin/db/seed). This will manually add seed values to the tables/database. It references the [seed.sql](../backend-flask/db/seed.sql) file.

- To see the seed data in the database:

  - Connect to the database: `./bin/db-connect`

  - `\dt` to see tables

  - `SELECT * FROM activities;`

  - Quit with `q`

  - Do `\x on` to activate expanded display or `\x auto` to activate automatic use of expanded display

  - Now, you can do: `SELECT * FROM activities;`

  - Confirm that uuid and timestamps are correctly generated and set

6. See what connections we are using with [db-sessions](../bin/db/sessions) script.

> We could have idle connections left open by our Database Explorer extension, try disconnecting and checking again by running the db-sessions script.

7. Easily setup (reset) everything for our database using [db-setup](../bin/db/setup). This will drop, create, schema-load and seed the database.

> This is only useful in development, and not production

> Try to load cruddur on the browser and check the logs for backend. Cruddur should load the seed data.

## Setup Database For Production

Setup Postgres database on AWS RDS

### Using CloudFormation

1. Create the [CloudFormation template file](../aws/cfn/db/template.yaml) and the [cfn-toml config file](../aws/cfn/db/config.toml).

2. Write [a bash script](../bin/cfn/db) to run the template

- Set DB_PASSWORD for MasterUserPassword. It is required in `bin/cfn/db`

```sh
export DB_PASSWORD=dbPassword123
gp env DB_PASSWORD=dbPassword123
```

3. Give execute permission and run the script to deploy the resources:

```sh
chmod u+x /bin/cfn/db/template.yaml

./bin/cfn/db/template.yaml
```

4. Execute the change set on the console

#### Setup the CONNECTION URI

> Copy the connection endpoint of the database. Go to Parameter store on Systems manager and edit the CONNECTION_URL to reflect that. You only need to edit what is after @ and before port number.

Similar to the production setup, we can set this for production using the details used for RDS on AWS

```sh
PROD_CONNECTION_URL="postgresql://cruddurroot:cruddurPassword1@cruddur-db-instance.cbkq6ia0u32o.us-east-2.rds.amazonaws.com:5432/cruddur"
```

Set this as env variable:

```sh
export PROD_CONNECTION_URL="postgresql://cruddurroot:cruddurPassword1@cruddur-db-instance.cbkq6ia0u32o.us-east-2.rds.amazonaws.com:5432/cruddur"

gp env PROD_CONNECTION_URL="postgresql://cruddurroot:cruddurPassword1@cruddur-db-instance.cbkq6ia0u32o.us-east-2.rds.amazonaws.com:5432/cruddur"
```

### Using the CLI

Documentation: https://docs.aws.amazon.com/cli/latest/reference/rds/create-db-instance.html

```sh
aws rds create-db-instance \
  --db-instance-identifier cruddur-db-instance \
  --db-instance-class db.t3.micro \
  --engine postgres \
  --engine-version  14.6 \
  --master-username cruddurroot \
  --master-user-password cruddurPassword1 \
  --allocated-storage 20 \
  --availability-zone us-east-2a \
  --backup-retention-period 0 \
  --port 5432 \
  --no-multi-az \
  --db-name cruddur \
  --storage-type gp2 \
  --publicly-accessible \
  --storage-encrypted \
  --enable-performance-insights \
  --performance-insights-retention-period 7 \
  --no-deletion-protection
```

- You can add this to turn off enhanced monitoring to minimize cost:

```sh
    --monitoring-interval 0 \

# Doc: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_Monitoring.OS.Enabling.html
```

> Creating the RDS instance will take about 10-15 mins

> You can temporarily stop an RDS instance for 7 days when you aren't using it.

### Establish a connection to the Postgres database on AWS (Locally)

1. Make sure the RDS instance is running

2. Do `echo $PROD_CONNECTION_URL` to confirm it is properly set

3. Next, we need to modify the inbound rules of the security group associated with the RDS

  <mark>Manually</mark>

  - The port will be Postgres (port number = 5432)
  - For the IP address, we need to put in our Gitpod IP address. This is gotten with the command:

  ```sh
  curl ifconfig.me
  ```

  - We can set this as env variable using:

  ```sh
  export GITPOD_IP=$(curl ifconfig.me)
  ```

  - You can do `echo $GITPOD_IP` to confirm

  - Copy the IP and paste in the security group configuration. It will auto append `/32` indicating one IP address

  - You can set the description as "GITPOD" (all caps). Then create rule.

  - Now, you can connect to the database using:

  ```sh
  psql $PROD_CONNECTION_URL
  ```

  - Do `\l` to see any list of databases

  <mark>Automatically</mark>

  Whenever we launch Gitpod, we'll have a new IP address. This means we will need to update the IP address on our RDS security group at every launch of Gitpod.

  The inbound rule we defined for Postgres has a 'Security group rule ID'. The security group itself has a 'Security group ID'. We'll set these two values as env variables since they are constants unless deleted.

  ```sh
  export DB_SG_ID="sg-***"
  gp env DB_SG_ID="sg-***"

  export DB_SG_RULE_ID="sgr-***"
  gp env DB_SG_RULE_ID="sgr-***"
  ```

  - Now, whenever we need to modify the inbound rule to use current Gitpod IP, we can run the command:

  ```sh
  aws ec2 modify-security-group-rules \
    --group-id $DB_SG_ID \
    --security-group-rules "SecurityGroupRuleId=$DB_SG_RULE_ID,SecurityGroupRule={Description=GITPOD,IpProtocol=tcp,FromPort=5432,ToPort=5432,CidrIpv4=$GITPOD_IP/32}"
  ```

  We can write a script for the above operation. In backend-flask/bin, create a new file [_update-sg-rule_](../bin/rds/update-sg-rule) and set it as a bash script to run the 'aws ec2 modify-security-group-rules' command

  > Documentation: https://docs.aws.amazon.com/cli/latest/reference/ec2/modify-security-group-rules.html#examples

  - Add execute rights:

  ```sh
  chmod u+x /bin/rds-update-sg-rule
  ```

  - We want this script to run at startup of Gitpod. So, we will add a command step for postgres in the _.gitpod.yml_ file

  ```yml
      command: |
        export GITPOD_IP=$(curl ifconfig.me)
        source "$THEIA_WORKSPACE_ROOT/backend-flask/bin/rds-update-sg-rule"
  ```

4. Next, we need to update [db-connect](../bin/db/connect) and [db-schema-load](../bin/db/schema-load) bash scripts for production:

```sh
if [ "$1" = "prod" ]; then
  echo "Running in production mode"
else
  echo "Running in development mode"
fi
```

5. Now, try to run the script to establish connection (in backend-flask directory):

```sh
./bin/db/connect prod
```

6. Modify the CONNECTION_URL in [backend-flask.env.erb](../erb/backend-flask.env.erb) for production.

7. Do compose up

8. Run the script to load schema

```sh
./bin/db/schema-load prod
```

- Try to access frontend cruddur on the browser. This should not have any data as we don't have any data on the system.