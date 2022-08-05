#Requires -Module Microsoft.PowerShell.Utility
# You can change the following defaults by altering the below settings:
#
# Set debug parameters
#$MyWhatif = $False
#$VerbosePreference = 'Continue'

# Helper functions
Function Get-Config {
    [CmdletBinding()]
    param(
        [string]$fileName
    )
    Try {
        Write-Verbose "Getting settings from $fileName"
        $configuration = Get-Content $fileName -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
        return $configuration
    }
    Catch {
        Write-Verbose "Config file not found"
        throw "Config File not found"
    }
}

function ConvertTo-Base64($string) {
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($string);
    $encoded = [System.Convert]::ToBase64String($bytes);
    return $encoded;
}

# Start of Script

# get the configuration data
Try {
    if ($PSScriptRoot.Length -eq 0) { $configRoot = "." } else { $configRoot = $PSScriptRoot }
    $configPath = Join-Path $configRoot 'config.json'
    $config = Get-Config $configPath
}
catch {
    Write-Host "Config File not found"
    Exit
}

$account     = $config.account # Atlassian subdomain i.e. whateverproceeds.atlassian.net
$username    = $config.username # username with domain something@domain.com
$token    = $config.token # Token created from product https://confluence.atlassian.com/cloud/api-tokens-938839638.html
$destination = $config.destination # Location on server where script is run to dump the backup zip file.
$attachments = $config.attachments # Tells the script whether or not to pull down the attachments as well
$cloud     = $config.cloud # Tells the script whether to export the backup for Cloud or Server
$today       = Get-Date -format yyyyMMdd-hhm # used to name backup file

# ensure we make calls with TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12;

# check for the destination path and create if not present
if(!(Test-Path -path $destination -PathType Container)){
Write-Verbose "Folder is not present, creating folder"
New-Item -ItemType Directory -Path $destination # create the Directory if it is not present
}
else{
Write-Verbose "Path is already present"
}

#Convert credentials to base64 for REST API header
$b64 = ConvertTo-Base64($username + ":" + $token);
$auth = $b64;

$body = @{
          cbAttachments=$attachments
          exportToCloud=$cloud
         }
$bodyjson = $body | ConvertTo-Json

if ($PSVersionTable.PSVersion.Major -lt 4) {
    throw "Script requires at least PowerShell version 4. Get it here: https://www.microsoft.com/en-us/download/details.aspx?id=40855"
}

Write-Verbose "Creating header for authup"
    [string]$ContentType = "application/json"
    [string]$URI = "https://$account.atlassian.net/rest/backup/1/export/runbackup"

    #Create Header
        $header = @{
                "Authorization" = "Basic "+$auth
                "Content-Type"="application/json"
                    }

Write-Verbose "Requesting backup"
try {
        $InitiateBackup = Invoke-RestMethod -Method Post -Headers $header -Uri $URI -ContentType $ContentType -Body $bodyjson -Verbose | ConvertTo-Json -Compress | Out-Null
} catch {
        $Exception = $_.Exception
        $InitiateBackup = $Exception.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($InitiateBackup)
        $reader.BaseStream.Position = 0
        $reader.DiscardBufferedData()
        $responseBody = $reader.ReadToEnd();
}

$responseBody

$GetBackupID = Invoke-WebRequest -Method Get -Headers $header https://$account.atlassian.net/rest/backup/1/export/lastTaskId
$LatestBackupID = $GetBackupID.content


Write-Verbose "Waiting for backup to finish"
do {
    $status = Invoke-RestMethod -Method Get -Headers $header -Uri "https://$account.atlassian.net/rest/backup/1/export/getProgress?taskId=$LatestBackupID"
    $statusoutput = $status.result
    $separator = ","
    $option = [System.StringSplitOptions]::None
    $s

    if ($status.progress -match "(\d+)") {
        $percentage = $Matches[1]
        if ([int]$percentage -gt 100) {
            $percentage = "100"
        }
        Write-Progress -Activity 'Creating backup' -Status $status.progress -PercentComplete $percentage
    }
    Start-Sleep -Seconds 5
} while($status.status -ne 'Success')

Write-Verbose "Downloading the backup file"
# first check to see if the backup failed?
if ([bool]($status.PSObject.Properties.Name -match "failedMessage")) {
    throw $status.failedMessage
}

# get the results 
$BackupDetails = $status.result
Write-Verbose "Backup details: [$BackupDetails]"
$BackupURI = "https://$account.atlassian.net/plugins/servlet/$BackupDetails"

Invoke-WebRequest -Method Get -Headers $header -WebSession $session -Uri $BackupURI -OutFile (Join-Path -Path $destination -ChildPath "JIRA-backup-$today.zip")