#!/usr/bin/env bash

sudo apt update && sudo apt dist-upgrade -y && sudo apt install acl git-core screen rsync exfat-fuse exfat-utils ntfs-3g minidlna gphoto2 libimage-exiftool-perl eject -y

sudo mkdir /media/cards
sudo mkdir /media/cards/card1
sudo mkdir /media/cards/card2
sudo mkdir /media/cards/card3
sudo mkdir /media/cards/card4
sudo mkdir /media/cards/card5
sudo mkdir /media/cards/card6

sudo mkdir /media/storage
sudo chown -R pi:pi /media/storage
sudo chmod -R 775 /media/storage
sudo setfacl -Rdm g:pi:rw /media/storage

cd
git clone https://github.com/jordivanduijn/easy-multiple-sd-backup.git
sudo chmod 775 /home/pi/easy-multiple-sd-backup/emsb.sh

sudo crontab -l | { cat; echo "@reboot sudo /home/pi/easy-multiple-sd-backup/emsb.sh > /home/pi/easy-multiple-sd-backup/output.log"; } | sudo crontab

sudo sed -i 's|'media_dir=/var/lib/minidlna'|'media_dir=/media/storage'|' /etc/minidlna.conf
sudo service minidlna start

echo "*************************************"
echo "Installation finished! Please reboot."
echo "*************************************"
