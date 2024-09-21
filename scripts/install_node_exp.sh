#!/bin/bash
FILE=node_exporter-1.8.2.linux-amd64.tar.gz
DIR=node_exporter-1.8.2.linux-amd64
wget -q https://github.com/prometheus/node_exporter/releases/download/v1.8.2/$FILE
tar xfz $FILE
sudo cp $DIR/node_exporter /usr/local/bin/node_exporter && echo "node_exporter copied to /usr/local/bin/"

#Edit crontab
if ! grep -q "node_exporter" /etc/crontab; then
    sudo sh -c "sudo echo -e \"@reboot root /usr/local/bin/node_exporter &\n\" >> /etc/crontab"
    node_exporter added to crontab
else
    echo "node_exporter already added to crontab"
fi

rm -rf $DIR
rm $FILE

echo "node_exporter setup complete"
exit 0
