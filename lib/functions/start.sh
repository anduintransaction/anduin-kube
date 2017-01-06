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
             --kubernetes-version=$KUBERNETES_VERSION \
             --cpus=$MINIKUBE_CPU \
             --disk-size=$MINIKUBE_DISK_SIZE \
             --memory=$MINIKUBE_RAM \
             --iso-url=https://storage.googleapis.com/minikube/iso/minikube-v1.0.1.iso \
             --host-only-cidr="${MINIKUBE_CIDR}/24"
}

function installInitService {
    echo "Installing init services"
    copyFileToMinikube $HOME/.anduin-kube/lib/init-service-install /home/docker && \
        runCommandOnMinikube /home/docker/init-service-install/install.sh
}

function installCoreDNS {
    echo "Installing coreDNS"
    copyFileToMinikube $HOME/.anduin-kube/lib/coredns-install /home/docker && \
        copyFileToMinikube $HOME/.minikube/ca.crt /home/docker/coredns-install && \
        copyFileToMinikube $HOME/.minikube/apiserver.crt /home/docker/coredns-install && \
        copyFileToMinikube $HOME/.minikube/apiserver.key /home/docker/coredns-install && \
        rm -f coredns_003_linux_x86_64.tgz && \
        wget https://github.com/miekg/coredns/releases/download/v003/coredns_003_linux_x86_64.tgz && \
        tar xzf coredns_003_linux_x86_64.tgz && \
        copyFileToMinikube coredns /home/docker/coredns-install && \
        rm -f coredns coredns_003_linux_x86_64.tgz && \
        runCommandOnMinikube /home/docker/coredns-install/install.sh
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
            setupKubernetesNetworking && waitForKubernetes
            ;;
        stopped)
            deleteVBoxNetwork $MINIKUBE_CIDR && \
                createNetwork && \
                minikube start && \
                runInitService && \
                setupKubernetesNetworking && \
                waitForKubernetes
            ;;
        *)
            deleteVBoxNetwork $MINIKUBE_CIDR && \
                createNetwork && \
                startMinikube && \
                installInitService && \
                installCoreDNS && \
                runInitService && \
                setupKubernetesNetworking && \
                waitForKubernetes
            ;;
    esac    
}
