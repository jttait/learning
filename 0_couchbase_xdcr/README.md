# Couchbase XDCR

## How to run

1. Start Docker
2. ./script.sh

## Functions

- setup - creates two Couchbase Docker containers, initializes two single-node Couchbase clusters,
  creates a test bucket in each cluster, creates bi-directional XDCR for the test bucket
- pause\_xdcr\_from\_cluster1\_to\_cluster2
- pause\_xdcr\_from\_cluster2\_to\_cluster1
- resume\_xdcr\_from\_cluster1\_to\_cluster2
- resume\_xdcr\_from\_cluster2\_to\_cluster1
- teardown - stops and deletes the Docker containers
- sdk - pass arguments to Couchbase SDK
  - sdk --cluster 1 --operation "upsert" --id "abc" --content "alice"
  - sdk --cluster 2 --operation "check" --id "abc" --content "alice"
  - sdk --cluster 2 --operation "remove" --id "abc"
