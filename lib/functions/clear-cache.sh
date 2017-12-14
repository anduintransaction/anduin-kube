#!/usr/bin/env bash

function clearCache {
    if [ `whoami` != "root" ]; then
        echo "Must be root"
        exit 1
    fi
    case `uname` in
        Darwin)
            killall -HUP mDNSResponder
            dscacheutil -flushcache
            ;;
    esac
}

