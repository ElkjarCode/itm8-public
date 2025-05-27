<#
.SYNOPSIS
    This script retrieves hardware information from a Windows computer and generates a hardware hash.

.DESCRIPTION
    The script collects various hardware details such as computer name, serial number, TPM version, and Secure Boot status. It then generates a hardware hash and saves it to a CSV file on the user's desktop.

.NOTES
    Author: Steffen Elkjær
    Username: stelk@itm8.com
    Created: 2024-05-24
    Version: 1.0
    Website: www.miracle42.dk

#>

# Restart PowerShell as admin
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $arguments = "& '" + $MyInvocation.MyCommand.Path + "'"
    Write-Host "Please accept the UAC prompt to continue running the script as administrator."
    Write-Host "After the script has finished you will get a file on your desktop with the hardware hash."
    Write-Host "Please send this file to your IT department."
    Start-Process powershell -Verb RunAs -ArgumentList $arguments
    exit
}

# Getting hardware hash
$OutputFolder = [environment]::GetFolderPath('Desktop')
$CompName = (Get-CimInstance -ClassName Win32_ComputerSystem).Name

# Getting Serial Number
$Get_SerialNumber = (Get-CimInstance -ClassName win32_bios).SerialNumber

# Getting logged in user
$loggedinuser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name.Split("\")[-1]

# Setting Hardware Hash Filename
$Hardware_Hash_File = "$($OutputFolder)\$loggedinuser" + "_$Get_SerialNumber" + "_HardwareHash.csv"

# Getting Hardware Hash
$Get_Hardware_Hash = (Get-CimInstance -Namespace root/cimv2/mdm/dmmap -ClassName MDM_DevDetail_Ext01 -Filter "InstanceID='Ext' AND ParentID='./DevDetail'").DeviceHardwareData

# Getting TPM Version
$TPM = Get-WmiObject -Namespace root/cimv2/security/microsofttpm -Class Win32_Tpm
$TPM2True = [bool]($TPM.SpecVersion -ge '2.0')

# Getting Secure Boot Status
$SecureBoot = Confirm-SecureBootUEFI

# Creating CSV File
$AutoPilotString = "Username,ComputerName,Device Serial Number,TPM Version 2.0,Secure Boot Enabled,Hardware Hash`n" + $loggedinuser + "," + $CompName + "," + $Get_SerialNumber + "," + $TPM2True + "," + $SecureBoot + "," + $Get_Hardware_Hash
$AutoPilotString | Out-File $Hardware_Hash_File