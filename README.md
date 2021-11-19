## Automate Elastic Fleet Application Updates with Systems Manager

This repository was created to accelerate [AppStream 2.0 Elastic Fleet](https://aws.amazon.com/about-aws/whats-new/2021/11/amazon-appstream-2-0-launches-elastic-fleets-serverless-fleet-type/) migrations by automating the application packaging process. The provided script in this repository goes in tandem with this [blog post](https://aws.amazon.com/blogs/desktop-and-application-streaming/automate-appstream-2-0-elastic-fleet-application-updates-with-aws-systems-manager/). The script can be ran locally or remotely via a [Systems Manager Run Command](https://docs.aws.amazon.com/systems-manager/latest/userguide/execute-remote-commands.html) against a SSM-Managed Windows EC2 instance. As provided, the script will create a virtual hard disk (VHD) meeting the specified size you pass as a parameter. It will then mount it to the machine, install Google Chrome on the VHD, detach the VHD, and then upload to a S3 bucket (if provided). For more details around the available parameters. 

### Script Steps

**Parameters**
- **installSize**
    This is the size the VHDX should be. The size should always be larger than the install of your application. 
- **vhdName**
    This is what you would like to name your VHDX file. This name will be used as identifier. 
- **vhdLocation**
    The local path that the VHDX file will be saved. This is not a mandatory parameter. If not provided, a folder will be created under $env:TEMP
    that matches vhdName. If the folder path matching vhdName already exists, it will create a new random folder (vhdName + random int).
- **vhdMountLetter**
    The drive letter you would like to mount the VHDX to. This is not a mandatory parameter. If not provided, the script will automatically 
    find an open drive letter assuming no mount path has been provided. If both a mount letter and mount path are not provided, the mount letter will be prioritized and a random open drive letter will be found.
- **vhdMountPath**
    Specifies the mount path you would like to mount the VHDX to. This is not a mandatory parameter. If both a mount letter and mount path are provided, the mount letter will be prioritized.
- **vhdS3Bucket**
    Specifies the S3 location where you would like to store the VHDX file. Note, if you do not have versioning enabled on the bucket, each file named the same will
    be overwritten.
- **force**
    Boolean parameter that allows your vhdMountPath to be created. If the path is not already created, the script will exit with no verified destination. If you 
    set -force $true, the supplied path will be created.

**Steps**
1. Validation - Test provided VHDLocation and if none is provided, create a folder under $env:TEMP.
2. Validation - Test the folder paths and if there is not a folder, the script will create one. If a folder is present, it will clear out txt/VHDX files that reside there from previous invocations. 
3. Validation - Test the provided drive letter and if in use, exit with error code. 
4. Validation - Test VHDMountPath, if it was provided. If the folder is not empty or it doesn't exist, the script will exit. However, if -force $true is provided as a parameter, the mount path will be created if not found.
5. Validation - If no drive letter or mount path is provided, the script will find an open drive letter.
6. Build Configuration - This stage will build out the commands that will create and mount your VHDX file. The disk will be expandable up to the size you provided as a parameter and will be formatted as NTFS. 
7. Execute Configuration - Once the configuration is built out, it will be passed into DISKPART to be executed. 
8. Application Install - After DISKPART is finished, your VHD will be mounted. From here you can run logic to install your application. As provided, the script will install the latest version of Google Chrome. If you intend to use the script to install Google Chrome, ensure you follow the blog linked above. 
9. Detach VHD - After your installation is complete, the script will detach the VHD.
10. Upload to S3 - If you provided an accessible S3 bucket, the script will upload the VHD file to the specified bucket. 

## Security

See [CONTRIBUTING](CONTRIBUTING.md#security-issue-notifications) for more information.

## License

This library is licensed under the MIT-0 License. See the LICENSE file.

