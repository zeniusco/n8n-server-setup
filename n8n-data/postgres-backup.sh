#!/bin/bash
PGPASSWORD=yourpassword pg_dump -U n8nuser -h 127.0.0.1 n8ndb > /home/runcloud/webapps/n8n/n8n-data/postgres/pg_backup_$(date +\%F).sql
if [ $? -ne 0 ]; then
  echo "n8n PostgreSQL backup FAILED at $(date) on $(hostname)" | mail -s "ERROR: n8n PostgreSQL Backup Failed" youremail@yourdomain.com
fi
