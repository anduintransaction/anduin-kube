#!/bin/sh

sudo mkdir -p /mnt/sda1/var/init.d && \
    sudo mkdir -p /mnt/sda1/var/lib/init && \
    sudo cp /home/docker/init-service-install/init.sh /mnt/sda1/var/lib/init/init.sh
