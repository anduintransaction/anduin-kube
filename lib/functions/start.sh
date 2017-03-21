#!/usr/bin/env bash

function createNetwork {
    echo "Creating network"
    output=`VBoxManage hostonlyif create`
    if [ $? -ne 0 ]; then
        exit 1
    fi
    networkName=`echo "$output" | grep -o "'.*'" | sed "s/'//g"`
    VBoxManage hostonlyif ipconfig --ip $MINIKUBE_CIDR $networkName
}

function startMinikube {
    minikube start \
             --kubernetes-version=$KUBERNETES_MINIKUBE_VERSION \
             --cpus=$MINIKUBE_CPU \
             --disk-size=$MINIKUBE_DISK_SIZE \
             --memory=$MINIKUBE_RAM \
             --host-only-cidr="${MINIKUBE_CIDR}/24"
}

function installInitService {
    echo "Installing init services"
    copyFileToMinikube $HOME/.anduin-kube/lib/init-service-install /home/docker && \
        runCommandOnMinikube /home/docker/init-service-install/install.sh
}

function installCoreDNS {
    if ! which coredns > /dev/null 2>& 1; then
        echo "Installing coreDNS"
        wget -O coredns_${COREDNS_VERSION}_darwin_x86_64.tgz https://github.com/coredns/coredns/releases/download/v${COREDNS_VERSION}/coredns_${COREDNS_VERSION}_darwin_x86_64.tgz && \
            tar xzf coredns_${COREDNS_VERSION}_darwin_x86_64.tgz && \
            copyToUsrLocalBin coredns && \
            rm coredns_${COREDNS_VERSION}_darwin_x86_64.tgz coredns
    fi
    cat $HOME/.anduin-kube/lib/coredns-install/coredns.core | sed 's!__HOME__!'$HOME'!g' > $HOME/.anduin-kube/coredns.core
}

function startCoreDNS {
    pidFile=/var/run/coredns.pid
    if [ -f $pidFile ]; then
        pid=`cat $pidFile`
        sudo kill -9 $pid > /dev/null 2>&1
        sudo rm -f $pidFile
    fi
    sudo bash -c "nohup coredns -pidfile $pidFile -conf $HOME/.anduin-kube/coredns.core > /var/log/coredns.log 2>&1" &
    count=0
    while [ ! -f $pidFile ]; do
        echo .
        sleep 1
        if [ $count -gt 10 ]; then
            echo "Cannot start coredns"
            return 1
        fi
        count=`expr $count + 1`
    done
    pid=`cat $pidFile`
    count=0
    while ! sudo kill -0 $pid > /dev/null 2>&1; do
        echo .
        sleep 3
        if [ $count -gt 10 ]; then
            echo "Cannot start coredns"
            return 1
        fi
        count=`expr $count + 1`
    done
}

function runCoreDNS {
    echo "Starting CoreDNS"
    installCoreDNS && startCoreDNS
}

function runInitService {
    echo "Running init services"
    runCommandOnMinikube sudo /mnt/sda1/var/lib/init/init.sh
}

function waitForKubernetes {
    echo "Waiting for kubernetes to come online"
    count=0
    until curl -sS -m 10 -f -o /dev/null --head http://kubernetes-dashboard.kube-system 2>/dev/null; do
        printf .
        count=`expr $count + 1`
        sleep 10
        if [ $count -gt 24 ]; then
            echo
            echo "Something wrong: cannot connect to kubernetes dashboard"
            break
        fi
    done
    echo
    echo "Done"
}

function start {
    stt=`minikubeStatus`
    case $stt in
        started)
            runCoreDNS && \
                setupKubernetesNetworking && \
                waitForKubernetes
            ;;
        stopped)
            deleteVBoxNetwork $MINIKUBE_CIDR && \
                createNetwork && \
                minikube start --kubernetes-version=$KUBERNETES_MINIKUBE_VERSION && \
                runCoreDNS && \
                setupKubernetesNetworking && \
                waitForKubernetes
            ;;
        *)
            deleteVBoxNetwork $MINIKUBE_CIDR && \
                createNetwork && \
                startMinikube && \
                runCoreDNS && \
                setupKubernetesNetworking && \
                waitForKubernetes
            ;;
    esac    
}
