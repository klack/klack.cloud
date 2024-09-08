#!/bin/bash

# Define the veth interface you are searching for
VETH_INTERFACE="vethefa4613"

# Get a list of all running Docker container IDs
container_ids=$(docker ps -q)

# Check each container's network settings
for container_id in $container_ids; do
  # Get the Pid of the container
  pid=$(docker inspect --format '{{.State.Pid}}' $container_id)

  # Find the veth interface associated with the container's namespace
  veth_found=$(nsenter -t $pid -n ip link show | grep -o "$VETH_INTERFACE")

  # If the veth interface is found, print the container ID and name
  if [ ! -z "$veth_found" ]; then
    container_name=$(docker inspect --format '{{.Name}}' $container_id | sed 's/\///')
    echo "Container ID: $container_id, Container Name: $container_name is connected to $VETH_INTERFACE"
  fi
done
