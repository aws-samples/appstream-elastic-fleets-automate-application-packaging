#!/bin/bash
# This script will install Chrome and package it on a VHD to be used on AppStream 2.0 Elastic fleets.
MountPath="/mnt/ChromeVHD/"
AppName="Chrome"
dd if=/dev/zero of=$AppName.img bs=1G count=1
sudo mkfs -t ext4 $AppName.img
sudo mkdir $MountPath
sudo mount -t auto -o loop $AppName.img $MountPath
wget https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm
sudo yum install -y google-chrome-stable_current_x86_64.rpm
sudo cp -R /opt/google/chrome $MountPath
sudo umount $MountPath
cat  > mount-script.sh << EOF
#!/bin/bash
sudo mkdir /opt/google
sudo mount -t auto -o loop /opt/appstream/AppBlocks/AppName/Application.img /opt/google
EOF
aws s3 cp mount-script.sh s3://my-virtual-hard-disks/chrome/mount-script.sh
aws s3 cp virtual-hard-disk.img s3://my-virtual-hard-disks/chrome/virtual-hard-disk.img
aws s3 cp /opt/google/chrome/product_logo_256.png s3://my-virtual-hard-disks/chrome/icon.png