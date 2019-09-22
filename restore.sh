#!/bin/bash
[[ -z "$1" ]] && echo "Usage: ./restore.sh ROOT_BACKUP_DIR [CONTAINERS...]" && exit 1

BACKUP_DIR=$1

# Select which containers to backup, or use default list
if [[ ! -z "$2" ]]; then
    CONTAINERS=(${@:2})
else
    CONTAINERS=(nzbget radarr sonarr transmission emby jackett letsencrypt)
fi

cd $BACKUP_DIR

# Get latest backup tarball
latest_backup=$(ls -t | grep tar.gz | head -n1)
echo "Restoring from $latest_backup..."

# Extract tarball
mkdir -p out
tar xzf $latest_backup -C out/

# Restore all config volumes
cd out/
for container in "${CONTAINERS[@]}"; do
    echo "Restoring volume for $container..."
    docker run --rm --volumes-from $container -v $(pwd):/backup alpine /bin/sh -c "cd /config && tar xf /backup/$container.tar"
    docker restart $container
done

# Restore docker-compose configs
if [ -f /etc/rpi-htpc/docker-compose.yml ]; then
    mv /etc/rpi-htpc/docker-compose.yml /etc/rpi-htpc/docker-compose.yml.bak
    mv /etc/rpi-htpc/.env /etc/rpi-htpc/.env.bak
fi

mv docker-compose.yml /etc/rpi-htpc/
mv .env /etc/rpi-htpc/
mv traefik-config /etc/rpi-htpc/traefik

# Remove extracted backup dir
cd .. && rm -rf out/

echo "Done!"
