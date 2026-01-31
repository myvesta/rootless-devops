#!/bin/bash

cd /root
if [ -d "rootless-devops" ]; then
    rm -rf rootless-devops
fi
git clone https://github.com/myvesta/rootless-devops.git
cd rootless-devops
cp -r etc/* /etc/
chmod 440 /etc/sudoers.d/devops
