#!/usr/bin/env bash

function cleanup {
    if [ `whoami` != "root" ]; then
        echo "Must be root"
        exit 1
    fi
    stopCoreDNS && cleanupDNS && cleanupRoute
}
