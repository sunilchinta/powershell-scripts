#!/bin/bash
mkdir /vmt
mount /dev/cdrom /mnt
cd /mnt
cp VMwareTools-*.tar.gz /vmt
cd /vmt
chmod 777 -R /VMwareTools-*.tar.gz
tar -xzvf VMwareTools-*.tar.gz
cd vmware-tools-distrib/
./vmware-install.pl -d
if [ $? -eq 0 ]
then
  echo "The script ran ok"
  rm -rf /vmt
  umount /dev/cdrom
  exit 0
else
  echo "The script failed" >&2
  exit 1
fi