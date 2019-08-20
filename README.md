# RPI HTPC

## Overview

RPI-HTPC consists of the following:

1. A ready-to-run Docker Compose file with the following containers: NZBGet, Transmission, Radarr, Sonarr, Emby, and Jackett
2. A simple setup script that installs all prereqs on your RPi
3. A systemd service that manages all of the containers for you
4. A script that can backup your app configs (used via cron)

**NOTE:** This has been tested on Raspbian on both RPi 3B+ and 4.

## Setup

### Configure Mounts

Configure any HDD mounts by editing `/etc/fstab` and running `sudo mount -a`.

In this guide, we assume a mount at `/mnt/share1/`.

### Modify Docker Compose File

Make required changes to `docker-compose.yml`.  In particular, change all of the volume targets to point to your configured external HDD mount.

### Run Setup Script

From the root of the repo:

```
chmod +x setup.sh
./setup.sh
```

This script will:

1. Install Docker
2. Start Docker service
3. Install Docker Compose
4. Add current user to Docker group
5. Copy `docker-compose.yml` to `~/config`
6. Enable and start RPI-HTPC systemd service
7. Install Samba and NFS (see next section for setup)

## Optional: Samba and NFS Setup

### Setting Up Samba

Add an entry for your mount in `/etc/samba/smb.conf`:

```
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

### Setting Up NFS

1. Open up required ports (if running firewall):

```
sudo ufw allow 2049
sudo ufw allow 111
```

2. Add your mount to NFS exports file and refresh:

```
sudo vim /etc/exports
## Allow only IPs on subnet:
## /mnt/share1 192.168.0.0/24(rw,sync,no_subtree_check,insecure)
## OR allow all:
## /mnt/share1 *(rw,sync,no_subtree_check,insecure)

sudo exportfs
sudo systemctl restart nfs-server.service
```

3. Assign mountd to a specific port for firewall (optional):

```
sudo vim /etc/default/nfs-kernel-server

# CHANGE THIS LINE: RPCMOUNTDOPTS="-p 13025"

sudo systemctl restart nfs-kernel-server.service
```

## Update Docker Containers

This will only restart containers that need an update:

```
cd ~/config && docker-compose up -d --build
```

## Backing Up Container Configs

All of the Docker containers used in this HTPC setup mount their config directories to `/config` inside the container.

A simple shell script is included that can be triggered daily via `crontab` to backup all of the container config volumes to a directory of your choice.  See `backup-volumes.sh`.
