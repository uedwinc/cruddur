# App Containerization

This can either be done on containers individually or multiple containers using docker-compose

## Containerize Individually

### 1. Containerize Backend

- Build the Dockerfile (run from /cruddur working directory)

```sh
docker build -t backend-flask ./backend-flask
```

- Run the container

```sh
docker run --rm -p 4567:4567 -it -e FRONTEND_URL='*' -e BACKEND_URL='*' -d backend-flask
```

- Access the backend url link from the ports tab on Gitpod and Confirm on the browser (add `/api/activities/home` endpoint)

> We haven't setup authentication so the backend returns cpgnito error as shown below:

![back](/images/back.png)

### 2. Containerize Frontend

- Go to the frontend directory and run `npm install` (This has already been done. Won't be running this to avoid any unknown package upgrade)

- Build the Dockerfile (run from /cruddur working directory)

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

