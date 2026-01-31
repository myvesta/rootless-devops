#!/bin/bash

allowed_paths_for_read=(
    "/etc/"
    "/var/log/"
)

allowed_paths_for_write=(
    "/etc/"
    "/var/log/"
)

banned_paths=(
    "/etc/passwd"
    "/etc/shadow"
    "/etc/group"
    "/etc/gshadow"
    "/etc/hosts"
    "/etc/resolv.conf"
    "/etc/sudoers"
    "/etc/sudoers.d/"
    "/etc/ssh/"
    "/etc/environment"
    "/etc/profile"
    "/etc/bashrc"
    "/etc/systemd/"
    "/lib/systemd"
    "/etc/cron"
)

startup_checks() {
    if [ -z "$2" ]; then
        echo "Usage: $0 <file>"
        exit 1
    fi

    if [ "$1" == "read" ]; then
        if [ ! -f "$2" ] && [ ! -d "$2" ]; then
            echo "Path not found: $2"
            exit 1
        fi
    fi
}

check_for_common_traversal_attempts() {
    if [[ "$1" == *"../"* || "$1" == *"~/"* || "$1" == *" "* ]]; then
        echo "Path not allowed (common traversal attempt): $1"
        exit 1
    fi
}

check_for_banned_paths() {
    for path in "${banned_paths[@]}"; do
        if [[ "$1" == "$path"* ]]; then
            echo "Path not allowed (banned path): $1"
            exit 1
        fi
    done
}

is_allowed_path_for_read() {
    check_for_common_traversal_attempts "$1"
    check_for_banned_paths "$1"
    for path in "${allowed_paths_for_read[@]}"; do
        if [[ "$1" == "$path"* ]]; then
            return 0
        fi
    done
    echo "Path not allowed for read: $1"
    exit 1
}

is_allowed_path_for_write() {
    check_for_common_traversal_attempts "$1"
    check_for_banned_paths "$1"
    for path in "${allowed_paths_for_write[@]}"; do
        if [[ "$1" == "$path"* ]]; then
            return 0
        fi
    done
    echo "Path not allowed for write: $1"
    exit 1
}

is_allowed_path_for_mode() {
    if [ "$1" == "read" ]; then
        is_allowed_path_for_read "$2"
    elif [ "$1" == "write" ]; then
        is_allowed_path_for_write "$2"
    fi
}
