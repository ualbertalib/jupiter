# Generate Documentation

`$ bundle exec rake rdoc`

# View Documentation

`$ open docs/rdoc/index.html`

# Check your style

`$ bundle exec rubocop`

# Run tests

`$ bundle exec rails test`

# REGenerate Documentation

`$ bundle exec rake rerdoc`


## Docker
This project comes with a docker setup to easily setup your own local development environment for jupiter in just a few steps.

### Step 1: Make sure you have docker and docker-compose installed:

1. [Install Docker](https://docs.docker.com/engine/installation/) (Requires version 1.13.0+)
2. [Install Docker Compose](https://docs.docker.com/compose/install/) (Requires version 1.10.0+)

#### Still need more help? Check out the following

##### OSX / Windows
- If you are on Mac, check out [Docker for Mac](https://docs.docker.com/docker-for-mac/)
- If you are on Windows, check out [Docker for Windows](https://docs.docker.com/docker-for-windows/)

These will install `docker`, `docker-compose`, and `docker-machine` on your machine.

##### Linux

Use your distribution's package manager to install `docker` and `docker-compose`.

### Step 2: Get Jupiter source code
Clone the Jupiter repository from github:
```shell
git clone git@github.com:ualbertalib/jupiter.git
```

### Step 3: Start docker and docker compose

To build, create, start and setup your docker containers simply run:
```shell
docker-compose up -d
```

Now that everything is up and running, you can setup the rails database (only need to be done once, this will setup both dev and test databases):
```shell
docker-compose run web rails db:setup
```

### Step 4: Open and view Jupiter!
Now everything is ready, you can go and view Jupiter! Just open your favorite browser and go to the following url:

[localhost:9000](localhost:9000)

(Note: ip address may be different if you are using `docker-machine`)

(Also feel free to change the port in the docker-compose file, this default was chosen so that it does not conflict if you already have a rails server running (which by default uses port 3000))

### Want to run the test suite?

1. Start up all the docker containers, like you did above (if its not already running):

  ```shell
  docker-compose up -d
  ```

2. Setup the test database (if you haven't already from above):
  ```shell
  docker-compose run web rails db:setup
  ```

3. Then you can run the test suite via rspec:
  ```shell
  docker-compose run web rails test
  ```

### Common gotchas?

- We are reusing the same solr for test and dev. This may cause issues between data. This shouldn't matter to much, but just be aware of this if things are getting mangled.

- If your having issues, logs are the best place to first look at what went wrong.

  To check all container logs:

  ```shell
  docker-compose logs
  ```

  Better yet you can check an individual container log by supplying the container name to the previous command. For example if I want to see the web container logs:

  ```shell
  docker-compose logs web
  ```

- One common issue could be the webpage is not rendering when you go to [localhost:9000](localhost:9000). This probably a result of the server not being started due to a bad stop and exiting of the container from a previous run. This causes the server to leave a pid file in the tmp directory. To fix this, cleanup the pid file via:

  ```shell
  sudo rm -rf /tmp/pids/server.pid
  ```

  Then restart the server:
    ```shell
    docker-compose restart web
    ```
