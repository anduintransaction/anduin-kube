#!/usr/bin/env bash

function fix {
    iptableSuccess=0
    until [ $iptableSuccess -eq 1 ]; do
        if ! runCommandOnMinikube 'sudo iptables -L FORWARD 1 | grep "fix recursive routing" > /dev/null 2>&1'; then
            runCommandOnMinikube 'sudo iptables -I FORWARD 1 -p tcp -d 10.96.0.0/12 -j REJECT --reject-with icmp-port-unreachable -m comment --comment "fix recursive routing"'
            if [ $? -eq 0 ]; then
                iptableSuccess=1
            else
                sleep 5
            fi
        else
            iptableSuccess=1
        fi
    done
    sudo -E anduin-kube setup-network
}
