# n8n + Docker + PostgreSQL on RunCloud  
**Subdomain:** `sub.domain.com`  
**Web App Name:** `n8n`  
**Web App Path:** `/home/runcloud/webapps/n8n/`

---

## 1. Prepare Your Files and Folder Structure
```
n8n-setup/
├── n8n-data/
│ ├── docker-compose.yml
│ ├── .env.example
│ ├── update_n8n.sh
│ ├── install-and-migration.sh
│ ├── monitor-containers.sh
│ ├── fix_n8n_permissions.sh
│ ├── manual-n8n-update-workflow.json
│ ├── data/
│ │ └── .gitkeep
│ ├── postgres/
│ │ └── .gitkeep
├── README.md
├── .gitignore
```


**.gitignore example:**
```
.env  
n8n-data/data/  
n8n-data/postgres/  
*.sql
```

---

## 2. Create the RunCloud Web App

- Log into RunCloud dashboard.
- Go to `Web Applications > Create Application`
- Application Stack: **Static**
- Domain: `sub.domain.com`
- Web Application Name: `n8n`
- Root Path: `/home/runcloud/webapps/n8n/`
- Create Application
- **Enable RunCloud Backup for this web app**:
-   Go to **Backups** in the RunCloud dashboard.
-   Add a backup job targeting `/home/runcloud/webapps/n8n/`.
-   Set schedule and retention as desired.

---

## 3. Enable SSL

- Go to your `n8n` web app in RunCloud.
- Go to **SSL/TLS** tab.
- Click **Install Free SSL (Let’s Encrypt)**
- Enable **Force SSL**

---

## 4. Upload Files, Remove `.gitkeep`, and Make scripts Executable
```
# Check if unzip is installed, install if missing
if ! command -v unzip &> /dev/null; then
  sudo apt-get update
  sudo apt-get install -y unzip
fi

# Download the repo as a zip
wget https://github.com/zeniusco/n8n-setup/archive/refs/heads/main.zip -O n8n-setup.zip

# Unzip the archive
unzip n8n-setup.zip

# Copy all contents to your webapp directory (use sudo)
sudo cp -r n8n-setup-main/* /home/runcloud/webapps/n8n/

# Clean up the downloaded zip and extracted folder
rm n8n-setup.zip
rm -rf n8n-setup-main/

# IMPORTANT: Remove .gitkeep (or any file) from the Postgres folder so the database can initialize
sudo rm -f /home/runcloud/webapps/n8n/n8n-data/postgres/.gitkeep

# (Optional: Also remove from data folder, though not required for n8n to work)
sudo rm -f /home/runcloud/webapps/n8n/n8n-data/data/.gitkeep

# Make scripts executable
sudo chmod +x /home/runcloud/webapps/n8n/n8n-data/update_n8n.sh
sudo chmod +x /home/runcloud/webapps/n8n/n8n-data/monitor-containers.sh
sudo chmod +x /home/runcloud/webapps/n8n/n8n-data/install-and-migration.sh
sudo chmod +x /home/runcloud/webapps/n8n/n8n-data/fix_n8n_permissions.sh
```

## Install dos2unix (for line ending fixes):
```
sudo apt-get install dos2unix
```
---

## 5. Set File and Folder Ownership

-   In the RunCloud dashboard, go to your `n8n` web app.
-   Go to **Tools > Fix File and Folder Ownership**.
-   Click the button to run the tool.

---

## 6. Secure Nginx Block for `n8n-data` Folder

-   In RunCloud dashboard, go to your `n8n` web app.
-   Go to **Nginx Config > Add Custom Config**.
-   Set:
    -   **Type:** `location.root`
    -   **Filename:** `deny-n8n-data`
    -   **Content:**

    ```nginx
    location ^~ /n8n-data/ {
        deny all;
        return 404;
    }
    ```
- Save, test, and reload Nginx.

---

## 7. Configure Environment Variables

In RunCloud **File Manager**:
- Copy `/home/runcloud/webapps/n8n/n8n-data/.env.example` to `.env`.
- **Edit `.env` and update following:**
```
N8N_BASIC_AUTH_USER=youruser
N8N_BASIC_AUTH_PASSWORD=yourpassword
N8N_HOST=sub.domain.com
WEBHOOK_URL=https://sub.domain.com/
N8N_ENCRYPTION_KEY=superlongrandomstring
DB_POSTGRESDB_PASSWORD=supersecret

# SMTP settings for Send Email node
N8N_SMTP_HOST=smtp.example.com
N8N_SMTP_USER=your@email.com
N8N_SMTP_PASS=yourpassword
N8N_SMTP_SENDER=your@email.com
N8N_SMTP_PORT=587
N8N_SMTP_SSL=false
```
- (Set other passwords/usernames as needed.)

---

## 8. Configure Nginx Proxy for n8n

