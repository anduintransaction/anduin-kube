#!/usr/bin/env bash

function checkDeps {
    if ! which VBoxManage > /dev/null 2>&1; then
        echo "VirtualBox not found. Please install VirtualBox: https://www.virtualbox.org/wiki/Downloads"
        return 1
    fi
    case `uname` in
        Linux)
            if ! which nmcli > /dev/null 2>&1; then
                echo "NMCLI not found, please install network manager"
                return 1
            fi
    esac
}

function installMinikube {
    if which minikube > /dev/null 2>&1; then
        version=`minikube version`
        if [ "$version" == "minikube version: $MINIKUBE_VERSION" ]; then
            return
        fi
    fi
    echo "Installing minikube $MINIKUBE_VERSION"
    case `uname` in
        Darwin)
            downloadLink=https://storage.googleapis.com/minikube/releases/$MINIKUBE_VERSION/minikube-darwin-amd64
            ;;
        Linux)
            downloadLink=https://storage.googleapis.com/minikube/releases/$MINIKUBE_VERSION/minikube-linux-amd64
            ;;
        *)
            echo "Not supported"
            return 1
            ;;
    esac
    wget -O minikube $downloadLink && \
        chmod +x minikube && \
        copyToUsrLocalBin minikube && \
        rm minikube
}

function installKubectl {
    if which kubectl > /dev/null 2>&1; then
        version=`kubectl version --client | grep -o 'GitVersion:"[^"]*"' | sed 's/GitVersion://' | sed 's/"//g'`
        if [ "$version" == "$KUBERNETES_VERSION" ]; then
            return
        fi
    fi
    echo "Installing kubectl $KUBERNETES_VERSION"
    case `uname` in
        Darwin)
            downloadLink=https://storage.googleapis.com/kubernetes-release/release/$KUBERNETES_VERSION/bin/darwin/amd64/kubectl
            ;;
        Linux)
            downloadLink=https://storage.googleapis.com/kubernetes-release/release/$KUBERNETES_VERSION/bin/linux/amd64/kubectl
            ;;
        *)
            echo "Not supported"
            return 1
            ;;
    esac
    wget -O kubectl $downloadLink && \
        chmod 755 kubectl && \
        copyToUsrLocalBin kubectl && \
        rm kubectl
}

function installIfNeeded {
    checkDeps && \
        installMinikube && \
        installKubectl
}
