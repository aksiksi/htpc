# RPI HTPC

A Docker-based HTPC setup for your Raspberry Pi.

## Setup

### Configure Mounts

Configure any HDD mounts by editing `/etc/fstab` and running `sudo mount -a`.

In this guide, we assume a mount at `/mnt/share1/`.

### Install Docker and Docker Compose

Install Docker:

```
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
```

Start Docker service:

```
sudo systemctl enable docker
sudo systemctl start docker
```

Install Docker Compose:

```
# Install required packages
sudo apt update
sudo apt install -y python python-pip libffi-dev python-backports.ssl-match-hostname

# Install Docker Compose from pip
# This might take a while
sudo pip install docker-compose
```

Add `pi` user to Docker group: `sudo usermod -aG pi docker`

### Create and Start RPI-HTPC

```
mkdir ~/config
cp docker-compose.yml ~/config

sudo cp rpi-htpc.service /etc/systemd/system
sudo systemctl enable rpi-htpc
sudo systemctl start rpi-htpc
```

### Optional: Setting Up Samba

Install Samba and add an entry for your mount in `/etc/samba/smb.conf`:

```
sudo apt install samba

sudo vim /etc/samba/smb.conf

[share1]
Comment = Share1
Path = /mnt/share1
Browseable = yes
Writeable = Yes
only guest = no
create mask = 0777
directory mask = 0777
Public = yes
Guest ok = yes

sudo systemctl restart smbd
```

### Optional: Setting Up NFS

1. Install NFS server:

```
sudo apt-get install nfs-common nfs-server -y
```

2. Open up required ports (if running firewall):

```
sudo ufw allow 2049
sudo ufw allow 111
```

3. Add your mount to NFS exports file and refresh:

```
sudo vim /etc/exports
## Allow only IPs on subnet:
## /mnt/share1 192.168.0.0/24(rw,sync,no_subtree_check,insecure)
## OR allow all:
## /mnt/share1 *(rw,sync,no_subtree_check,insecure)

sudo exportfs
sudo systemctl restart nfs-server.service
```

4. Assign mountd to a specific port for firewall (optional):

```
sudo vim /etc/default/nfs-kernel-server

# CHANGE THIS LINE: RPCMOUNTDOPTS="-p 13025"

sudo systemctl restart nfs-kernel-server.service
```

## Update Docker Containers

This will only restart containers that need an update:

```
docker-compose up -d --build
```

## Backing Up Container Configs

All of the Docker containers used in this HTPC setup mount their config directories to `/config` inside the container.

A simple shell script is included that can triggered daily to backup all of the container config volumes to a directory of your choice.  See `backup-volumes.sh`.
