# n8n + Docker + PostgreSQL on RunCloud  
**Subdomain:** `sub.domain.com`  
**Web App Name:** `n8n`  
**Web App Path:** `/home/runcloud/webapps/n8n/`

---

## 1. Prepare Your Files and Folder Structure

n8n-setup/  
├── n8n-data/  
│ ├── docker-compose.yml  
│ ├── .env.example  
│ ├── update_n8n.sh  
│ ├── install-and-migration.sh  
│ ├── manual-n8n-update-workflow.json  
│ ├── data/  
│ │ └── .gitkeep  
│ ├── postgres/  
│ │ └── .gitkeep  
├── README.md  
├── .gitignore  


**.gitignore example:**
.env  
n8n-data/data/  
n8n-data/postgres/  
*.sql  


---

## 2. Create the RunCloud Web App

- Log into RunCloud dashboard.
- Go to `Web Applications > Create Application`
- Application Stack: **Static**
- Domain: `sub.domain.com`
- Web Application Name: `n8n`
- Root Path: `/home/runcloud/webapps/n8n/`
- Create Application

---

## 3. Enable SSL

- Go to your `n8n` web app in RunCloud.
- Go to **SSL/TLS** tab.
- Click **Install Free SSL (Let’s Encrypt)**
- Enable **Force SSL**

---

## 4. Upload Files, Remove `.gitkeep`, and Make Script Executable

- Download, unzip, and upload all files to `/home/runcloud/webapps/n8n/`.
- Remove `.gitkeep` from `n8n-data/postgres/` (and optionally from `n8n-data/data/`).
- Make `update_n8n.sh` executable.

---

## 5. Set File and Folder Ownership

- In RunCloud dashboard: `Tools > Fix File and Folder Ownership`

---

## 6. Secure Nginx Block for `n8n-data` Folder

- Go to `Nginx Config > Add Custom Config`
- Type: `location.root`
- Filename: `deny-n8n-data`
- Content:
    ```nginx
    location ^~ /n8n-data/ {
        deny all;
        return 404;
    }
    ```
- Save, test, and reload Nginx.

---

## 7. Configure Environment Variables

- In RunCloud File Manager:
  - Copy `.env.example` to `.env`
  - Update:
    - `N8N_BASIC_AUTH_USER=youruser`
    - `N8N_BASIC_AUTH_PASSWORD=yourpassword`
    - `N8N_HOST=sub.domain.com`
    - `WEBHOOK_URL=https://sub.domain.com/`
    - `N8N_ENCRYPTION_KEY=superlongrandomstring`
    - `DB_POSTGRESDB_PASSWORD=supersecret`
    - (Set other credentials as needed)

---

## 8. Configure Nginx Proxy for n8n

- Go to `Nginx Config` in RunCloud dashboard.
- Under Predefined Config:
    - Proxy: Effortlessly turn NGINX as a proxy server
    - Type: `location.root`
    - Config Name: `/etc/nginx-rc/extra.d/n8n.location.root.nginx-proxy.conf`
    - Paste only the proxy directives (no `location / {}` wrapper).

---

## 9. Install Docker & Docker Compose (SSH)

- SSH into your server.
- Run:
    ```bash
    sudo bash /home/runcloud/webapps/n8n/n8n-data/install-and-migration.sh
    ```

---

## 10. Start PostgreSQL & n8n (SSH as runcloud user)

- SSH into your server.
- Switch to the `runcloud` user:
    ```bash
    sudo -i -u runcloud
    cd /home/runcloud/webapps/n8n/n8n-data/
    docker-compose up -d n8n-postgres
    docker-compose up -d n8n
    ```