1.  In your RunCloud dashboard, go to your `n8n` web app.
2.  Go to **Nginx Config**.
3.  Under **Predefined Config (Optional):**
    -   Look for **Proxy: Effortlessly turn NGINX as a proxy server**
    -   **Type:** `location.root`
    -   **Config Name:** `/etc/nginx-rc/extra.d/n8n.location.root.nginx-proxy.conf`
4.  **Edit `/etc/nginx-rc/extra.d/n8n.location.root.nginx-proxy.conf`** and paste in only these lines:
```
proxy_pass http://127.0.0.1:5678;
proxy_set_header Host $host;
proxy_set_header X-Real-IP $remote_addr;
proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
proxy_set_header X-Forwarded-Proto $scheme;
proxy_http_version 1.1;
proxy_set_header Upgrade $http_upgrade;
proxy_set_header Connection "upgrade";
proxy_read_timeout 300s;
```
- **Save the file.**
- **Click the “Reload Nginx” button in RunCloud** to apply the changes.


## **9\. Install Docker & Docker Compose (One-Time, SSH Step)**

    ```bash
    sudo bash /home/runcloud/webapps/n8n/n8n-data/install-and-migration.sh
    ```

---

## 10. Start PostgreSQL & n8n (SSH as runcloud user)
  
    ```bash
    sudo -i -u runcloud
    cd /home/runcloud/webapps/n8n/n8n-data/
    docker-compose up -d n8n-postgres
    docker-compose up -d n8n
    ```
