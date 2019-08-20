#!/bin/bash

# Install some required packages first
sudo apt update
sudo apt install -y \
     apt-transport-https \
     ca-certificates \
     curl \
     gnupg2 \
     software-properties-common

# Get the Docker signing key for packages
curl -fsSL https://download.docker.com/linux/$(. /etc/os-release; echo "$ID")/gpg | sudo apt-key add -

# Add the Docker official repos
echo "deb [arch=armhf] https://download.docker.com/linux/$(. /etc/os-release; echo "$ID") \
     $(lsb_release -cs) stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list

# Install Docker
# The aufs package, part of the "recommended" packages, won't install on Buster just yet, because of missing pre-compiled kernel modules.
# We can work around that issue by using "--no-install-recommends"
sudo apt update
sudo apt install -y --no-install-recommends \
    docker-ce \
    cgroupfs-mount

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

# Setup RPI-HTPC systemd service
mkdir ~/config
cp docker-compose.yml ~/config

sudo cp rpi-htpc.service /etc/systemd/system
sudo systemctl enable rpi-htpc
sudo systemctl start rpi-htpc

# Optional: Install Samba
sudo apt install samba

# Optional: Install NFS
sudo apt-get install nfs-common nfs-server -y
