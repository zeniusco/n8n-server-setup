# n8n Docker + PostgreSQL on RunCloud

## Directory Structure

- /home/runcloud/webapps/n8n/n8n-data/        # All n8n scripts, configs, Docker data (private)
- /home/runcloud/webapps/n8n/public/          # Web root (public)

## Setup Steps

1. Create RunCloud web app (static, proxy Nginx, SSL)
2. Deploy this repo to /home/runcloud/webapps/n8n/n8n-data/ via RunCloud Git
3. SSH as root, run `bash /home/runcloud/webapps/n8n/n8n-data/install-and-migration.sh`
4. Fill out .env with secrets/credentials
5. Use RunCloud Deployment Scripts to run one-time directory setup
6. Use RunCloud Deployment Scripts to start PostgreSQL and n8n
7. Set up Nginx proxy per guide
8. Set up cron job for auto-updates
9. Import manual update workflow in n8n
10. Configure backup and Supervisor in RunCloud
11. For migration, restore directory and re-run install-and-migration.sh

## Security

- No secrets in /public/
- All data outside web root
- Use SSL and strong credentials

## Backup

- Ensure /home/runcloud/webapps/n8n/ is included in RunCloud backup schedule

