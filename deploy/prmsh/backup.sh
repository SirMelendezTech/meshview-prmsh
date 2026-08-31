#!/bin/bash
# PostgreSQL backup for the MeshView PR deployment.
# Schedule from the host crontab, e.g. daily at 03:00:
#   0 3 * * * /home/master/meshview/deploy/prmsh/backup.sh >> /home/master/meshview/deploy/prmsh/logs/backup.log 2>&1
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="${DIR}/data/backups"
KEEP_DAYS=14
STAMP="$(date +%Y%m%d_%H%M%S)"

mkdir -p "${BACKUP_DIR}"

docker exec meshview-prmsh-db pg_dump -U meshview -d meshview \
  | gzip -9 > "${BACKUP_DIR}/meshview_${STAMP}.sql.gz"

echo "[$(date)] backup written: meshview_${STAMP}.sql.gz"

# Prune old backups
find "${BACKUP_DIR}" -name 'meshview_*.sql.gz' -mtime "+${KEEP_DAYS}" -delete
