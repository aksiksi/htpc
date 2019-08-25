#!/bin/bash
[[ -z "$1" ]] && echo "Usage: ./restore.sh ROOT_BACKUP_DIR" && exit 1

CONTAINERS=(nzbget radarr sonarr transmission emby jackett)
BACKUP_DIR=$1

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
done

# Remove extracted backup dir
cd .. && rm -rf out/

echo "Done!"
