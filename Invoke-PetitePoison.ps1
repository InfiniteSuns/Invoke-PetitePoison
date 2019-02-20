<#
.SYNOPSIS
    A tool to match 'user:hash' files to 'hash:pass' files, creating a 'user:pass' file.
.DESCRIPTION
    Imagine you have a long list of users and their hashes, and a hashcat potfile of craked hashes. Now you can create yourself a nice file consisting of only users with their cracked passwords.
.PARAMETER UserHash
    The path to the path to 'user:hash' file (i.e. C:\UserHashPath.txt)
.PARAMETER HashPass
    The path to the path to 'hash:pass' file (i.e. C:\HashPassPath.txt)
.PARAMETER UserPass
    The path to the path to 'user:pass' file (i.e. C:\UserPassPath.txt). If not set file with timestamp is going to be created in the same directory as script file.
.EXAMPLE
    C:\PS> .\Invoke-PetitePoison.ps1 -UserHash C:\UserHashPath.txt -HashPass C:\HashPassPath.txt -UserPass C:\UserPassPath.txt
.NOTES
    Author: Dmitry Kireev @InfiniteSuns
    Date:   February 20, 2019    
#>

param (
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [String]$UserHash = $null,
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [String]$HashPass = $null,
    [String]$UserPass = $null
)

function Get-ReverseString {
param( [String]$StringToReverse )
    $StringToReverseArr = $StringToReverse.ToCharArray()
    [Array]::Reverse($StringToReverseArr)
    [String]$ReversedString = -join $StringToReverseArr
    $ReversedString
}

$NoStats = $false
$NoSemicolons = $true

if ($PSBoundParameters.ContainsKey('UserHash')) {
    Write-Output "[i] Userhash path received as argument"
    if (Test-Path -Path $UserHash) {
        Write-Output "[+] Userhash path seems legit`n"
        $UserHashPath = $UserHash
    }
}

if ($PSBoundParameters.ContainsKey('HashPass')) {
    Write-Output "[i] Hashpass path received as argument"
    if (Test-Path -Path $HashPass) {
        Write-Output "[+] Hashpass path seems legit`n"
        $HashPassPath = $HashPass
    }
}

if ($PSBoundParameters.ContainsKey('UserPass')) {
    Write-Output "[i] Userpass path received as argument"
    if (Test-Path -Path $UserPass) {
        Write-Output "[!] Userpass file seem to already exist, sure you want to append to it?"
        $ReadHost = Read-Host "[?] Default is to append (y/n)" 
            Switch ($ReadHost) { 
                Y { Write-Output "[+] Fine, you wanted that, not me`n"; $UserPassPath = $UserPass; $NoStats = $true }
                N {
                    Write-Output "[+] Well then, going to write to our own UserPassPath file"
                    [Int]$TimeStampCurrent = (New-TimeSpan -Start (Get-Date "01/01/1970") -End (Get-Date)).TotalSeconds
                    $CurrentDir = Split-Path (Get-Variable MyInvocation).Value.MyCommand.Path
                    $UserPassPath = "$CurrentDir\UserPass$TimeStampCurrent.txt" }
                Default { Write-Output "[+] Lazy today? Okay, default is to append, you were warned`n"; $UserPassPath = $UserPass; $NoStats = $true } 
            }
    } else {
        Write-Output "[+] Userpass path seem to not exist, will create a file`n"
        $UserPassPath = $UserPass
    }
} else {
    Write-Output "[+] Userpass path not set, will create a file`n"
    [Int]$TimeStampCurrent = (New-TimeSpan -Start (Get-Date "01/01/1970") -End (Get-Date)).TotalSeconds
    $CurrentDir = Split-Path (Get-Variable MyInvocation).Value.MyCommand.Path
    $UserPassPath = "$CurrentDir\UserPass$TimeStampCurrent.txt"
}

 Write-Output "[!] Do your hashes contain semicolons (e.g. NetNTLMv2)?"
$ReadHost = Read-Host "[?] Default is no (y/n)" 
Switch ($ReadHost) { 
    Y { Write-Output "[+] Okay, but it is going to a loooong time`n"; $NoSemicolons =$false }
    N { Write-Output "[+] Fine then, it is going to be faster`n"; $NoSemicolons =$true }
    Default { Write-Output "[+] Lazy today? Well, default is no semicolons`n"; $NoSemicolons =$true } 
}

