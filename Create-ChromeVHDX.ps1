<#
MIT No Attribution

Copyright 2021 Amazon Web Services

Permission is hereby granted, free of charge, to any person obtaining a copy of this
software and associated documentation files (the "Software"), to deal in the Software
without restriction, including without limitation the rights to use, copy, modify,
merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

.SYNOPSIS
    This cmdlet will create a Virtual Hard Disk (VHDX file) and mount it to an open drive letter, folder path, or both. 
.DESCRIPTION
    This script will mount a VHDX to the machine it is ran on. The VHDX can then have an application installed on it.
    Once an application is installed, you can detach the VHDX and mount to other machines to mobilize your application.
    VHD Documentation: https://docs.microsoft.com/en-us/previous-versions/windows/it-pro/windows-server-2012-r2-and-2012/gg252579(v=ws.11)
.PARAMETER installSize
    This is the size the VHDX should be. The size should always be larger than the install of your application. 
.PARAMETER vhdName
    This is what you would like to name your VHDX file. This name will be used as identifier. 
.PARAMETER vhdLocation
    The local path that the VHDX file will be saved. This is not a mandatory parameter. If not provided, a folder will be created under C:\
    that matches vhdName. If the folder path matching vhdName already exists, it will create a new random folder.
.PARAMETER vhdMountLetter
    The drive letter you would like to mount the VHDX to. This is not a mandatory parameter. If not provided, the script will automatically 
    find an open drive letter assuming no mount path has been provided. If both a mount letter and mount path are not provided, the mount letter will be prioritized and a random open drive letter will be found.
.PARAMETER vhdMountPath
    Specifies the mount path you would like to mount the VHDX to. This is not a mandatory parameter. If both a mount letter and mount path are provided, the mount letter will be prioritized.
.PARAMETER vhdS3Bucket
    Specifies the S3 location where you would like to store the VHDX file. Note, if you do not have versioning enabled on the bucket, each file named the same will
    be overwritten.
.PARAMETER force
    Boolean parameter that allows your vhdMountPath to be created. If the path is not already created, the script will exit with no verified destination. If you 
    set -force $true, the supplied path will be created.
.EXAMPLE
    .\Create-VHDX.ps1 -installSize 400 -vhdName MyApp
    .\Create-VHDX.ps1 -installSize 400 -vhdName MyApp -vhdLocation C:\MyPath
    .\Create-VHDX.ps1 -installSize 400 -vhdName MyApp -vhdLocation C:\MyPath\ -vhdMountLetter D
    .\Create-VHDX.ps1 -installSize 400 -vhdName MyApp -vhdLocation C:\MyPath\ -vhdMountPath C:\My\Mount\Path\
    .\Create-VHDX.ps1 -installSize 400 -vhdName MyApp -vhdLocation C:\MyPath\ -vhdMountPath C:\My\Mount\Path\ -vhdMountLetter D
    .\Create-VHDX.ps1 -installSize 400 -vhdName MyApp -vhdLocation C:\MyPath\ -vhdMountPath C:\My\Mount\Path\ -vhdMountLetter D -force $true
#>

[CmdletBinding()]
Param (
    # The size of your VHDX. THis should be larger than the install of your application.
    [Parameter(Mandatory=$true)]
    [string]$installSize,

    # What you would like to name your VHDX
    [Parameter(Mandatory=$true)]
    [string]$vhdName,

    # Local path where you want the VHDX to be stored. Ex> D:\MyVHD
    [Parameter(Mandatory=$false)]
    [string]$vhdLocation,

    # Letter to mount your VHDX
    [Parameter(Mandatory=$false)]
    [string]$vhdMountLetter,

    # Specifies what specific folder to mount your VHDX
    [Parameter(Mandatory=$false)]
    [string]$vhdMountPath,

    # Specifies what specific folder to mount your VHDX
    [Parameter(Mandatory=$false)]
    [string]$vhdS3Bucket,

    # Specifies what specific folder to mount your VHDX
    [Parameter(Mandatory=$false)]
    [Boolean]$force
)
$ErrorActionPreference = 'continue'
$LocalTempDir = $env:TEMP

