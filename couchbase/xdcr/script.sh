#!/bin/bash

source functions.sh

set -e

setup
pause_xdcr_cluster1_to_cluster2
pause_xdcr_cluster2_to_cluster1
sdk --cluster 1 --operation "upsert" --id "1" --value "alice"
resume_xdcr_cluster1_to_cluster2
resume_xdcr_cluster2_to_cluster1
sleep 10
sdk --cluster 1 --operation "check" --id "1" --value "alice"
sdk --cluster 2 --operation "check" --id "1" --value "alice"
teardown

echo "All tests passed"
