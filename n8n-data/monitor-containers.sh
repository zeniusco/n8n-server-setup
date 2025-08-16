#!/bin/bash
N8N_STATUS=$(docker ps --filter "name=n8n" --filter "status=running" --format "{{.Names}}")
PG_STATUS=$(docker ps --filter "name=postgres" --filter "status=running" --format "{{.Names}}")
if [ -z "$N8N_STATUS" ] || [ -z "$PG_STATUS" ]; then
  cd /home/runcloud/webapps/n8n/n8n-data/
  docker-compose up -d
fi
