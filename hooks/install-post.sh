#!/bin/bash

if [ -d "override" ]; then
    files_count=$(ls -1 override/ 2>/dev/null | wc -l)
    if [ $files_count -gt 0 ]; then
        cp override/* /usr/local/bin/
        echo "= Copied override files to /usr/local/bin/"
    fi
fi

if [ -f "/usr/local/bin/devops-override-conf" ]; then
    chown root:root /usr/local/bin/devops-override-conf
    chmod 0644 /usr/local/bin/devops-override-conf
    echo "= Set permissions for /usr/local/bin/devops-override-conf"
fi

if [ -f "override-devops-ssh-keys/authorized_keys" ]; then
    cp override-devops-ssh-keys/authorized_keys /home/devops/.ssh/authorized_keys
    chown devops:devops /home/devops/.ssh/authorized_keys
    chmod 0600 /home/devops/.ssh/authorized_keys
    echo "= Copied override-devops-ssh-keys/authorized_keys to /home/devops/.ssh/authorized_keys"
fi