# Validate vhdLocation parameter
if($vhdLocation){
  if(Test-Path $vhdLocation){
    if($vhdLocation[$vhdLocation.Length - 1] -eq '\'){
      $localPath = $vhdLocation+$vhdName
      $folderPath = $vhdLocation.TrimEnd('\')
    }else{
      $localPath = $vhdLocation+"\"+$vhdName
      $folderPath = $vhdLocation
    }
  }else{
    Write-Host "Please verify your destination path and try again. Exiting.."
    exit
  }
}else{
  $folderPath = "$localTempDir\$vhdName"
  $pathVal -eq $false
  do{
    if(Test-Path $folderPath){
      $int = Get-Random -Maximum 100
      $folderPath = "$localTempDir\$vhdName$int"
      $localPath = "$localTempDir\$vhdName$int\$vhdName"
      if(Test-Path $folderPath){
        break
      }else{
        $pathVal = $true
      }
    }else{
      $localPath = "$folderPath\$vhdName"
      $pathVal -eq $true
    }
  }while($pathVal -eq $false)
}
if(-not(Test-Path $folderPath)){
  mkdir $folderPath | Out-Null
}else{
  if(Test-Path "$localPath.txt"){
    rm "$localPath.txt" -Force
  }elseif(Test-Path "$localPath.vhdx"){
    rm "$localPath.vhdx" -Force
  }
}

# Validate vhdMountLetter/vhdMountPath parameter
if($vhdMountLetter){
  if($vhdMountLetter.Length -gt 1){
    $vhdMountLetter = $vhdMountLetter[0]
  }
  if(Test-Path $vhdMountLetter":"){
    Write-Host "The Drive letter that you have specified ($vhdMountLetter) is currently in use. Please select a new open letter. Exiting.."
    exit
  }
}elseif($vhdMountPath){
  if(-not(Test-Path $vhdMountPath)){
    if($force -eq $true){
      Write-Host "The provided mount path ($vhdMountPath) is being created."
      mkdir $vhdMountPath
    }else{
      Write-Host "The provided mount path ($vhdMountPath) could not be found. Please verify the provided path or set pass in -force `$true. Exiting.."
      exit
    }
  }elseif($null -ne (Get-ChildItem $vhdMountPath)){
    Write-Host "The provided mount path ($vhdMountPath) is not empty. Please empty the directory or provided a new path. Exiting.."
    exit
  }
}else{
  $vhdMountLetter = $null
  $i = 0
  while(($null -eq $vhdMountLetter) -or ($i -le 25)){
    $testLetter = (65..90) | Get-Random -Count 1 | % {[char]$_}
    $i++
    if(($testLetter -ne 'A') -or ($testLetter -ne 'B') -or ($testLetter -ne 'C') -or ($testLetter -ne 'D') -or ($testLetter -ne 'E')){
      if(-not(Test-Path $testletter":\")){
        $vhdMountLetter = $testLetter
        break
      }
    }
  }
  if($null -eq $vhdMountLetter){
    Write-Host "An open drive letter was not detected. Please free up drive letters or pass your desired open letter in on the pipeline. Exiting.."
    exit
  }
}

# Create DISKPART config file 
Set-Location $folderPath
Out-File "$vhdName.txt" -InputObject "create vdisk file=$localPath.vhdx type=expandable maximum=$installSize" -Encoding utf8 -Append
Out-File "$vhdName.txt" -InputObject "select vdisk file=$localPath.vhdx" -Encoding utf8 -Append
Out-File "$vhdName.txt" -InputObject "attach vdisk" -Encoding utf8 -Append
Out-File "$vhdName.txt" -InputObject "create partition primary" -Encoding utf8 -Append
Out-File "$vhdName.txt" -InputObject "format fs=ntfs label=`"$vhdName`" quick" -Encoding utf8 -Append
if($vhdMountLetter){
  Out-File "$vhdName.txt" -InputObject "assign letter=$vhdMountLetter" -Encoding utf8 -Append
}if($vhdMountPath){ 
  Out-File "$vhdName.txt" -InputObject "assign mount=`"$vhdMountPath`"" -Encoding utf8 -Append
}

# Run DISKPART with config and cleanup config file after execution
diskpart /s "$vhdName.txt"
rm "$vhdName.txt" -Force
Start-Sleep -s 3

# Download and silently install Google Chrome 
# Change the following section to install/update your application
# -------------------------------------------------------------- #
$Installer = "ChromeInstaller.exe"
(new-object System.Net.WebClient).DownloadFile('https://dl.google.com/chrome/install/chrome_installer.exe', "$LocalTempDir\$Installer")
& "$LocalTempDir\$Installer" /silent /install
$Process2Monitor =  "ChromeInstaller"
# -------------------------------------------------------------- #
Do { 
  $ProcessesFound = Get-Process | ?{$Process2Monitor -contains $_.Name} | Select-Object -ExpandProperty Name
  Start-Sleep -s 2
} Until (!$ProcessesFound)
rm "$LocalTempDir\$Installer" -ErrorAction SilentlyContinue -Verbose 

# Detach VHDX
Out-File "$LocalTempDir\$vhdName.txt" -InputObject "select vdisk file=`"$localPath.vhdx`"" -Encoding utf8 -Append
Out-File "$LocalTempDir\$vhdName.txt" -InputObject "detach vdisk noerr" -Encoding utf8 -Append
diskpart /s "$LocalTempDir\$vhdName.txt" 
rm "$LocalTempDir\$vhdName.txt" -Force
Start-Sleep -s 3

# Upload VHDX to provided S3 bucket
if($vhdS3Bucket){
  if(-not($null -eq (Get-S3Bucket -BucketName $vhdS3Bucket))){
    try{
      Write-S3Object -BucketName $vhdS3Bucket -File "$localPath.vhdx"
    }catch{
      Write-Host "S3 upload failed due to the following error message: " $_.Exception.Message
      exit
    }
  }
}