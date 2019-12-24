 Param(
   [Parameter(Mandatory=$true)]
   [string]$username,
   [Parameter(Mandatory=$true)]
   [string]$password
)

#Create a function to download sysmon-installer.ps1
function Download-Sysmon-Installer
{
try {
    $tmpfile = ""
    $tmpfile = [System.IO.Path]::GetTempFileName()
    $url = "https://raw.githubusercontent.com/Castaldio86/Sysmon-Installer/master/sysmon-installer.ps1"
    $client = New-Object System.Net.WebClient
    $client.DownloadFile($url, $tmpfile)
    Write-Verbose 'Sucessfully downloaded sysmon-installer.ps1'
    Unblock-File -Path $tmpfile -ErrorAction Stop
    $ps1file = Join-Path -Path (Split-Path -Path $tmpfile -Parent) -ChildPath 'sysmon-installer.ps1'
    if (Test-Path $ps1file) {
        $hashSrc = Get-FileHash $tmpfile -Algorithm "SHA256"
        $hashDest = Get-FileHash $ps1file -Algorithm "SHA256"
        If ($hashSrc.HashString -ne $hashDest.HashString)
            {
                Remove-Item -Path $ps1file -Force -ErrorAction Stop
                $tmpfile | Rename-Item -NewName 'sysmon-installer.ps1' -Force -ErrorAction Stop
            }
        else {
            Remove-Item -Path $tmpfile -Force -ErrorAction Stop
        }
    }
    else {
        $tmpfile | Rename-Item -NewName 'sysmon-installer.ps1' -Force -ErrorAction Stop
    }    
} 
catch {
    Throw "Something went wrong $($_.Exception.Message)"
}
return $ps1file
}

$ps1file = Download-Sysmon-Installer
$arguments = ("-ExecutionPolicy Bypass -verb RunAs -File " + $ps1file)
$jobname = "Sysmon-Installer"
$action = New-ScheduledTaskAction –Execute "$pshome\powershell.exe" -Argument "$arguments"
$duration = ([timeSpan]::maxvalue)
$trigger =New-ScheduledTaskTrigger -Once -At (get-date).AddMinutes(5).ToString("HH:mm")
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RunOnlyIfNetworkAvailable -DontStopOnIdleEnd
Register-ScheduledTask -TaskName $jobname -Action $action -Trigger $trigger -User $username -Password $password -Settings $settings