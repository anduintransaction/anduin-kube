#!/usr/bin/env bash

function removeMinikube {
    if [ $(minikubeStatus) != "NA" ]; then
        echo "Deleting minikube machine"
        minikube delete
    fi
    if kubectl config get-contexts | grep minikube > /dev/null 2>&1; then
        echo "Deleting minikube context"
        kubectl config delete-context minikube
    fi
    echo "Deleting minikube configs"
    rm -rf ~/.minikube
}

function cleanupVBox {
    deleteVBoxNetwork $MINIKUBE_CIDR
}

function cleanupDNS {
    networksetup -listallnetworkservices | grep -v '\*' | while read line; do
        currentNS=`networksetup -getdnsservers "$line"`
        if [[ $currentNS != There* ]] && [[ $currentNS == *$MINIKUBE_IP* ]]; then
            currentNS=`echo $currentNS | sed 's/'$MINIKUBE_IP'//g' | sed 's/\s*//'`
            sudo networksetup -setdnsservers "$line" $currentNS
        fi
        currentSearch=`networksetup -getsearchdomains "$line"`
        if [[ $currentSearch != There* ]] && [[ $currentSearch == *svc.coredns.local* ]]; then
            currentSearch=`echo $currentSearch | sed 's/svc.coredns.local//g' | sed 's/\s*//'`
            sudo networksetup -setsearchdomains "$line" "$currentSearch"
        fi
    done
}

function cleanupRoute {
    if netstat -nr | grep '10/24'; then
        sudo route -n delete 10.0.0.0/24
    fi
}

function runRootCommand {
    echo "Please enter your password if asked"
    cleanupDNS && cleanupRoute
}

function delete {
    removeMinikube && \
        cleanupVBox && \
        runRootCommand
}
