#!/usr/bin/env bash

export MINIKUBE_VERSION=v0.22.1
export MINIKUBE_ISO_VERSION=v0.23.3
export MINIKUBE_CIDR=192.168.144.1
export MINIKUBE_DHCP_IP=192.168.144.6
export MINIKUBE_IP=192.168.144.100
export MINIKUBE_CPU=4
export MINIKUBE_RAM=4096
export MINIKUBE_DISK_SIZE=50g
export KUBERNETES_VERSION=v1.7.5
export KUBERNETES_MINIKUBE_VERSION=v1.7.5
export DOCKER_VERSION=1.12.6
export IMLADRIS_VERSION=0.12.0
export COREDNS_VERSION=010
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

function echoLog {
    now=`date '+%Y-%m-%d %H:%M:%S'`
    echo -e "$now\t$1"
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
        if [[ $currentNS != *127.0.0.1* ]]; then
            currentNS="127.0.0.1 $currentNS"
            networksetup -setdnsservers "$line" $currentNS
        fi
    done
    launchctl unload /System/Library/LaunchDaemons/com.apple.mDNSResponder.plist
    defaults write /Library/Preferences/com.apple.mDNSResponder.plist StrictUnicastOrdering -bool YES
    launchctl load /System/Library/LaunchDaemons/com.apple.mDNSResponder.plist
}

function modifyRoute {
    if netstat -nr | grep '10/24'; then
        return
    fi
    route -n add 10.0.0.0/24 $MINIKUBE_IP
}

function cleanupDNS {
    networksetup -listallnetworkservices | grep -v '\*' | while read line; do
        currentNS=`networksetup -getdnsservers "$line"`
        if [[ $currentNS != There* ]] && [[ $currentNS == *$MINIKUBE_IP* ]] || [[ $currentNS == *127.0.0.1* ]]; then
            currentNS=`echo $currentNS | sed 's/'$MINIKUBE_IP'//g' | sed 's/\s*//'`
            currentNS=`echo $currentNS | sed 's/127.0.0.1//g' | sed 's/\s*//'`
            networksetup -setdnsservers "$line" $currentNS
        fi
        currentSearch=`networksetup -getsearchdomains "$line"`
        if [[ $currentSearch != There* ]] && [[ $currentSearch == *svc.coredns.local* ]]; then
            currentSearch=`echo $currentSearch | sed 's/svc.coredns.local//g' | sed 's/\s*//'`
            currentSearch=`echo $currentSearch | sed 's/svc.corednsw.local//g' | sed 's/\s*//'`
            networksetup -setsearchdomains "$line" "$currentSearch"
        fi
    done
    anduin-kube clear-cache
}

function cleanupRoute {
    if netstat -nr | grep '10/24'; then
        route -n delete 10.0.0.0/24
    fi
}

function installCoreDNS {
    needInstall=0
    if ! which coredns > /dev/null 2>&1; then
        needInstall=1
    else
        version=`coredns --version`
        if [ "$version" != "CoreDNS-$COREDNS_VERSION" ]; then
            needInstall=1
        fi
    fi
    if [ $needInstall -eq 1 ]; then
        echo "Installing coreDNS"
        wget -O coredns_${COREDNS_VERSION}_darwin_x86_64.tgz https://github.com/coredns/coredns/releases/download/v${COREDNS_VERSION}/coredns_${COREDNS_VERSION}_darwin_x86_64.tgz && \
            tar xzf coredns_${COREDNS_VERSION}_darwin_x86_64.tgz && \
            copyToUsrLocalBin coredns && \
            rm coredns_${COREDNS_VERSION}_darwin_x86_64.tgz coredns
    fi
    cat $HOME/.anduin-kube/lib/coredns-config/coredns.core | sed 's!__HOME__!'$HOME'!g' > $HOME/.anduin-kube/coredns.core
}

function startCoreDNS {
    installCoreDNS && stopCoreDNS
    if [ $? -ne 0 ]; then
        echo "Cannot start coredns"
        exit 0
    fi
    echo "Starting coredns"
    nohup coredns -conf $HOME/.anduin-kube/coredns.core > /var/log/coredns.log 2>&1 &
    pid=$!
    count=0
    while ! kill -0 $pid > /dev/null 2>&1; do
        echo .
        sleep 3
        if [ $count -gt 10 ]; then
            echo "Cannot start coredns"
            return 1
        fi
        count=`expr $count + 1`
    done
}

function stopCoreDNS {
    echo "Stop coredns"
    pids=`ps -ef | grep coredns | grep -v grep | awk '{print $2}'`
    if [ -z "$pids" ]; then
        return
    fi
    for pid in $pids; do
        kill -9 $pid > /dev/null 2>&1
    done
}

function startHealthz {
    stopHealthz
    echo "Starting health check"
    nohup anduin-kube healthz > /var/log/anduin-kube-healthz.log 2>&1 &
    pid=$!
    count=0
    while ! kill -0 $pid > /dev/null 2>&1; do
        echo .
        sleep 3
        if [ $count -gt 10 ]; then
            echo "Cannot start health check"
            return 1
        fi
        count=`expr $count + 1`
    done
}

function stopHealthz {
    echo "Stopping health check"
    pids=`ps -ef | grep "anduin-kube healthz" | grep -v grep | awk '{print $2}'`
    if [ -z "$pids" ]; then
        return
    fi
    for pid in $pids; do
        kill -9 $pid > /dev/null 2>&1
    done
}
