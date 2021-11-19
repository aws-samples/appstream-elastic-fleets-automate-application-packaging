## Automate Elastic Fleet Application Updates with Systems Manager

This repository was created to accelerate [AppStream 2.0 Elastic Fleet](https://aws.amazon.com/about-aws/whats-new/2021/11/amazon-appstream-2-0-launches-elastic-fleets-serverless-fleet-type/) migrations by automating the application packaging process. The provided script in this repository goes in tandem with this [blog post](https://aws.amazon.com/blogs/desktop-and-application-streaming/automate-appstream-2-0-elastic-fleet-application-updates-with-aws-systems-manager/). The script can be ran locally or remotely via a [Systems Manager Run Command](https://docs.aws.amazon.com/systems-manager/latest/userguide/execute-remote-commands.html) against a SSM-Managed Linux EC2 instance. As provided, the script will create a virtual hard disk (VHD),

### Script Steps
**Parameters**
MountPath="/mnt/ChromeVHD/"
AppName="Chrome"

**VHD Creation**
dd if=/dev/zero of=$AppName.img bs=1G count=1
sudo mkfs -t ext4 $AppName.img

**Mount VHD**
sudo mkdir $MountPath
sudo mount -t auto -o loop $AppName.img $MountPath

**Install Chrome**
wget https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm
sudo yum install -y google-chrome-stable_current_x86_64.rpm

**Move Application to VHD**
sudo cp -R /opt/google/chrome $MountPath

**Unmount VHD**
sudo umount $MountPath

**Create Mount Script**
cat  > mount-script.sh << EOF
#!/bin/bash
sudo mkdir /opt/google
sudo mount -t auto -o loop /opt/appstream/AppBlocks/AppName/Application.img /opt/google
EOF

**Upload VHD to S3**
aws s3 cp mount-script.sh s3://my-virtual-hard-disks/chrome/mount-script.sh
aws s3 cp virtual-hard-disk.img s3://my-virtual-hard-disks/chrome/virtual-hard-disk.img
aws s3 cp /opt/google/chrome/product_logo_256.png s3://my-virtual-hard-disks/chrome/icon.png


## Security

See [CONTRIBUTING](CONTRIBUTING.md#security-issue-notifications) for more information.

## License

This library is licensed under the MIT-0 License. See the LICENSE file.

