#!/bin/bash

arch=$(uname -m)
if [ "$arch" == "x86_64" ]; then
    FILE=node_exporter-1.8.2.linux-amd64.tar.gz
    DIR=node_exporter-1.8.2.linux-amd64
elif [ "$arch" == "aarch64" ]; then
    FILE=node_exporter-1.8.2.linux-arm64.tar.gz
    DIR=node_exporter-1.8.2.linux-arm64
fi

wget -q https://github.com/prometheus/node_exporter/releases/download/v1.8.2/$FILE
tar xfz $FILE
sudo cp $DIR/node_exporter /usr/local/bin/node_exporter && echo "node_exporter copied to /usr/local/bin/"

#Edit crontab
if ! grep -q "node_exporter" /etc/crontab; then
    sudo sh -c "sudo echo -e \"@reboot root /usr/local/bin/node_exporter &\" >> /etc/crontab"
    echo "node_exporter added to crontab"
else
    echo "node_exporter already added to crontab"
fi

rm -rf $DIR
rm $FILE

echo "node_exporter setup complete"
exit 0
