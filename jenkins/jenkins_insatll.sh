#!/bin/bash
set -e

echo "Updating package lists..."
sudo apt update

echo "Installing OpenJDK 17..."
sudo apt install -y openjdk-17-jdk

echo "Setting Java 17 as default..."
sudo update-alternatives --install /usr/bin/java java /usr/lib/jvm/java-17-openjdk-amd64/bin/java 2
sudo update-alternatives --set java /usr/lib/jvm/java-17-openjdk-amd64/bin/java

echo "Verifying Java version..."
java -version

echo "Removing old Jenkins installation and configs..."
sudo systemctl stop jenkins || true
sudo apt purge -y jenkins
sudo apt autoremove -y
sudo rm -rf /etc/apt/sources.list.d/jenkins.list /usr/share/keyrings/jenkins-keyring.asc
sudo rm -rf /usr/share/jenkins /var/lib/jenkins /var/cache/jenkins /var/log/jenkins

echo "Adding official Jenkins repo and key..."
wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key | \
  sudo tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null

echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" | \
  sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null

echo "Updating package lists..."
sudo apt update

echo "Installing Jenkins..."
sudo apt install -y jenkins

echo "Creating systemd override to use correct jenkins.war path..."
sudo mkdir -p /etc/systemd/system/jenkins.service.d/

sudo tee /etc/systemd/system/jenkins.service.d/override.conf > /dev/null <<EOF
[Service]
ExecStart=
ExecStart=/usr/bin/java -Djava.awt.headless=true -jar /usr/share/java/jenkins.war
EOF

echo "Reloading systemd daemon and restarting Jenkins service..."
sudo systemctl daemon-reload
sudo systemctl enable --now jenkins

echo "Fixing Jenkins directories ownership..."
sudo chown -R jenkins:jenkins /var/lib/jenkins /var/log/jenkins /var/cache/jenkins

echo "Jenkins status:"
sudo systemctl status jenkins --no-pager

echo "Installation complete! Access Jenkins at http://<your-server-ip>:8080"
echo "To get the initial admin password, run:"
echo "  sudo cat /var/lib/jenkins/secrets/initialAdminPassword"