$CurrentPass = ""
$CurrentUser = ""
$CurrentHash = ""
$TotalUserHashCount = 0
$TotalHashPassCount = 0
$TotalUserPassCount = 0
$CurrentUserHashCount = 0

$TotalUserHashCount = (Get-Content -Path $UserHashPath | Measure-Object -Line).Lines
$TotalHashPassCount = (Get-Content -Path $HashPassPath | Measure-Object -Line).Lines

Write-Output "[i] Got $TotalUserHashCount 'user:hash' lines"
Write-Output "[i] Got $TotalHashPassCount 'hash:pass' lines`n"

$TimeStampStart = 0
$TimeStampStop = 0

[Int]$TimeStampStart = (New-TimeSpan -Start (Get-Date "01/01/1970") -End (Get-Date)).TotalSeconds

Try {
    foreach($UserHashLine in [System.IO.File]::ReadLines($UserHashPath)) {
        $CurrentUserHashCount += 1
        $CurrentPass = ""
        $CurrentUser = $UserHashLine.Split(":")[0]
        $CurrentHash = $UserHashLine.Split(":")[1]
        foreach($HashPassLine in [System.IO.File]::ReadLines($HashPassPath)) {
            if ($NoSemicolons -eq $true) {
                $PotfileHash = $HashPassLine.Split(":")[0]
                $PotfilePass = $HashPassLine.Split(":")[1]
            } else {
                $HashPassLineReversed = Get-ReverseString($HashPassLine)
                $PotfilePass = Get-ReverseString($HashPassLineReversed.Split(":")[0])
                $PotfileHash = Get-ReverseString($HashPassLineReversed.Split(":")[1])
            }
            if ($PotfileHash -eq $CurrentHash) {
                $CurrentPass = $PotfilePass
            }
        }
        if ($CurrentPass -ne "") {
            $UserPassLine = $CurrentUser + ":" + $CurrentPass
            [System.IO.File]::AppendAllLines([String]$UserPassPath, [String[]]$UserPassLine)
        } 
        Write-Progress -activity "[i] Now, going to replace hashes with passwords, do not look away from progress bar" -status "[i] $CurrentUserHashCount of out $TotalUserHashCount hashes processed" -percentComplete (($CurrentUserHashCount / $TotalUserHashCount) * 100)
    }
} Catch [System.Management.Automation.RuntimeException] {
    Write-Warning "[!] Something went wrong, will try to use native functions, probably it'll help`n"
    foreach($UserHashLine in Get-Content $UserHashPath) {
        $CurrentUserHashCount += 1
        $CurrentPass = ""
        $CurrentUser = $UserHashLine.Split(":")[0]
        $CurrentHash = $UserHashLine.Split(":")[1]
        foreach($HashPassLine in Get-Content $HashPassPath) {
            if ($NoSemicolons -eq $true) {
                $PotfileHash = $HashPassLine.Split(":")[0]
                $PotfilePass = $HashPassLine.Split(":")[1]
            } else {
                $HashPassLineReversed = Get-ReverseString($HashPassLine)
                $PotfilePass = Get-ReverseString($HashPassLineReversed.Split(":")[0])
                $PotfileHash = Get-ReverseString($HashPassLineReversed.Split(":")[1])
            }
            if ($PotfileHash -eq $CurrentHash) {
                $CurrentPass = $PotfilePass
            }
        }
        if ($CurrentPass -ne "") {
            $UserPassLine = $CurrentUser + ":" + $CurrentPass
            Add-Content -Path $UserPassPath -Value $UserPassLine
        } 
        Write-Progress -activity "[i] Now, going to replace hashes with passwords, do not look away from progress bar" -status "[i] $CurrentUserHashCount of out $TotalUserHashCount hashes processed" -percentComplete (($CurrentUserHashCount / $TotalUserHashCount) * 100)
    }
}

[Int]$TimeStampStop = (New-TimeSpan -Start (Get-Date "01/01/1970") -End (Get-Date)).TotalSeconds
$TimeTaken = $TimeStampStop - $TimeStampStart
Write-Output "[i] Done in $TimeTaken seconds"

if ($NoStats -ne $true) {
    $TotalUserPassCount = (Get-Content -Path $UserPassPath | Measure-Object -Line).Lines
    [Int]$percent = (100 * $TotalUserPassCount / $TotalUserHashCount)
    Write-Output "[i] Now you have $TotalUserPassCount 'user:pass' lines"
    Write-Output "[i] It is approximately $percent%"
}