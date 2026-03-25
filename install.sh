#!/bin/bash

if ! id "devops" &>/dev/null; then
    useradd devops
    chsh -s /bin/bash devops
    mkdir -p /home/devops/.ssh
    touch /home/devops/.ssh/authorized_keys
    chmod 0700 /home/devops/.ssh
    chmod 0600 /home/devops/.ssh/authorized_keys
    chown -R devops:devops /home/devops
fi

cd /home/devops
if [ -d "rootless-devops" ]; then
    rm -rf rootless-devops
fi
git clone https://github.com/myvesta/rootless-devops.git
cd rootless-devops

cp -r etc/* /etc/
chmod 440 /etc/sudoers.d/devops

cp -r usr/local/bin/* /usr/local/bin/
chmod +x /usr/local/bin/devops-*
chmod -x /usr/local/bin/devops-func.sh

if [ -f "/usr/local/bin/devops-override-conf" ]; then
    chown root:root /usr/local/bin/devops-override-conf
    chmod 0644 /usr/local/bin/devops-override-conf
fi

if [ -f "/usr/local/bin/devops-self-update-blocked" ]; then
    chown root:root /usr/local/bin/devops-self-update-blocked
    chmod 0644 /usr/local/bin/devops-self-update-blocked
fi

touch /var/log/devops-denied-access.log
chown root:root /var/log/devops-denied-access.log
chmod 0600 /var/log/devops-denied-access.log
