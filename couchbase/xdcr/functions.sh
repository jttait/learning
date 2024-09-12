#!/bin/bash

setup() {
	# Start the Docker containers
	docker run \
		--detach \
		--name cluster1 \
		--publish 8091-8097:8091-8097 \
		--publish 9123:9123 \
		--publish 11207:11207 \
		--publish 11210:11210 \
		--publish 11280:11280 \
		--publish 18091-18097:18091-18097 \
		couchbase
	docker run \
		--detach \
		--name cluster2 \
		--publish 7091-7097:8091-8097 \
		--publish 9124:9123 \
		--publish 11208:11207 \
		--publish 11211:11210 \
		--publish 11281:11280 \
		--publish 17091-17097:18091-18097 \
		couchbase
	sleep 15

	CLUSTER1_IP_ADDRESS=$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' cluster1)
	CLUSTER2_IP_ADDRESS=$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' cluster2)
	USERNAME=Administrator
	PASSWORD=password
	CLUSTER1_LOCALHOST=localhost:8091
	CLUSTER2_LOCALHOST=localhost:7091

	# Initialize the Couchbase clusters
	curl -X POST http://$CLUSTER1_LOCALHOST/clusterInit \
		-d username=$USERNAME \
		-d password=$PASSWORD \
		-d clusterName=cluster1 \
		-d port=8091 \
		-d services=kv
	curl -X POST http://$CLUSTER2_LOCALHOST/clusterInit \
		-d username=$USERNAME \
		-d password=$PASSWORD \
		-d clusterName=cluster2 \
		-d port=8091 \
		-d services=kv
	sleep 15

	# Create buckets
	curl -X POST -u $USERNAME:$PASSWORD http://$CLUSTER1_LOCALHOST/pools/default/buckets \
		-d name=test \
		-d ramQuota=1000
	curl -X POST -u $USERNAME:$PASSWORD http://$CLUSTER2_LOCALHOST/pools/default/buckets \
		-d name=test \
		-d ramQuota=1000

	# Setup bidirectional XDCR
	curl -u $USERNAME:$PASSWORD http://$CLUSTER1_LOCALHOST/pools/default/remoteClusters \
		-d name=cluster2 \
		-d username=$USERNAME \
		-d password=$PASSWORD \
		-d hostname=$CLUSTER2_IP_ADDRESS
	curl -u $USERNAME:$PASSWORD http://$CLUSTER2_LOCALHOST/pools/default/remoteClusters \
		-d name=cluster1 \
		-d username=$USERNAME \
		-d password=$PASSWORD \
		-d hostname=$CLUSTER1_IP_ADDRESS
	sleep 5
	curl -X POST -u $USERNAME:$PASSWORD http://$CLUSTER1_LOCALHOST/controller/createReplication \
		-d fromBucket=test \
		-d toCluster=cluster2 \
		-d toBucket=test \
		-d replicationType=continuous
	curl -X POST -u $USERNAME:$PASSWORD http://$CLUSTER2_LOCALHOST/controller/createReplication \
		-d fromBucket=test \
		-d toCluster=cluster1 \
		-d toBucket=test \
		-d replicationType=continuous
}

pause_xdcr_cluster1_to_cluster2() {
	CLUSTER1_SETTINGS_URI=$(curl -X GET -u $USERNAME:$PASSWORD http://$CLUSTER1_LOCALHOST/pools/default/tasks | jq -r '.[] | select(.type == "xdcr") | .settingsURI')
	curl -X POST -u $USERNAME:$PASSWORD http://$CLUSTER1_LOCALHOST$CLUSTER1_SETTINGS_URI \
		-d pauseRequested=true
}

pause_xdcr_cluster2_to_cluster1() {
	CLUSTER2_SETTINGS_URI=$(curl -X GET -u $USERNAME:$PASSWORD http://$CLUSTER2_LOCALHOST/pools/default/tasks | jq -r '.[] | select(.type == "xdcr") | .settingsURI')
	curl -X POST -u $USERNAME:$PASSWORD http://$CLUSTER2_LOCALHOST$CLUSTER2_SETTINGS_URI \
		-d pauseRequested=true
}

resume_xdcr_cluster1_to_cluster2() {
	CLUSTER1_SETTINGS_URI=$(curl -X GET -u $USERNAME:$PASSWORD http://$CLUSTER1_LOCALHOST/pools/default/tasks | jq -r '.[] | select(.type == "xdcr") | .settingsURI')
	curl -X POST -u $USERNAME:$PASSWORD http://$CLUSTER1_LOCALHOST$CLUSTER1_SETTINGS_URI \
		-d pauseRequested=false
}

resume_xdcr_cluster2_to_cluster1() {
	CLUSTER2_SETTINGS_URI=$(curl -X GET -u $USERNAME:$PASSWORD http://$CLUSTER2_LOCALHOST/pools/default/tasks | jq -r '.[] | select(.type == "xdcr") | .settingsURI')
	curl -X POST -u $USERNAME:$PASSWORD http://$CLUSTER2_LOCALHOST$CLUSTER2_SETTINGS_URI \
		-d pauseRequested=false
}

sdk() {
	go run main.go "$@"
}

teardown() {
	docker stop cluster1
	docker rm cluster1
	docker stop cluster2
	docker rm cluster2
}
