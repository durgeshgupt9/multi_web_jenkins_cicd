# Dynamic Docker-based NGINX with Jenkins CI/CD, SSL, and Auto HTML Generation

This project sets up a **Docker-based NGINX** load balancer with:

- Dynamic container restarts on Git changes using **Jenkins CI/CD (Poll SCM)**
- No `docker-compose` – handled via individual Docker commands
- Domain-based routing with **SSL support**
- Auto-generated HTML landing page
- NGINX reload without downtime
- Systemd integration to manage the container via `systemctl`

---

## Features

| Feature                    | Description                                      |
|----------------------------|--------------------------------------------------|
| Docker NGINX            | Lightweight containerized NGINX reverse proxy    |
| Auto-Restart            | Git SCM trigger via Jenkins                      |
| Auto HTML               | Dynamic HTML generation on deploy                |
| SSL Support             | Self-signed or real certificates (Let's Encrypt) |
| Domain Load Balancing   | Ready for domain-level traffic handling          |

---

script
bash nginx_setup.sh

Jenkins CI/CD Setup
Use the provided Jenkinsfile to:

Poll your Git repo every minute

Clone HTML files

Auto-generate HTML

Rebuild & restart the container

Reload NGINX inside Docker
 Domain & SSL Setup
1. Self-Signed SSL (for testing)

openssl req -x509 -nodes -days 365 \
-newkey rsa:2048 \
-keyout ssl/yourdomain.key \
-out ssl/yourdomain.crt \
-subj "/CN=yourdomain.com"
2. Real SSL (Production)
Use Certbot + DNS/HTTP challenge (optional integration)

Restart Behavior (CI/CD Flow)
Jenkins polls repo

On change:

Clones repo

Generates new HTML

Rebuilds Docker image

Restarts container

Reloads NGINX config (no downtime)