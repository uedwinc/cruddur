# Secure Flask and Implement Container Insights

# Securing Flask

https://flask.palletsprojects.com/en/2.3.x/debugging/

- Edit inbound rules for cruddur-alb-sg to only work for my IP (for now)
- Leave only ports for HTTPS and HTTP and allow only My IP

- In backend-flask/ directory, create a new dockerfile (/Dockerfile.prod) for production and edit the original dockerfile to allow debugging

`/backend-flask/Dockerfile`
```Dockerfile
FROM 387543059434.dkr.ecr.ca-central-1.amazonaws.com/cruddur-python:3.10-slim-buster

# Inside Container
# make a new folder inside container
WORKDIR /backend-flask

# Outside Container -> Inside Container
# this contains the libraries want to install to run the app
COPY requirements.txt requirements.txt

# Inside Container
# Install the python libraries used for the app
RUN pip3 install -r requirements.txt

# Outside Container -> Inside Container
# . means everything in the current directory
# first period . - /backend-flask (outside container)
# second period . /backend-flask (inside container)
COPY . .

EXPOSE ${PORT}

# CMD (Command)
# python3 -m flask run --host=0.0.0.0 --port=4567
CMD [ "python3", "-m" , "flask", "run", "--host=0.0.0.0", "--port=4567", "--debug"]
```

- Create a script to log into ECR `/bin/ecr/login`

- Add execute permission and login

```sh
chmod u+x /bin/ecr/login

./bin/ecr/login
```

- Create the following directories: `/bin/docker/build/`(files here: backend-flask-prod, frontend-react-js-prod), `/bin/docker/push/` (files here: backend-flask-prod), `/bin/docker/run/` (files here: backend-flask-prod)

- Give execute permissions

- Build the production image

```sh
./bin/docker/build/backend-flask-prod
```

- Set URL, tag and push

```sh
./bin/docker/push/backend-flask-prod
```

- Now, we need to update task definition on ECS and force deployment
- Create a new file: `/bin/ecs/force-deploy-backend-flask`

- Give execute permissions

- Execute

```sh
./bin/ecs/force-deploy-backend-flask
```

- Restructure bin/ directory
  - Move the /bin dir up one level outside backend-flask/

- Build the frontend-react-js

```sh
./bin/docker/build/frontend-react-js-prod
```

- Create push script for frontend-react-js

- Make the script executable

- Execute the script

```sh
./bin/docker/push/frontend-react-js-prod
```

- Now, we need to update task definition on ECS and force deployment
- Create a new file: `/bin/ecs/force-deploy-frontend-react-js`

- Give execute permissions

- Execute

```sh
./bin/ecs/force-deploy-frontend-react-js
```

- Confirm the following url paths on browser

https://api.cruddur.com
https://api.cruddur.com/api/health-check
https://api.cruddur.com/api/activities/home

- Type in a wrong endpoint to be sure it doesn't return a typeerror (instead an internal server error maybe) as that debug mode should not be seen from customer end

- If you encounter any errors, you can also check rollbar for error logging

> Incase you want to reduce spend and stop your running containers, go to ECS, check the service and click 'update'. Then change the 'Desired tasks' to zero(0). Then, when you stop your tasks, it won't start another one.

- Restructure the /bin directory

- Create an sql script to kill all connections: /backend-flask/db/kill-all-connections.sql
- Create a script to run the kill all db connections: /bin/db/kill-all

# Configure Container Insights

- Configure xray in task-definitions/backend-flask.json

- Create a bin/backend/register and bin/frontend/register scripts to register task definitions

- Give execute rights to the files

- Run the register files

- Deploy /bin/backend/deploy

- Confirm that all the services are running on ECS. Click into all to see the various tasks

- Create env files to hold our environment variables
  - First, we need to store the env variables in env.erb files: erb/backend-flask.env.erb and erb/frontend-react-js.env.erb
  - Next, we need to create ruby scripts that generate the envs: /bin/backend/generate-env and /bin/frontend/generate-env
  - When these files are run, they generate a `.env` file. Let's ignore that in .gitignore
  - Give execute permission to the generate-env files
  - Add command to generate-env at startup in .gitpod.yml file
  - Remove env variables from docker-compose and reference generated env file path

- Create bin/frontend/run script

- Edit docker-compose networks

- Create bin/busybox to be used for debugging
  - Give execute permission
  - Run the file
  - While connected, go to another tab and run `docker network inspect cruddur-net`
  - Search for the busybox service (just look through for a weirdly named service)
  - In the shell tab of busybox, run some commands to be debug: `ping xray-daemon`, `telnet xray-daemon 2000`

- Move health-check file to the backend-flask/bin directory

- Now, to turn on container insights, go to ECS > Custers > cruddur
  - Click 'Update cluster'
  - Expand 'Monitoring' tab and check 'Use container insights'
  - Click 'Update'

- Go to CloudWatch > Container insights