Odoo 18 Deployment with Docker, Nginx, PostgreSQL & Jenkins CI/CD
-------------------------------------------------------------------
This repository provides a complete production-ready setup for deploying Odoo 18 using Docker Compose, PostgreSQL, and Nginx with SSL and domain support. It includes an automated Jenkins pipeline that monitors your custom Odoo addons, pulls changes, and reloads the Odoo container seamlessly.
Docker & Docker Compose installed on the server

Jenkins server with Git access and permission to run Docker commands

Domain pointed to your server IP (for Nginx + SSL)

Basic knowledge of Odoo and Docker

Setup & Deployment
Clone this repository:


git clone https://github.com/durgeshgupt9/odoo_jenkins_cicd.git
cd odoo_project
Run the installation script to create deployment structure and start containers:

bash jenkins_install.sh
bash nginx_domain_odoo.sh
This script will:

Create nginx-odoo-setup-docker/ folder with subdirectories

Copy necessary configs (docker-compose.yml, odoo.conf, Nginx files)

Launch PostgreSQL, Odoo, and Nginx containers with SSL & domain setup

Jenkins CI/CD Pipeline
Polling: Jenkins polls the Git repository every 5 minutes for changes in addons/.

On change:

Jenkins pulls latest changes.

Restarts the Odoo Docker container (odoo18-app).

Runs optional deploy.sh inside Odoo container for module upgrades.

How to Configure
Configure Jenkins with the included Jenkinsfile.

Ensure Jenkins user can access Docker and the project directory.

Modify environment variables in Jenkinsfile as needed.

Development Workflow
Develop your custom modules inside nginx-odoo-setup-docker/addons/.

Commit and push your code to the Git repository.

Jenkins automatically deploys updates with zero downtime by restarting only the Odoo container.

Manual Docker Commands
Start services manually:


cd nginx-odoo-setup-docker
docker-compose up -d
Stop services:


docker-compose down
View Odoo logs:


docker logs -f odoo18-app
Configuration Details
Odoo config: nginx-odoo-setup-docker/config/odoo.conf

Custom addons: nginx-odoo-setup-docker/addons/

Nginx config & SSL: nginx-odoo-setup-docker/nginx/conf.d/

Docker Compose file: nginx-odoo-setup-docker/docker-compose.yml

Troubleshooting
Check Odoo container logs for errors:


docker logs odoo18-app
Ensure PostgreSQL container is running and volumes have correct permissions.

Verify domain and SSL certificates are correctly configured in Nginx.
