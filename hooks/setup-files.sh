#!/bin/bash

if [ ! -d "hooks" ]; then
    echo "ERROR: I'm not in the rootless-devops repository folder"
    exit 1
fi

cp -r etc/* /etc/
chmod 440 /etc/sudoers.d/devops

cp -r usr/local/bin/* /usr/local/bin/
chmod +x /usr/local/bin/devops-*
chmod +x /usr/local/bin/devops_*
chmod -x /usr/local/bin/devops-func.sh

if [ -f "/usr/local/bin/devops-override-conf" ]; then
    chown root:root /usr/local/bin/devops-override-conf
    chmod 0644 /usr/local/bin/devops-override-conf
fi

if [ -f "/usr/local/bin/devops-self-update-blocked" ]; then
    chown root:root /usr/local/bin/devops-self-update-blocked
    chmod 0644 /usr/local/bin/devops-self-update-blocked
fi

if [ -f "/usr/local/bin/devops-repo-url" ]; then
    chown root:root /usr/local/bin/devops-repo-url
    chmod 0600 /usr/local/bin/devops-repo-url
fi

if [ -f "/usr/local/bin/devops-repo-folder-name" ]; then
    chown root:root /usr/local/bin/devops-repo-folder-name
    chmod 0600 /usr/local/bin/devops-repo-folder-name
fi

touch /var/log/devops-denied-access.log
chown root:root /var/log/devops-denied-access.log
chmod 0600 /var/log/devops-denied-access.log
