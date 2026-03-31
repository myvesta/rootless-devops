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

echo "== Installing rootless-devops software"

if [ ! -z "$1" ]; then
    repo_url="$1"
    echo "$repo_url" > /usr/local/bin/devops-repo-url
    chmod 0600 /usr/local/bin/devops-repo-url
    chown root:root /usr/local/bin/devops-repo-url
    echo "= Repository URL set to: $repo_url"
else
    repo_url="https://github.com/myvesta/rootless-devops.git"
fi

if [ ! -z "$2" ]; then
    repo_folder_name="$2"
    echo "$repo_folder_name" > /usr/local/bin/devops-repo-folder-name
    chmod 0600 /usr/local/bin/devops-repo-folder-name
    chown root:root /usr/local/bin/devops-repo-folder-name
    echo "= Repository folder name set to: $repo_folder_name"
else
    repo_folder_name="rootless-devops"
fi

if [ -f "/usr/local/bin/devops-repo-url" ]; then
    repo_url_owner=$(stat -c "%U" /usr/local/bin/devops-repo-url)
    repo_url_group=$(stat -c "%G" /usr/local/bin/devops-repo-url)
    repo_url_mode=$(stat -c "%a" /usr/local/bin/devops-repo-url)
    if [ "$repo_url_owner" = "root" ] && [ "$repo_url_group" = "root" ] && [ "$repo_url_mode" = "600" ]; then
        repo_url=$(cat /usr/local/bin/devops-repo-url)
        echo "= Using configured repository URL: $repo_url"
    fi
fi

if [ -f "/usr/local/bin/devops-repo-folder-name" ]; then
    repo_folder_name_owner=$(stat -c "%U" /usr/local/bin/devops-repo-folder-name)
    repo_folder_name_group=$(stat -c "%G" /usr/local/bin/devops-repo-folder-name)
    repo_folder_name_mode=$(stat -c "%a" /usr/local/bin/devops-repo-folder-name)
    if [ "$repo_folder_name_owner" = "root" ] && [ "$repo_folder_name_group" = "root" ] && [ "$repo_folder_name_mode" = "600" ]; then
        repo_folder_name=$(cat /usr/local/bin/devops-repo-folder-name)
        echo "= Using configured repository folder name: $repo_folder_name"
    fi
fi

if [ -d "$repo_folder_name" ]; then
    rm -rf $repo_folder_name
fi

git clone $repo_url

cd $repo_folder_name

source hooks/install-pre.sh

source hooks/setup-files.sh

source hooks/install-post.sh

echo "== Rootless-devops software installed"

exit 0
