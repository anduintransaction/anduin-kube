#!/usr/bin/env bash

export MINIKUBE_VERSION=v1.2.0
export MINIKUBE_ISO_VERSION=v1.2.0
export MINIKUBE_CIDR=192.168.144.1
export MINIKUBE_DHCP_IP=192.168.144.6
export MINIKUBE_IP=192.168.144.100
export MINIKUBE_CPU=4
export MINIKUBE_RAM=${MINIKUBE_RAM:-6144}
export MINIKUBE_DISK_SIZE=50g
export KUBERNETES_VERSION=v1.15.0
export KUBERNETES_MINIKUBE_VERSION=v1.15.0
export DOCKER_VERSION=18.09.6
export IMLADRIS_VERSION=0.13.1
export COREDNS_VERSION=1.5.2
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
        sudo -E cp $fileToCopy /usr/local/bin
        sudo -E chmod 755 /usr/local/bin/`basename $fileToCopy`
        sudo -E chown $currentUser:$currentGroup /usr/local/bin/`basename $fileToCopy`
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
    case $(minikube status | grep 'host: ' | sed 's/host: //') in
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

function modifyDNSDarwin {
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

function addCustomDNSLinux {
    resolvConfHeadFile=/etc/resolvconf/resolv.conf.d/head
    archLinuxResolvConfFile=/etc/resolvconf.conf
    if [ -f $resolvConfHeadFile ]; then
        if ! grep -q 'nameserver 127.0.0.1' $resolvConfHeadFile; then
            echo 'nameserver 127.0.0.1' > $resolvConfHeadFile
        fi
        resolvconf -u
    elif [ -f $archLinuxResolvConfFile ]; then
        if ! grep -q 'prepend_nameservers 127.0.0.1' $archLinuxResolvConfFile; then
            echo 'prepend_nameservers=127.0.0.1' >> $archLinuxResolvConfFile
        fi
        if ! grep -q 'local_nameservers' $archLinuxResolvConfFile; then
            echo 'local_nameservers="0.0.0.0 255.255.255.255 ::1"' >> $archLinuxResolvConfFile
        fi
        resolvconf -u
    elif [ -f "/run/systemd/resolve/stub-resolv.conf" ]; then
        devices=`nmcli -c no -f UUID con | grep -v UUID`
        for device in `echo "$devices"`; do
            nmcli con mod $device ipv4.dns "127.0.0.1 8.8.8.8"
        done
        systemctl restart NetworkManager
    else
        echo "[main]" > /etc/NetworkManager/conf.d/anduin-kube.conf
        echo "dns=none" >> /etc/NetworkManager/conf.d/anduin-kube.conf
        rm -f /etc/resolv.conf
        systemctl restart NetworkManager
        echo "nameserver 127.0.0.1" > /etc/resolv.conf
        echo "nameserver 8.8.8.8" >> /etc/resolv.conf 
    fi
}

function killDnsmasq {
    killall dnsmasq > /dev/null 2>&1 || true
}

function modifyDNSLinux {
    sed -i 's/^dns=dnsmasq/#dns=dnsmasq/' /etc/NetworkManager/NetworkManager.conf &&
        addCustomDNSLinux &&
        systemctl restart NetworkManager &&
        killDnsmasq
}

function modifyDNS {
    case `uname` in
        Darwin)
            modifyDNSDarwin
            ;;
        Linux)
            modifyDNSLinux
            ;;
        *)
            echo "Not supported"
            return 1
            ;;
    esac
}

function modifyRouteDarwin {
    if ! netstat -nr | grep -q '10.96/12'; then
        route -n add 10.96.0.0/12 $MINIKUBE_IP
    fi
    if ! netstat -nr | grep -q '172.17/24'; then
        route -n add 172.17.0.0/24 $MINIKUBE_IP
    fi
}

function modifyRouteLinux {
    if ! ip route | grep -q '10.96.0.0/12'; then
        ip route add 10.96.0.0/12 via $MINIKUBE_IP
    fi
    if ! ip route | grep -q '172.17.0.0/24'; then
        ip route add 172.17.0.0/24 via $MINIKUBE_IP
    fi
}

function modifyRoute {
    case `uname` in
        Darwin)
            modifyRouteDarwin
            ;;
        Linux)
            modifyRouteLinux
            ;;
        *)
            echo "Not supported"
            return 1
            ;;
    esac
}

