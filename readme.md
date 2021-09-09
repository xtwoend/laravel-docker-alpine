# Docker build for php service


## Directory

```
	--yourforlderapp
	  --deploy
	  	--nginx
	  	  	nginx.conf
	  	--php
	  	  	www.conf
	  	  	php.ini
	  	--supervisor
            --conf.d
                worker.conf  
	  	  	supervisord.conf
	  public/index.php #sample index
	  Dockerfile
	  Makefile
```

## USE docker-compose

```
	# Build the continer
	docker-compose build php-service redis

	# Run container
	docker-compser up
```

## USAGE

```
	# Build the container
	make build

	# Build and publish the container
	make release

	# Publish a container to AWS-ECR.
	# This includes the login to the repo
	make publish

	# Run the container
	make run

	# Run the container link volume
	make run-dev

	# Build an run the container
	make up

	# Build an run the container link volume
	make up-dev

	# Stop the running container
	make stop
```