- Visit [https://sub.domain.com](https://sub.domain.com) to test.

---

## 11. Set Up Cron Jobs (For Recurring Tasks)

### 11A. Auto-Update n8n

- Job Name: `n8n auto-update`
- Command:
    ```bash
    cd /home/runcloud/webapps/n8n/n8n-data/ && docker-compose pull n8n && docker-compose up -d n8n
    ```
- Run As: `runcloud`
- Schedule: `0 3 * * *`

### 11B. Logical PostgreSQL Backup

- Job Name: `n8n postgres backup`
- Command:
    ```bash
    PGPASSWORD=yourpassword pg_dump -U n8nuser -h 127.0.0.1 n8ndb > /home/runcloud/webapps/n8n/n8n-data/postgres/pg_backup_$(date +\%F).sql
    ```
- Run As: `runcloud`
- Schedule: `0 2 * * *` (or as preferred)

> **What is a logical PostgreSQL backup?**  
> This creates a `.sql` file containing all n8n data (workflows, credentials, execution history, etc.)  
> You can restore this file with `psql` to recover everything.

### 11C. Monitor and Restart n8n and PostgreSQL Containers

- Job Name: `n8n container monitor`
- Command:
    ```bash
    N8N_STATUS=$(docker ps --filter "name=n8n" --filter "status=running" --format "{{.Names}}")
    PG_STATUS=$(docker ps --filter "name=postgres" --filter "status=running" --format "{{.Names}}")
    if [ -z "$N8N_STATUS" ] || [ -z "$PG_STATUS" ]; then
      cd /home/runcloud/webapps/n8n/n8n-data/
      docker-compose up -d
    fi
    ```
- Run As: `runcloud`
- Schedule: `*/5 * * * *`

---

## 12. Monitoring & Notifications

**A. Supervisor for Docker (recommended):**

- In RunCloud, go to your `n8n` web app > Supervisor.
- Add New Supervisor Job:
  - Job Name: `docker`
  - Run As: `runcloud`
  - Auto Restart: Enabled
  - Auto Start: Enabled
  - Numprocs: `1`
  - Command:  
    ```
    /usr/bin/systemctl start docker
    ```
- Save the Supervisor job.

**B. Notifications:**
- In RunCloud > Integrations > Notifications:
  - Add your preferred channel (email, Slack, etc.)
  - Enable notifications for Supervisor events, backups, and server issues.

---

## 13. Secure Manual Update Workflow in n8n

- Import this JSON workflow into n8n (replace user/pass as needed):

```json
{
  "nodes": [
    {
      "parameters": {
        "path": "trigger-update",
        "httpMethod": "POST",
        "authentication": "basicAuth"
      },
      "id": "WebhookTrigger",
      "name": "Webhook",
      "type": "n8n-nodes-base.webhook",
      "typeVersion": 1,
      "position": [250, 250],
      "credentials": {
        "httpBasicAuth": {
          "user": "youradminuser",
          "password": "youradminpassword"
        }
      }
    },
    {
      "parameters": {
        "command": "/home/runcloud/webapps/n8n/n8n-data/update_n8n.sh"
      },
      "id": "ExecuteCommand",
      "name": "Execute Command",
      "type": "n8n-nodes-base.executeCommand",
      "typeVersion": 1,
      "position": [550, 250]
    },
    {
      "parameters": {
        "responseData": "n8n update triggered."
      },
      "id": "RespondToWebhook",
      "name": "Respond to Webhook",
      "type": "n8n-nodes-base.respondToWebhook",
      "typeVersion": 1,
      "position": [850, 250]
    }
  ],
  "connections": {
    "WebhookTrigger": {
      "main": [
        [
          {
            "node": "ExecuteCommand",
            "type": "main",
            "index": 0
          }
        ]
      ]
    },
    "ExecuteCommand": {
      "main": [
        [
          {
            "node": "RespondToWebhook",
            "type": "main",
            "index": 0
          }
        ]
      ]
    }
  }
}
```
- Set strong credentials for the webhook node.
- Activate the workflow.

## 14\. Migration/Restore — ONLY for Restoring Old/Existing Files or Databases on a New Server

> **Follow this step ONLY when restoring from backup or moving to a new server.
> Skip for a new installation.**

**A. Complete all steps above first on your new server.**

**B. Restore your backup of `/home/runcloud/webapps/n8n/` to the same path.**

-   Includes:
    -   `/n8n-data/` (all files, folders, volumes)
    -   `.env`, compose, scripts, etc.
-   Set file ownerships via RunCloud tool.
-   Remove `.gitkeep` from `postgres/`.

**C. Review configs (`.env`, `docker-compose.yml`).**

**D. Start containers as runcloud user:**
```
sudo -i -u runcloud
cd /home/runcloud/webapps/n8n/n8n-data/
docker-compose up -d
```
- Check with docker-compose ps and logs.

**E. Test your site at [https://sub.domain.com](https://sub.domain.com)**

**F. Re-create cron jobs, Supervisor, notifications if missing.**

**G. Update DNS if needed.**

## 15\. Security Best Practices

-   Never store secrets in `/public/`
-   Use strong credentials in `.env`
-   Regularly test backup and restore
-   Keep RunCloud, Docker, and n8n updated

## Tips: What To Do If You Update `docker-compose.yml`, `.env`, or Nginx `.conf` Files

### If you update `docker-compose.yml` or `.env`:

You must restart Docker containers so changes take effect.

**How to do it (via SSH):**
```
sudo -i -u runcloud
cd /home/runcloud/webapps/n8n/n8n-data/
docker-compose up -d
```
### If you update your Nginx `.conf` file:

You must reload Nginx for changes to apply.

-   Go to your web app in the RunCloud dashboard.
-   Click the “Reload Nginx” button.

|File Changed|What To Do After Change|Where to do it|
|:----|:----|:----|
|docker-compose.yml|SSH as runcloud, run docker-compose up -d|SSH terminal|
|.env|SSH as runcloud, run docker-compose up -d|SSH terminal|
|Nginx config|Click “Reload Nginx” in RunCloud UI|RunCloud dashboard|