function cleanupDNSDarwin {
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

function cleanupCustomDNSLinux {
    resolvConfHeadFile=/etc/resolvconf/resolv.conf.d/head
    archLinuxResolvConfFile=/etc/resolvconf.conf
    if [ -f $resolvConfHeadFile ]; then
        sed -i '/nameserver 127.0.0.1/d' $resolvConfHeadFile
        resolvconf -u
    elif [ -f $archLinuxResolvConfFile ]; then
        sed -i '/prepend_nameservers=127.0.0.1/d' $archLinuxResolvConfFile
        sed -i '/local_nameservers/d' $archLinuxResolvConfFile
        resolvconf -u
    elif [ -f "/run/systemd/resolve/stub-resolv.conf" ]; then
         systemctl disable systemd-resolved
         systemctl stop systemd-resolved
         rm -f /etc/resolv.conf
         if ! grep -q 'dns=default' /etc/NetworkManager/NetworkManager.conf; then
             sed -i "s/\[main\]/[main]\ndns=default/" /etc/NetworkManager/NetworkManager.conf
         fi
         devices=`nmcli -c no -f UUID con | grep -v UUID`
         for device in `echo "$devices"`; do
             nmcli con mod $device ipv4.dns "8.8.8.8"
         done
         systemctl restart NetworkManager
    else
        rm -f /etc/NetworkManager/conf.d/anduin-kube.conf
        systemctl restart NetworkManager
    fi
}

function cleanupDNSLinux {
    cleanupCustomDNSLinux &&
        systemctl restart NetworkManager
}

function cleanupDNS {
    case `uname` in
        Darwin)
            cleanupDNSDarwin
            ;;
        Linux)
            cleanupDNSLinux
            ;;
        *)
            echo "Not supported"
            return 1
            ;;
    esac
}

function cleanupRouteDarwin {
    if netstat -nr | grep '10.96/12'; then
        route -n delete 10.96.0.0/12
    fi
    if netstat -nr | grep '172.17/24'; then
        route -n delete 172.17.0.0/24
    fi
}

function cleanupRouteLinux {
    if ip route | grep -q '10.96.0.0/12'; then
        ip route del 10.96.0.0/12
    fi
    if ip route | grep -q '172.17.0.0/24'; then
        ip route del 172.17.0.0/24
    fi
}

function cleanupRoute {
    case `uname` in
        Darwin)
            cleanupRouteDarwin
            ;;
        Linux)
            cleanupRouteLinux
            ;;
        *)
            echo "Not supported"
            return 1
            ;;
    esac
}

function installCoreDNS {
    # Waiting for network
    echo "Waiting for network"
    until curl -sS -o /dev/null --fail -m 5 https://github.com 2>/dev/null; do
        echo .
        sleep 3
    done
    needInstall=0
    if ! which coredns > /dev/null 2>&1; then
        needInstall=1
    else
        version=`coredns --version | head -1`
        if [ "$version" != "CoreDNS-$COREDNS_VERSION" ]; then
            needInstall=1
        fi
    fi
    if [ $needInstall -eq 1 ]; then
        echo "Installing coreDNS"
        case `uname` in
            Darwin)
                downloadLink=https://github.com/coredns/coredns/releases/download/v${COREDNS_VERSION}/coredns_${COREDNS_VERSION}_darwin_amd64.tgz
                ;;
            Linux)
                downloadLink=https://github.com/coredns/coredns/releases/download/v${COREDNS_VERSION}/coredns_${COREDNS_VERSION}_linux_amd64.tgz
                ;;
            *)
                echo "Not supported"
                return 1
                ;;
        esac
        wget -O coredns.tgz $downloadLink &&
            tar xzf coredns.tgz && \
            copyToUsrLocalBin coredns && \
            rm coredns.tgz coredns
    fi
    mkdir -p $HOME/.anduin-kube/zones
    cat $HOME/.anduin-kube/lib/coredns-config/coredns.core | sed 's!__HOME__!'$HOME'!g' > $HOME/.anduin-kube/coredns.core
    userAndGroup=`ls -la $HOME | awk '{if ($9 == ".") print $3"\t"$4}'`
    user=`echo "$userAndGroup" | cut -f 1`
    group=`echo "$userAndGroup" | cut -f 2`
    chown -R $user:$group $HOME/.anduin-kube/zones
    chown -R $user:$group $HOME/.anduin-kube/coredns.core
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

function startTimeSync {
    kubectl delete deployment ntp ntp-cron --namespace kube-system --context minikube --ignore-not-found=true &&
        kubectl create -f $HOME/.anduin-kube/lib/services/ntp/deployment.yml &&
        kubectl create -f $HOME/.anduin-kube/lib/services/ntp-cron/deployment.yml
}
