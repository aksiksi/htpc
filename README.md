# RPI HTPC

## Overview

RPI-HTPC consists of the following:

1. A ready-to-run Docker Compose file with the following containers: NZBGet, Transmission, Radarr, Sonarr, Emby, and Jackett
2. A simple setup script that installs all prereqs on your RPi
3. A systemd service that manages all of the containers for you
4. A script that can backup your app configs (used via cron)

**NOTE:** This has been tested on Raspbian on both RPi 3B+ and 4.

## Setup

### Clone this Repo

Install `git`, then clone this repository:

```bash
sudo apt install git
git clone https://github.com/aksiksi/rpi-media.git
```

### Configure Mounts

Configure any HDD mounts by editing `/etc/fstab` and running `sudo mount -a`.

In this guide, we assume a mount at `/mnt/share1/`.

### Modify Docker Compose File

Make required changes to `docker-compose.yml`.  In particular, change all of the volume targets to point to your configured external HDD mount.

Note that the config volumes for most of the containers are created in `setup.sh`.  This is done so that they persist between Docker Compose runs.

### Create Environment File

Create a file called `env` and place this at the root of this repo.  This file will be copied out to a `.env` file for use with Docker Compose.

Make sure to specify the following variables that are required by the Docker Compose file:

```
# Timezone setting
TIMEZONE=America/New_York

# OpenVPN settings
# Only required if using the Transmission + OpenVPN container
# Provider list: http://haugene.github.io/docker-transmission-openvpn/supported-providers/
# Find configs here: https://github.com/haugene/docker-transmission-openvpn/tree/master/openvpn
OPENVPN_PROVIDER=PROVIDER
OPENVPN_CONFIG=CONFIG
OPENVPN_USERNAME=USERNAME
OPENVPN_PASSWORD=PASSWORD

# Share and downloads paths for shared volumes
SHARE_PATH=/mnt/share1
DOWNLOADS_PATH=/mnt/share1/Downloads
```

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
5. Copy `docker-compose.yml` and `env` to `/etc/opt/rpi-htpc`
6. Enable and start the systemd service
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

## Optional: Setting Up DLNA

DLNA is a widely supported media sharing protocol.  In some cases, clients may not have support for SMB or NFS, so DLNA is a good backup.

First, install `minidlna`:

```
sudo apt-get install minidlna
```

Open: `sudo vim /etc/minidlna.conf`

Add the following config where relevant:

```
# User to run the daemon as (defaults to root)
user=pi

# Location of [V]ideo directories to serve
media_dir=V,/mnt/share1/Movies
media_dir=V,/mnt/share1/Series

# Put the cache on external HDD insted of SD card
db_dir=/mnt/share1/.cache/minidlna

# Name your server
friendly_name=RPIHTPC

# Set to "no" for better performance
inotify=yes
```

Stop the service, sync your folders, then start it again:

```
sudo service minidlna stop
sudo minidlnad -R
sudo service minidlna restart
```

If it doesn't work, make sure that port 8200 is open. Check the log for details: `tail -f /var/log/minidlna.log`

## Reverse Proxy

The `docker-compose.yml` contains a service that runs Nginx + LetsEncrypt which can be used as a reverse proxy.

### Dynamic DNS

You can use `ddclient` to keep your DDNS up to date:

```
sudo apt-get install ddclient

vim /etc/ddclient.conf
# Configure your domain

# Refresh entry every 300 seconds
ddclient -daemon 300
```

### Setting Up LetsEncrypt Certs

In my case, my DDNS points to `home.mydomain.com`. My root domain points to another server, so I only want to validate this subdomain (`ONLY_SUBDOMAINS=true`).

Here is what my `docker-compose.yml` entry looks like for `letsencrypt`:

```
  letsencrypt:
    image: linuxserver/letsencrypt
    container_name: letsencrypt
    cap_add:
      - NET_ADMIN
    environment:
      PUID: 1000
      PGID: 1000
      TZ: ${TIMEZONE}
      URL: mydomain.com
      SUBDOMAINS: home
      ONLY_SUBDOMAINS: "true"
      VALIDATION: http
    volumes:
      - /etc/opt/rpi-htpc/letsencrypt:/config
    ports:
      - "443:443"
      - "80:80"
    restart: unless-stopped
```

### Configuring Proxy Endpoints

All you need to do is rename the proxy configs you need located under: `/etc/opt/rpi-htpc/letsencrypt/nginx/proxy-confs/`

Make sure to select either subfolder (`myhost.com/nzbget`) or subdomain (`nzbget.myhost.com`).

If you are setting up Emby, ensure that authentication is set to "Handled by Proxy".

## Update Docker Containers

This will only restart containers that need an update:

```
cd /etc/opt/rpi-htpc && docker-compose up -d --build
```

## Backing Up Container Configs

All of the Docker containers used in this HTPC setup mount their config directories to `/config` inside the container.

A simple shell script is included that can be triggered daily via `crontab` to backup all of the container config volumes to a directory of your choice.  See `backup.sh`. You can use `restore.sh` to restore from the latest backup genereate by the backup script.

Example `crontab`:

```
0 6 * * * /home/pi/config/backup.sh /mnt/share1/Backups
```
