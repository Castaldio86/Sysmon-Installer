<#                                                                                                                                                               
#                                                                                                                                                               
#                                                                                                                                                               
#                                                                                                                                                               
#                                                                                                                                                               
#                                                                                                                                   .         .                 
#                                                                                                  ..                          .*////     *////                 
#                                                                                             */////.                          //////    //////                 
#                                                                                            ,//////.                          //////    //////                 
#                                                                                            ,//////.                          //////    //////                 
#                //////       //////       //////      *////////////*     .//////,*////,  //////////////    /////////////      //////    //////                 
#                //////       //////       //////    *///////**////////    ////////////,  //////////////  //////*  .//////.    //////    //////                 
#                //////       //////       //////   *//////      ///////   /////////*,.      ,//////     //////*     //////    //////    //////                 
#                //////       //////       //////   //////*      *//////   ///////           ,//////     ///////////////////   //////    //////                 
#                //////       //////       //////  .//////*      ,//////.  //////*           ,//////     ///////////////////  .//////   .//////                 
#                //////       //////       //////   ///////      ///////   //////,           ,//////     //////               .//////   .//////                 
#                .//////,   ,////////,    ///////   ,//////*     ///////   //////,           ,//////     //////*     //////*   //////    //////                 
#                 ,////////////////////////////,      ////////////////     //////,           ,//////      ,///////////////.    ////////. ////////               
#                   *///////////  ///////////*          *//////////*       //////,           ,//////.       ,///////////.       ///////.  ///////               
#                                                                                             //////////                                                        
#                                                                                              /////////                                                        
#                                                                                                                                                               
#                                                                                                                                                                
#																																							    
#																																								
#																																								
#>

<#
#Script is created by Gianni Castaldi (gianni.castaldi@wortell.nl)
#Check sysmon
#Download Sysmon
#Download sysmonconfig.xml
#Install Sysmon
#Update Sysmon
#>

#Script variables
$SysmonHash = "80B110B91730729BE60C7D79C55FFF0EC893FD4CFB5F44D04C433EE8E95C5E20"
$SysmonConfigHash = "2603EC0EF528EA1FF10A2D60D3885C1B8887AC02"

#Check if correct version of Sysmon is installed
function Test-Sysmon
{
    $HashCorrect = $false
    $XMLHashCorrect = $false
    $ServiceExist = $false
    if (Get-WmiObject win32_service -ErrorAction Stop | Where-Object {$_.Description -eq "System Monitor service"}) {
        $ServiceExist = $true
        $SysmonPath = ""
        $SysmonPath = (Get-WmiObject win32_service | Where-Object {$_.Description -eq "System Monitor service"}) | Select-Object Name,PathName,State
    }
    if ($SysmonPath.PathName) {
        $hashDest = ""
        $hashDest = Get-FileHash $SysmonPath.PathName -Algorithm "SHA256"
        If ($SysmonHash -eq $hashDest.Hash) {
            $HashCorrect = $true
        }
    }
    try {
        $SHA1 = ""
        $SHA1 = ((Get-WinEvent Microsoft-Windows-Sysmon/Operational | Where-Object {$_.Id -eq "16" -and $_.Message -Match "Sysmon config state changed:"} -ErrorAction Stop | Select-Object -ExpandProperty Message -first 1) -Split "`r`n" -Match "ConfigurationFileHash" -Replace "ConfigurationFileHash: SHA1=","")
        If ($SHA1 -eq $SysmonConfigHash) {
            $XMLHashCorrect = $true
        }
        else {
                $SHA1 = "0"
        }
    }
    catch { 
        Write-Error "Unable to read eventviewer"
    }

    $SysmonStatus = [PSCustomObject] @{
    ServiceExist = $ServiceExist 
    SysmonPath = $SysmonPath
    SysmonDefaultHash = $SysmonHash
    SysmonInstalledHash= $hashDest.Hash
    XMLDefaultHash = $SysmonConfigHash
    XMLInstalledHash = $SHA1
    HashCorrect = $HashCorrect
    XMLHashCorrect = $XMLHashCorrect
    }
return $SysmonStatus
}

#Create a function to download Sysmon.exe
function Download-Sysmon 
{
try {
    $tmpfile = ""
    $tmpfile = [System.IO.Path]::GetTempFileName()
    $url = "https://live.sysinternals.com/Sysmon.exe"
    $client = New-Object System.Net.WebClient
    $client.DownloadFile($url, $tmpfile)
    Write-Verbose 'Sucessfully downloaded Sysmon.exe'
    Unblock-File -Path $tmpfile -ErrorAction Stop
    $exefile = Join-Path -Path (Split-Path -Path $tmpfile -Parent) -ChildPath 'Sysmon.exe'
    if (Test-Path $exefile) {
        $hashSrc = ""
        $hashDest = ""
        $hashSrc = Get-FileHash $tmpfile -Algorithm "SHA256"
        $hashDest = Get-FileHash $exefile -Algorithm "SHA256"
        If ($hashSrc.HashString -ne $hashDest.HashString)
            {
                Remove-Item -Path $exefile -Force -ErrorAction Stop
                $tmpfile | Rename-Item -NewName 'Sysmon.exe' -Force -ErrorAction Stop
            }
        else {
            Remove-Item -Path $tmpfile -Force -ErrorAction Stop
        }
    }
    else {
        $tmpfile | Rename-Item -NewName 'Sysmon.exe' -Force -ErrorAction Stop
    }    
} 
catch {
    Throw "Something went wrong $($_.Exception.Message)"
}
return $exefile
}

