#!/bin/bash
docker stop learning-nginx-static-content
docker rm learning-nginx-static-content
docker build -t learning-nginx-static-content .
docker run -d -p 8080:8080 --name learning-nginx-static-content learning-nginx-static-content
