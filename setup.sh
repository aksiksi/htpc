#!/bin/bash

# Start Docker daemon
sudo systemctl enable docker
sudo systemctl start docker

# Install required packages for docker-compose
sudo apt update
sudo apt install -y python python-pip libffi-dev python-backports.ssl-match-hostname

# Install Docker Compose from pip
# This might take a while
sudo pip install docker-compose

# Add current user to docker group
sudo usermod -aG $USER docker

# Create required external volumes
# We do this so that data is persisted across docker-compose sessions
# Emby volume is mapped to directory; see docker-compose.yml
CONTAINERS=(nzbget radarr radarr4k sonarr transmission jackett traefik ombi)
for container in "${CONTAINERS[@]}"; do
    docker volume create $container
done

# Create config directory
sudo mkdir -p /etc/htpc-config
sudo chown ${USER}:${USER} /etc/htpc-config
cp docker-compose.yml /etc/htpc-config
cp env /etc/htpc-config/.env

cp -R scripts /etc/htpc-config/scripts

# Setup Traefik configs
cp -R traefik /etc/htpc-config/traefik
touch /etc/htpc-config/traefik/acme.json
chmod 600 /etc/htpc-config/traefik/acme.json

# Setup systemd service
sudo cp htpc.service /etc/systemd/system
sudo systemctl enable htpc
sudo systemctl start htpc

# Optional: Install Samba
sudo apt install samba

# Optional: Install NFS
sudo apt-get install nfs-common nfs-server -y
