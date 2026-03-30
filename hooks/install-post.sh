#!/bin/bash

if [ -d "override" ]; then
    cp override/* /usr/local/bin/
    echo "= Copied override files to /usr/local/bin/"
fi

if [ -f "/usr/local/bin/devops-override-conf" ]; then
    chown root:root /usr/local/bin/devops-override-conf
    chmod 0644 /usr/local/bin/devops-override-conf
    echo "= Set permissions for /usr/local/bin/devops-override-conf"
fi

