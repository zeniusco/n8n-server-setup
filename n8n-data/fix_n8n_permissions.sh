#!/bin/bash

EMAIL="you@example.com"
HOST="$(hostname)"
DATE="$(date)"
DATA_DIR="/home/runcloud/webapps/n8n/n8n-data"

# Fix ownership first
/usr/bin/chown -R runcloud:runcloud "$DATA_DIR" || echo "CHOWN FAILED for $DATA_DIR on $HOST at $DATE" | /usr/bin/mail -s "n8n chown FAILED" "$EMAIL"

# Fix n8n data permissions
/usr/bin/chown -R 1000:1000 "$DATA_DIR/data" || echo "CHOWN FAILED for $DATA_DIR/data on $HOST at $DATE" | /usr/bin/mail -s "n8n chown FAILED" "$EMAIL"

# Fix Postgres data permissions
/usr/bin/chown -R 999:999 "$DATA_DIR/postgres" || echo "CHOWN FAILED for $DATA_DIR/postgres on $HOST at $DATE" | /usr/bin/mail -s "n8n chown FAILED" "$EMAIL"

# Fix .env file permissions
/usr/bin/chown 1000:1000 "$DATA_DIR/.env" || echo "CHOWN FAILED for $DATA_DIR/.env on $HOST at $DATE" | /usr/bin/mail -s "n8n chown FAILED" "$EMAIL"

# Array of items and their desired permissions
declare -A items=(
  ["$DATA_DIR/data"]="700"
  ["$DATA_DIR/postgres"]="700"
  ["$DATA_DIR/.env"]="600"
  ["$DATA_DIR/manual-n8n-update-workflow.json"]="600"
  ["$DATA_DIR/install-and-migration.sh"]="700"
  ["$DATA_DIR/monitor-containers.sh"]="700"
  ["$DATA_DIR/update_n8n.sh"]="700"
  ["$DATA_DIR/docker-compose.yml"]="644"
)

for item in "${!items[@]}"; do
  perm="${items[$item]}"
  if [[ -e "$item" ]]; then
    /usr/bin/chmod "$perm" "$item" || echo "CHMOD FAILED: $item to $perm on $HOST at $DATE" | /usr/bin/mail -s "n8n chmod FAILED: $item" "$EMAIL"
  else
    echo "MISSING: $item on $HOST at $DATE" | /usr/bin/mail -s "n8n MISSING: $item" "$EMAIL"
  fi
done
