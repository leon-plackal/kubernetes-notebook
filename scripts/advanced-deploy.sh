#!/bin/bash

# Configuration Variables
IMAGE_NAME="username/myapp:latest"  # Replace 'username' with your Docker Hub username
CONTAINER_BLUE="myapp_blue"
CONTAINER_GREEN="myapp_green"
PORT_MAPPING="80:80"
HEALTHCHECK_URL="http://localhost/health"  # Change based on your app's health check endpoint

# Pull the latest image
echo "Pulling the latest Docker image..."
docker pull "$IMAGE_NAME"

# Determine which container is currently running
if docker ps --filter "name=$CONTAINER_BLUE" --format '{{.Names}}' | grep -q "$CONTAINER_BLUE"; then
    ACTIVE_CONTAINER="$CONTAINER_BLUE"
    NEW_CONTAINER="$CONTAINER_GREEN"
else
    ACTIVE_CONTAINER="$CONTAINER_GREEN"
    NEW_CONTAINER="$CONTAINER_BLUE"
fi

echo "Current active container: $ACTIVE_CONTAINER"
echo "Deploying new container as: $NEW_CONTAINER"

# Run the new container on a different name
docker run -d --name "$NEW_CONTAINER" -p "$PORT_MAPPING" "$IMAGE_NAME"

# Wait for the new container to be ready
echo "Waiting for the new container to be healthy..."
for i in {1..10}; do
    sleep 3
    if curl --silent --fail "$HEALTHCHECK_URL"; then
        echo "New container is healthy!"
        break
    fi
    echo "Waiting for the new container to respond... Attempt $i"
    if [ $i -eq 10 ]; then
        echo "New container failed to start. Rolling back..."
        docker stop "$NEW_CONTAINER"
        docker rm "$NEW_CONTAINER"
        exit 1
    fi
done

# Stop the old container
echo "Stopping old container: $ACTIVE_CONTAINER"
docker stop "$ACTIVE_CONTAINER"
docker rm "$ACTIVE_CONTAINER"

echo "Deployment successful! Now running: $NEW_CONTAINER"
