#!/bin/bash
BACKUP_DIR=~/backups/$(date -I)
mkdir -p $BACKUP_DIR && cd $BACKUP_DIR

CONTAINERS=(nzbget radarr sonarr transmission emby jackett)
for container in "${CONTAINERS[@]}"; do
    docker run --rm --volumes-from $container -v $(pwd):/backup alpine /bin/sh -c "cd /config && tar cvf /backup/$container.tar *"
done
