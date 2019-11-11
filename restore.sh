#!/bin/bash
[[ -z "$1" ]] && echo "Usage: ./restore.sh ROOT_BACKUP_DIR [CONTAINERS...]" && exit 1

BACKUP_DIR=$1

# Select which containers to backup, or use default list
if [[ ! -z "$2" ]]; then
    CONTAINERS=(${@:2})
else
    CONTAINERS=(nzbget radarr radarr4k sonarr transmission jackett traefik ombi)
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
    docker run --rm --volumes-from $container -v $(pwd):/backup alpine /bin/sh -c "rm -rf /config/* && cd /config && tar xf /backup/$container.tar"
    docker restart $container
done

# If existing config exists, back it up
if [ -f /etc/htpc-config/docker-compose.yml ]; then
    mv /etc/htpc-config/docker-compose.yml /etc/htpc-config/docker-compose.yml.bak
    mv /etc/htpc-config/.env /etc/htpc-config/.env.bak
    mv /etc/htpc-config/scripts /etc/htpc-config/scripts-old
    mv /etc/htpc-config/traefik /etc/htpc-config/traefik-old
fi

# Restore docker-compose configs
mv docker-compose.yml /etc/htpc-config
mv .env /etc/htpc-config
mv traefik-config /etc/htpc-config/traefik
mv scripts /etc/htpc-config/scripts

# Remove extracted backup dir
cd .. && rm -rf out/

echo "Done!"
