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
             --bootstrapper=kubeadm \
             --cpus=$MINIKUBE_CPU \
             --disk-size=$MINIKUBE_DISK_SIZE \
             --memory=$MINIKUBE_RAM \
             --host-only-cidr="${MINIKUBE_CIDR}/24" && \
        minikube stop && \
        VBoxManage modifyvm minikube --nic1 none && \
        VBoxManage modifyvm minikube --nic1 nat && \
        VBoxManage modifyvm minikube --natnet1 "192.168.171/24" && \
        VBoxManage modifyvm minikube --natdnshostresolver1 on && \
        minikube start --kubernetes-version=$KUBERNETES_MINIKUBE_VERSION --bootstrapper=kubeadm && \
        minikube addons enable dashboard
}

function waitForKubernetes {
    echo "Waiting for kubernetes to come online"
    count=0
    until curl -sS -m 10 -f -o /dev/null --head http://kubernetes-dashboard.kube-system.svc.kube 2>/dev/null; do
        printf .
        count=`expr $count + 1`
        sudo -E anduin-kube clear-cache
        sleep 10
        if [ $count -gt 24 ]; then
            echo
            echo "Something wrong: cannot connect to kubernetes dashboard"
            break
        fi
    done
    echo
    case `uname` in
        Darwin)
            sudo killall -USR1 mDNSResponder
            sudo killall -USR2 mDNSResponder
            ;;
    esac
    echo "Done"
}

function start {
    # Ask for admin password right away
    sudo -E ls / > /dev/null 2>&1

    stt=`minikubeStatus`
    case $stt in
        started)
            anduin-kube fix &&
                waitForKubernetes &&
                startTimeSync
            ;;
        stopped)
            deleteVBoxNetwork $MINIKUBE_CIDR &&
                createNetwork &&
                VBoxManage modifyvm minikube --nic1 none &&
                VBoxManage modifyvm minikube --nic1 nat &&
                VBoxManage modifyvm minikube --natnet1 "192.168.171/24" &&
                VBoxManage modifyvm minikube --natdnshostresolver1 on &&
                minikube start --kubernetes-version=$KUBERNETES_MINIKUBE_VERSION --bootstrapper=kubeadm &&
                anduin-kube fix &&
                waitForKubernetes &&
                startTimeSync
            ;;
        *)
            deleteVBoxNetwork $MINIKUBE_CIDR &&
                createNetwork &&
                startMinikube &&
                anduin-kube fix &&
                waitForKubernetes &&
                startTimeSync
            ;;
    esac
}
