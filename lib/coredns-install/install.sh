#!/bin/sh

coreDNSRoot=/mnt/sda1/var/lib/coredns

installCoreDNS() {
    if [ -f "$coreDNSRoot/coredns" ]; then
        return
    fi
    sudo mkdir -p $coreDNSRoot && \
        sudo mv /home/docker/coredns-install/coredns $coreDNSRoot/coredns && \
        sudo chmod 755 $coreDNSRoot/coredns && \
        sudo chown root:root $coreDNSRoot/coredns
}

installCoreDNSConfig() {
    sudo cp /home/docker/coredns-install/coredns.core $coreDNSRoot/
    sudo cp /home/docker/coredns-install/ca.crt $coreDNSRoot/
    sudo cp /home/docker/coredns-install/apiserver.crt $coreDNSRoot/
    sudo cp /home/docker/coredns-install/apiserver.key $coreDNSRoot/
}

installCoreDNSService() {
    sudo cp /home/docker/coredns-install/coredns.sh /mnt/sda1/var/init.d/
}

installCoreDNS && installCoreDNSConfig && installCoreDNSService
