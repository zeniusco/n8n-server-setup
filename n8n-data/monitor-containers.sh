#!/bin/bash
N8N_STATUS=$(docker ps --filter "name=n8n" --filter "status=running" --format "{{.Names}}")
PG_STATUS=$(docker ps --filter "name=postgres" --filter "status=running" --format "{{.Names}}")

MESSAGE=""

if [ -z "$N8N_STATUS" ]; then
  MESSAGE="n8n container was DOWN"
fi

if [ -z "$PG_STATUS" ]; then
  if [ -n "$MESSAGE" ]; then
    MESSAGE="$MESSAGE and "
  fi
  MESSAGE="${MESSAGE}PostgreSQL container was DOWN"
fi

if [ -n "$MESSAGE" ]; then
  MESSAGE="ALERT: $MESSAGE on $(hostname) at $(date). Attempting restart."
  echo "$MESSAGE" | mail -s "n8n/PG Container Alert on $(hostname)" youremail@yourdomain.com
  cd /home/runcloud/webapps/n8n/n8n-data/
  docker-compose up -d
fi
