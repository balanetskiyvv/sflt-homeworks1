#!/bin/bash

SOURCE_DIR="/home/balanetskiyvm1"
TARGET_DIR="/tmp/backup"

rsync -ac --exclude '.*' "$SOURCE_DIR" "$TARGET_DIR" > /dev/null 2>> /var/log/backup.log

if [[ $? -eq 0 ]]; then
        echo "[$(date)] Резервное копирование выполнено успешно!" >> /var/log/backup.log
else
        echo "[$(date)] Ошибка при выполнении резервного копирования!" >> /var/log/backup.log
fi
