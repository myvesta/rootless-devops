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