- Visit [https://sub.domain.com](https://sub.domain.com) to test.

---

## 11. Set Up Cron Jobs (For Recurring Tasks)

## Before you being this step: make sure you have followed this repo: [https://github.com/zeniusco/server-email-setup](https://github.com/zeniusco/server-email-setup) and installed server-wide mail system.

## Add each of these cron jobs separately in your RunCloud Cron Jobs UI, specifying the user and schedule for each.

### A. Fix Line Endings for All Text Files

- Job Name: `auto fix line endings`
- Command:

```
for ext in sh json yml yaml env md; do find /home/runcloud/webapps/n8n/n8n-data/ -type f -name "*.$ext" -exec dos2unix {} \; || echo "$ext dos2unix failed" | mail -s "dos2unix fail" you@email.com; done
```

- **Note:** Replace `you@email.com` with your real email address.
- **Vendor Binary:** Select **“Write your own”** in RunCloud and paste the command above.
- Run As: `runcloud`
- Schedule: `0 */6 * * *` (every 6 hours)

### B. Ensure 700 Permission for fix_n8n_permissions.sh

- Job Name: `chmod 700 fix_n8n_permissions`
- Command:

```
f=/home/runcloud/webapps/n8n/n8n-data/fix_n8n_permissions.sh;e=you@email.com;[ -e $f ]&&/usr/bin/chmod 700 $f||echo "$f:chmodfail" |/usr/bin/mail -s "chmodfail" $e;[-e $f ]||echo "$f:missing"|/usr/bin/mail -s "missing" $e
```

- **Note:** Replace `you@email.com` with your real email address.
- **Vendor Binary:** Select **“Write your own”** in RunCloud and paste the command above.
- Run As: `runcloud`
- Schedule: `0 */6 * * *` (every 6 hours)

### C. Fix All Other Permissions

- Job Name: `chmod permission fix all`
- Command:

```
/home/runcloud/webapps/n8n/n8n-data/fix_n8n_permissions.sh
```

- **Vendor Binary:** Select **`/bin/bash`** in RunCloud.
- Run As: `root`
- Schedule: `0 */6 * * *` (every 6 hours)

### D. Auto-Update n8n

- Job Name: `n8n auto-update`
- Command:

    ```bash
    cd /home/runcloud/webapps/n8n/n8n-data/ && docker-compose pull n8n && docker-compose up -d n8n && echo "$(date) OK" | mail -s "n8n Update SUCCESS" youremail@yourdomain.com|| echo "$(date) FAIL" | mail -s "n8n Update FAIL" youremail@yourdomain.com
    ```
    
- **Vendor Binary:** Select **`/bin/bash`** in RunCloud.
- Run As: `runcloud`
- Schedule: `0 3 * * *` (every day at 3am, or any time you prefer)


### E. Logical PostgreSQL Backup

- Job Name: `n8n postgres backup`
- Command:

    ```bash
    cd /home/runcloud/webapps/n8n/n8n-data/ && PGPASSWORD=yourpassword pg_dump -U n8nuser -h 127.0.0.1 n8ndb > postgres/pg_backup_$(date +\%F).sql || echo "PG backup FAIL $(date)" | mail -s "PG Backup FAIL" youremail@yourdomain.com
    ```
    
- **Vendor Binary:** Select **`/bin/bash`** in RunCloud.
- **Note:** Replace `you@email.com` with your real email address
- **Note:** Replace yourpassword, n8nuser, and n8ndb with your actual DB credentials from .env.
- Run As: `runcloud`
- Schedule: `0 2 * * *` (every day at 2am, or any time you prefer)

#### **What is a logical PostgreSQL backup?**
- `pg_dump` creates a logical (SQL) backup of your PostgreSQL database, saving all your n8n data—including workflows, credentials, history, etc.—as a portable `.sql` file.
- You can restore this file on any PostgreSQL server using `psql` to recover all n8n data.

### F. Monitor and Restart n8n and PostgreSQL Containers
- Job Name: `n8n container monitor`
- Command:
  
    ```bash
    /home/runcloud/webapps/n8n/n8n-data/monitor-containers.sh
    ```

- **Note:** Replace `you@email.com` with your real email address
- **Vendor Binary:** Select **`/bin/bash`** in RunCloud.
- Run As: `runcloud`
- Schedule: `*/10 * * * *` (every 10 minutes)

**What does this do?**
-   This script checks if the n8n and PostgreSQL containers are running every 5 minutes.
-   If either container is not running, it will automatically restart both by running `docker-compose up -d`.

### G. Docker Restart
- Job Name: `docker restart`
- Command:
  
    ```bash
    if ! pgrep dockerd > /dev/null; then service docker start || echo "Docker could not be started on $(hostname) at $(date)" | mail -s "Docker restart FAIL" youremail@yourdomain.com; fi
    ```

- **Note:** Replace `you@email.com` with your real email address
- **Vendor Binary:** Write your own
- Run As: `root`
- Schedule: `*/10 * * * *` (every 10 minutes)

---

## 12. Log Monitoring & Notifications
 
**A. Enable RunCloud’s Log Monitoring Features:**

1.  **Go to your n8n web app in the RunCloud dashboard.**
2.  **Navigate to the “Monitoring” section**
3.  **Enable the following features:**
    -   **Top Path** – to see your most frequently accessed URLs/routes.
    -   **IP Address Hit** – to monitor which IPs are making the most requests.
    -   **Slow Script** – to catch slow requests and performance issues.
4.  **For Slow Script:**
    -   **Set the threshold to `1 second`** (recommended to catch even brief slowdowns).
    -   Adjust higher if you see too many false positives.
  
**B. Notifications:**
- In RunCloud > Integrations > Notifications:
  - Add your preferred channel (email, Slack, etc.)
  - Enable notifications for Supervisor events, backups, and server issues.

---

## 13. Create an Error Trigger Node in n8n to send all workflow failure email notification

**Step 1: Add the Error Trigger Node**

-   Add the **Error Trigger** node as the first node.
    -   This node is triggered **automatically** when any workflow (that references this error workflow) fails.

**Step 2: Add the Send Email Node**

-   Add a **Send Email** node connected to the Error Trigger node.
-   Configure it

**Step 3: Save the Workflow**

-   Save and **activate** the workflow.

**Step 4: Link This Error Workflow to Other Workflows**

-   Open any workflow you want monitored.
-   Go to **Workflow Settings** (top right ⚙️).
-   Set the **Error Workflow** to the error handler workflow you just created.
-   Save the settings.

---
## Secure Manual Update Workflow in n8n

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

## Migration/Restore — ONLY for Restoring Old/Existing Files or Databases on a New Server

> **Follow this step ONLY when restoring from backup or moving to a new server.
> Skip for a new installation.**

### **A. Complete All Steps Above First**

-   Do all setup steps 1–12 (new web app, SSL, Docker, configs, cronjobs etc.) on the new server.

### **B. Restore Your Files and Data**

**Restore your backup of `/home/runcloud/webapps/n8n/` to the same path on the new server.**
    -   Includes:
        -   `/n8n-data/` (all files and folders)
        -   `.env` file
        -   Docker Compose file, scripts, workflows, etc.
        -   Docker volumes:
            -   `n8n-data/data/` (workflows, credentials, config)
            -   `n8n-data/postgres/` (PostgreSQL data)
    -   Transfer via `rsync`, `scp`, SFTP, or RunCloud backup restore.
-   **Set ownerships with RunCloud “Fix File and Folder Ownership” tool.**
-   **Remove any `.gitkeep` files from the `postgres` directory:**
-   ```sudo rm -f /home/runcloud/webapps/n8n/n8n-data/postgres/.gitkeep```


### **C. Review Configs**
-   Double-check `.env` and `docker-compose.yml` for correct domains, credentials, etc.

### **D. Start Containers**

1.  **Switch to `runcloud` user:**
```
sudo -i -u runcloud
cd /home/runcloud/webapps/n8n/n8n-data/
```

2.  **Start containers:**
```
docker-compose up -d
```

3.  **Check status:**
```
docker-compose ps
docker-compose logs n8n
docker-compose logs n8n-postgres
```

### **E. Test Your Site**

-   Visit https://sub.domain.com and log in to n8n.


### **F. Re-create Cron Jobs, Supervisor, and Notifications (if not included in backup)**

-   Double-check all cronjobs and notifications in RunCloud.

### **G. Update DNS if needed with new server IP**


## **15\. Security Best Practices**

-   Never store secrets in `/public/` (no longer present)
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
