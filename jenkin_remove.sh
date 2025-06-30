#!/bin/bash
set -e

echo "Stopping Jenkins service if running..."
sudo systemctl stop jenkins || true

echo "Removing Jenkins package and data..."
sudo apt purge -y jenkins
sudo apt autoremove -y

echo "Removing Jenkins files and directories..."
sudo rm -rf /etc/apt/sources.list.d/jenkins.list
sudo rm -rf /usr/share/keyrings/jenkins-keyring.asc
sudo rm -rf /usr/share/jenkins /var/lib/jenkins /var/cache/jenkins /var/log/jenkins
sudo rm -rf /etc/systemd/system/jenkins.service.d

echo "Removing all Java packages..."
# This will remove all installed OpenJDK packages
sudo apt purge -y openjdk-* icedtea-* icedtea6-*

echo "Autoremoving leftover packages..."
sudo apt autoremove -y

echo "Cleaning apt cache..."
sudo apt clean

echo "Verifying removal..."

if ! command -v java &> /dev/null
then
    echo "Java removed successfully."
else
    echo "Warning: Java still installed."
fi

if ! systemctl is-active --quiet jenkins
then
    echo "Jenkins service removed successfully."
else
    echo "Warning: Jenkins service still exists."
fi

echo "Removal complete."