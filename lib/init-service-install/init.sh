#!/bin/sh

for initFile in `ls /mnt/sda1/var/init.d/*.sh 2>/dev/null`; do
    sudo $initFile start
done
