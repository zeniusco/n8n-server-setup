#!/bin/bash

# Install Docker (if not present)
if ! command -v docker &> /dev/null
then
  apt-get update
  apt-get install -y ca-certificates curl gnupg
  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  chmod a+r /etc/apt/keyrings/docker.gpg
  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
    tee /etc/apt/sources.list.d/docker.list > /dev/null
  apt-get update
  apt-get install -y docker-ce docker-ce-cli containerd.io
fi

# Install Docker Compose (if not present)
if ! command -v docker-compose &> /dev/null
then
  curl -SL https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose
  chmod +x /usr/local/bin/docker-compose
fi

# Add runcloud user to docker group
usermod -aG docker runcloud

# Set permissions (runcloud user must own files)
chown -R runcloud:runcloud /home/runcloud/webapps/n8n/n8n-data/

echo "Install and migration script complete. Please logout and log in as 'runcloud' user to continue."
