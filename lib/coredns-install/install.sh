#!/bin/sh

coreDNSRoot=/var/lib/boot2docker/opt/coredns

installCoreDNS() {
    if [ -f "$coreDNSRoot/coredns" ]; then
        return
    fi
    echo "Installing coreDNS"
    sudo mkdir -p $coreDNSRoot && \
        rm -f coredns_003_linux_x86_64.tgz && \
        wget https://github.com/miekg/coredns/releases/download/v003/coredns_003_linux_x86_64.tgz && \
        tar xzf coredns_003_linux_x86_64.tgz && \
        sudo mv coredns $coreDNSRoot/coredns && \
        sudo chmod 755 $coreDNSRoot/coredns && \
        sudo chown root:root $coreDNSRoot/coredns && \
        rm -f coredns_003_linux_x86_64.tgz
}

installCoreDNSConfig() {
    sudo cp /home/docker/coredns-install/coredns.core $coreDNSRoot/
    sudo cp /home/docker/coredns-install/ca.crt $coreDNSRoot/
    sudo cp /home/docker/coredns-install/apiserver.crt $coreDNSRoot/
    sudo cp /home/docker/coredns-install/apiserver.key $coreDNSRoot/
}

installCoreDNSService() {
    sudo cp /home/docker/coredns-install/coredns-boot.sh /var/lib/boot2docker/init.d/
}

installCoreDNS && installCoreDNSConfig && installCoreDNSService
