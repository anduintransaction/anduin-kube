#!/usr/bin/env bash

export MINIKUBE_VERSION=v0.14.0
export MINIKUBE_CIDR=192.168.100.1
export MINIKUBE_DHCP_IP=192.168.100.6
export MINIKUBE_IP=192.168.100.100
export MINIKUBE_CPU=4
export MINIKUBE_RAM=4096
export MINIKUBE_DISK_SIZE=50g
export KUBERNETES_VERSION=v1.5.1
export DOCKER_VERSION=1.12.4
export IMLADRIS_VERSION=0.5.7
export EXTRA_NAT_NETWORK_NAME=minikube
export EXTRA_NAT_NETWORK_NET=10.0.72.0/24

function getCurrentUser {
    whoami
}

function getCurrentUserGroup {
    groups $(getCurrentUser) | awk '{print $1}'
}

function copyToUsrLocalBin {
    fileToCopy=$1
    filename="thequickbrownfox1234"
    touch /usr/local/bin/$filename > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        currentUser=`getCurrentUser`
        currentGroup=`getCurrentUserGroup`
        sudo cp $fileToCopy /usr/local/bin
        sudo chmod 755 /usr/local/bin/$fileToCopy
        sudo chown $currentUser:$currentGroup /usr/local/bin/$fileToCopy
    else
        cp $fileToCopy /usr/local/bin
        rm /usr/local/bin/$filename
    fi
}

function minikubeStatus {
    case $(minikube status | grep minikubeVM | sed 's/minikubeVM: //') in
        Running)
            echo "started"
            ;;
        Stopped)
            echo "stopped"
            ;;
        *)
            echo "NA"
            ;;
    esac
}

function deleteVBoxNetwork {
    networkName=""
    VBoxManage list hostonlyifs | while IFS='' read -r line || [[ -n "$line" ]]; do
        if [[ $line == Name:* ]]; then
            networkName=`echo "$line" | awk '{print $2}'`
        fi
        if [[ $line == IPAddress:* ]]; then
            networkCIDR=`echo "$line" | awk '{print $2}'`
            if [ "$networkCIDR" == "$1" ]; then
                echo "Deleting network $networkName"
                VBoxManage hostonlyif remove $networkName
                dhcpName=`VBoxManage list dhcpservers | grep $networkName | awk '{print $2}'`
                if [ ! -z "$dhcpName" ]; then
                    echo "Deleting DHCP server $dhcpName"
                    VBoxManage dhcpserver remove --netname $dhcpName
                fi
            fi
        fi
    done
}

function copyFileToMinikube {
    scp -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ~/.minikube/machines/minikube/id_rsa -r $1 docker@$MINIKUBE_IP:$2
}

function runCommandOnMinikube {
    ssh -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ~/.minikube/machines/minikube/id_rsa docker@$MINIKUBE_IP $@
}

function modifyDNS {
    networksetup -listallnetworkservices | grep -v '\*' | while read line; do
        currentNS=`networksetup -getdnsservers "$line"`
        if [[ $currentNS == There* ]]; then
            currentNS=8.8.8.8
        fi
        if [[ $currentNS != *$MINIKUBE_IP* ]]; then
            currentNS="$MINIKUBE_IP $currentNS"
            sudo networksetup -setdnsservers "$line" $currentNS
        fi

        currentSearch=`networksetup -getsearchdomains "$line"`
        if [[ $currentSearch == There* ]]; then
            currentSearch=
        fi
        if [[ $currentSearch != *svc.coredns.local* ]]; then
            currentSearch="$currentSearch svc.coredns.local"
            sudo networksetup -setsearchdomains "$line" $currentSearch
        fi
    done
    sudo launchctl unload /System/Library/LaunchDaemons/com.apple.mDNSResponder.plist
    sudo defaults write /Library/Preferences/com.apple.mDNSResponder.plist AlwaysAppendSearchDomains -bool YES
    sudo launchctl load /System/Library/LaunchDaemons/com.apple.mDNSResponder.plist
}

function modifyRoute {
    if netstat -nr | grep '10/24'; then
        return
    fi
    sudo route -n add 10.0.0.0/24 $MINIKUBE_IP
}

function setupKubernetesNetworking {
    modifyDNS && modifyRoute
}
