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

function waitForKubernetes {
    echo "Waiting for kubernetes to come online"
    count=0
    until curl -sS -m 10 -f -o /dev/null --head http://kubernetes-dashboard.kube-system.svc.kube 2>/dev/null; do
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
            sudo anduin-kube setup-network && \
                waitForKubernetes
            ;;
        stopped)
            deleteVBoxNetwork $MINIKUBE_CIDR && \
                createNetwork && \
                VBoxManage modifyvm minikube --nic1 none && \
                VBoxManage modifyvm minikube --nic1 nat && \
                VBoxManage modifyvm minikube --natnet1 "192.168.171/24" && \
                VBoxManage modifyvm minikube --natdnshostresolver1 on && \
                minikube start --kubernetes-version=$KUBERNETES_MINIKUBE_VERSION && \
                sudo anduin-kube setup-network && \
                waitForKubernetes
            ;;
        *)
            deleteVBoxNetwork $MINIKUBE_CIDR && \
                createNetwork && \
                startMinikube && \
                sudo anduin-kube setup-network && \
                waitForKubernetes
            ;;
    esac    
}
