#!/bin/bash
docker build -t go-test-server ./server
docker build -t learning-nginx-load-balancer .

docker stop test-server-1
docker rm test-server-1

docker stop test-server-2
docker rm test-server-2

docker stop test-server-3
docker rm test-server-3

docker stop nginx-load-balancer
docker rm nginx-load-balancer

docker network rm test-network
docker network create test-network

docker run \
	--detach \
	--name test-server-1 \
	--env SERVER_NAME=test-server-1 \
	--net test-network \
	go-test-server

docker run \
	--detach \
	--name test-server-2 \
	--env SERVER_NAME=test-server-2 \
	--net test-network \
	go-test-server

docker run \
	--detach \
	--name test-server-3 \
	--env SERVER_NAME=test-server-3 \
	--net test-network \
	go-test-server

docker run \
	--detach \
	--publish 8080:8080 \
	--name nginx-load-balancer \
	--net test-network \
	learning-nginx-load-balancer