#Create a function to download sysmonconfig.xml
function Download-SysmonConfig
{
try {
    $tmpfile = ""
    $tmpfile = [System.IO.Path]::GetTempFileName()
    $url = "https://github.com/Castaldio86/Sysmon-Installer/blob/master/sysmonconfig.xml"
    $client = New-Object System.Net.WebClient
    $client.DownloadFile($url, $tmpfile)
    Write-Verbose 'Sucessfully downloaded sysmonconfig.xml'
    Unblock-File -Path $tmpfile -ErrorAction Stop
    $xmlfile = Join-Path -Path (Split-Path -Path $tmpfile -Parent) -ChildPath 'sysmonconfig.xml'
    if (Test-Path $xmlfile) {
        $hashSrc = Get-FileHash $tmpfile -Algorithm "SHA256"
        $hashDest = Get-FileHash $xmlfile -Algorithm "SHA256"
        If ($hashSrc.HashString -ne $hashDest.HashString)
            {
                Remove-Item -Path $xmlfile -Force -ErrorAction Stop
                $tmpfile | Rename-Item -NewName 'sysmonconfig.xml' -Force -ErrorAction Stop
            }
        else {
            Remove-Item -Path $tmpfile -Force -ErrorAction Stop
        }
    }
    else {
        $tmpfile | Rename-Item -NewName 'sysmonconfig.xml' -Force -ErrorAction Stop
    }    
} 
catch {
    write-Error "Something went wrong $($_.Exception.Message)"
}
return $xmlfile
}

#Install Sysmon.exe with sysmonconfig.xml
function Install-Sysmon {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string] $Parameter,
        [Parameter(Mandatory)]
        [string] $SysmonEXE,
        [Parameter()]
        [string] $SysmonXML
    )
        $Arguments = ""
        if ($Parameter -eq "i"){
            $Arguments = ("-accepteula -" + $Parameter + " " + $SysmonXML)
        }
        else {
            $Arguments = ("-" + $Parameter + " " + $SysmonXML)
        }
Start-Process -FilePath $SysmonEXE -ArgumentList $Arguments -verb RunAs -Wait
}

#___Main___
$SysmonStatus = Test-Sysmon
$SysmonXML = Download-SysmonConfig
$SysmonEXE = Download-Sysmon

# Install (Not installed)
if ($SysmonStatus.HashCorrect -eq $false -and $SysmonStatus.XMLHashCorrect -eq $false){
    Write "Install (Not installed)"
    $Parameter = "i"
    Install-Sysmon $Parameter $SysmonEXE $SysmonXML
    $SysmonStatus = Test-Sysmon
}

# Reinstall (Installed not Running)
if ($SysmonStatus.ServiceExist -eq $true -and $SysmonStatus.SysmonPath.State -ne "Running"){
    Write "Reinstall (Installed not Running)"
    $Parameter = "u"
    Install-Sysmon $Parameter $SysmonStatus.SysmonPath.PathName
    $Parameter = "i"
    Install-Sysmon $Parameter $SysmonEXE $SysmonXML
    $SysmonStatus = Test-Sysmon
}

# Reinstall (Wrong Sysmon Version)
if ($SysmonStatus.HashCorrect -eq $false -and $SysmonStatus.XMLHashCorrect -eq $true){
    Write "Reinstall (Wrong Sysmon Version)"
    $Parameter = "u"
    Install-Sysmon $Parameter $SysmonStatus.SysmonPath.PathName
    $Parameter = "i"
    Install-Sysmon $Parameter $SysmonEXE $SysmonXML
    $SysmonStatus = Test-Sysmon
}

# Reinstall (Wrong Name)
if ($SysmonStatus.ServiceExist -eq $true -and $SysmonStatus.SysmonPath.Name -ne "Sysmon"){
    Write "Reinstall (Wrong Name)"
    $Parameter = "u"
    Install-Sysmon $Parameter $SysmonStatus.SysmonPath.PathName
    $Parameter = "i"
    Install-Sysmon $Parameter $SysmonEXE $SysmonXML
    $SysmonStatus = Test-Sysmon
}

# Change (Wrong XML Version)
if ($SysmonStatus.HashCorrect -eq $true -and $SysmonStatus.XMLHashCorrect -eq $false){
    Write "Change (Wrong XML Version)"
    $Parameter = "c"
    Install-Sysmon $Parameter $SysmonEXE $SysmonXML
    $SysmonStatus = Test-Sysmon
}

write $SysmonStatus