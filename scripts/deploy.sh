#!/bin/bash

set -e

APP_DIR="/home/ec2-user/app"
JAR_NAME="DevOpsSummative-1.0-SNAPSHOT.jar"
LOG_FILE="app.log"

# Ensure the EC2 user has ownership of the app directory and files
echo "Ensuring correct permissions for the app directory..."
sudo chown -R ec2-user:ec2-user "$APP_DIR"
sudo chmod -R 755 "$APP_DIR"

# Ensure the JAR file has the correct executable permission
echo "Setting executable permission on JAR..."
sudo chown ec2-user:ec2-user "$APP_DIR/$JAR_NAME"
sudo chmod 755 "$APP_DIR/$JAR_NAME" || echo "Warning: chmod failed"

# Ensure the log file is writable
echo "Ensuring log file is writable..."
sudo touch "$APP_DIR/$LOG_FILE"
sudo chown ec2-user:ec2-user "$APP_DIR/$LOG_FILE"
sudo chmod 777 "$APP_DIR/$LOG_FILE"

# Check if Java is installed
echo "Checking for Java installation..."
if ! command -v java &> /dev/null; then
    echo "Java is not installed. Installing Amazon Corretto 17..."

    # Install Java 17 (Amazon Corretto)
    sudo yum update -y
    sudo yum install java-17-amazon-corretto -y

    # Verify installation
    if ! command -v java &> /dev/null; then
        echo "ERROR: Failed to install Java!"
        exit 1
    fi

    echo "Java installed successfully!"
else
    echo "Java is already installed."
fi

echo "Navigating to app directory: $APP_DIR"
cd "$APP_DIR"

echo "Stopping existing Java app if it's running..."
PIDS=$(ps aux | grep "$JAR_NAME" | grep -v grep | awk '{print $2}')
if [ -n "$PIDS" ]; then
  echo "Stopping existing Java process(es): $PIDS"
  kill -15 $PIDS
  sleep 3
  if ps -p $PIDS > /dev/null; then
    echo "Force killing process..."
    kill -9 $PIDS
  fi
else
  echo "No existing Java process found."
fi

if [ ! -f "$JAR_NAME" ]; then
  echo "ERROR: JAR file not found in $APP_DIR!"
  exit 1
fi

echo "Starting the new Java app..."
nohup java -jar "$JAR_NAME" > "$LOG_FILE" 2>&1 &

# Wait for the app to actually start
echo "Waiting for the app to start..."
for i in {1..10}; do
  sleep 2
  if curl -s http://localhost:8080 > /dev/null; then
    echo "Application is up!"
    break
  fi
  echo "Waiting... attempt $i"
  if [ "$i" -eq 10 ]; then
    echo "ERROR: Application failed to start." >&2
    exit 1
  fi
done

LOG_GROUP="/aws/code-deploy/logs"
aws logs create-log-group --log-group-name "$LOG_GROUP" || true
aws logs create-log-stream --log-group-name "$LOG_GROUP" --log-stream-name "DeployLog" || true

#timestamped logging
echo "$(date) - Application started" >> "$LOG_FILE"

echo "Deployment completed successfully."
