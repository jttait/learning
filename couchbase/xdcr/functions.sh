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
	curl http://$CLUSTER1_LOCALHOST/clusterInit \
		--request POST \
		--silent \
		--output /dev/null \
		--data username=$USERNAME \
		--data password=$PASSWORD \
		--data clusterName=cluster1 \
		--data port=8091 \
		--data services=kv
	curl http://$CLUSTER2_LOCALHOST/clusterInit \
		--request POST \
		--silent \
		--output /dev/null \
		--data username=$USERNAME \
		--data password=$PASSWORD \
		--data clusterName=cluster2 \
		--data port=8091 \
		--data services=kv
	sleep 15

	# Create buckets
	curl http://$CLUSTER1_LOCALHOST/pools/default/buckets \
		--request POST \
		--user $USERNAME:$PASSWORD \
		--silent \
		--output /dev/null \
		--data name=test \
		--data ramQuota=1000
	curl http://$CLUSTER2_LOCALHOST/pools/default/buckets \
		--request POST \
		--user $USERNAME:$PASSWORD \
		--silent \
		--output /dev/null \
		--data name=test \
		--data ramQuota=1000

	# Setup bidirectional XDCR
	curl http://$CLUSTER1_LOCALHOST/pools/default/remoteClusters \
		--user $USERNAME:$PASSWORD \
		--silent \
		--output /dev/null \
		--data name=cluster2 \
		--data username=$USERNAME \
		--data password=$PASSWORD \
		--data hostname=$CLUSTER2_IP_ADDRESS
	curl http://$CLUSTER2_LOCALHOST/pools/default/remoteClusters \
		--user $USERNAME:$PASSWORD \
		--silent \
		--output /dev/null \
		--data name=cluster1 \
		--data username=$USERNAME \
		--data password=$PASSWORD \
		--data hostname=$CLUSTER1_IP_ADDRESS
	sleep 5
	curl http://$CLUSTER1_LOCALHOST/controller/createReplication \
		--request POST \
		--user $USERNAME:$PASSWORD \
		--silent \
		--output /dev/null \
		--data fromBucket=test \
		--data toCluster=cluster2 \
		--data toBucket=test \
		--data replicationType=continuous
	curl http://$CLUSTER2_LOCALHOST/controller/createReplication \
		--request POST \
		--user $USERNAME:$PASSWORD \
		--silent \
		--output /dev/null \
		--data fromBucket=test \
		--data toCluster=cluster1 \
		--data toBucket=test \
		--data replicationType=continuous
}

pause_xdcr_cluster1_to_cluster2() {
	CLUSTER1_SETTINGS_URI=$(
		curl --user $USERNAME:$PASSWORD --silent http://$CLUSTER1_LOCALHOST/pools/default/tasks | \
			jq -r '.[] | select(.type == "xdcr") | .settingsURI'
	)
	curl http://$CLUSTER1_LOCALHOST$CLUSTER1_SETTINGS_URI \
		--request POST \
		--user $USERNAME:$PASSWORD \
		--silent \
		--output /dev/null \
		--data pauseRequested=true
}

pause_xdcr_cluster2_to_cluster1() {
	CLUSTER2_SETTINGS_URI=$(
		curl --user $USERNAME:$PASSWORD --silent http://$CLUSTER2_LOCALHOST/pools/default/tasks | \
			jq -r '.[] | select(.type == "xdcr") | .settingsURI'
	)
	curl http://$CLUSTER2_LOCALHOST$CLUSTER2_SETTINGS_URI \
		--request POST \
		--user $USERNAME:$PASSWORD \
		--silent \
		--output /dev/null \
		--data pauseRequested=true
}

resume_xdcr_cluster1_to_cluster2() {
	CLUSTER1_SETTINGS_URI=$(
		curl --user $USERNAME:$PASSWORD --silent http://$CLUSTER1_LOCALHOST/pools/default/tasks | \
			jq -r '.[] | select(.type == "xdcr") | .settingsURI'
	)
	curl http://$CLUSTER1_LOCALHOST$CLUSTER1_SETTINGS_URI \
		--request POST \
		--user $USERNAME:$PASSWORD \
		--silent \
		--output /dev/null \
		--data pauseRequested=false
}

resume_xdcr_cluster2_to_cluster1() {
	CLUSTER2_SETTINGS_URI=$(
		curl --user $USERNAME:$PASSWORD --silent http://$CLUSTER2_LOCALHOST/pools/default/tasks | \
			jq -r '.[] | select(.type == "xdcr") | .settingsURI'
	)
	curl http://$CLUSTER2_LOCALHOST$CLUSTER2_SETTINGS_URI \
		--request POST \
		--user $USERNAME:$PASSWORD \
		--silent \
		--output /dev/null \
		--data pauseRequested=false
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
