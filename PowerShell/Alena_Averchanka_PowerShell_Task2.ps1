$DefaultDaysAgo = 30
$DefaultOutputDir = "D:\temp\"
$DefaultApplicationLogs = $true
$DefaultSystemLogs = $true

# For Windows with english default language
$DefaultSeverity = @("Error", "Warning")

# For Windows with russian default language
#$DefaultSeverity = @("Ошибка", "Предупреждение")

# Get-Logs-CSV - main function. To get logs in .csv file you should use it.
function Get-Logs-CSV {
    <#
    .SYNOPSIS
        Gathering Windows Event Viewer logs and export data into .csv files.

    .DESCRIPTION
        Get-Logs-CSV is a function that exports Windows application and/or system logs 
        to a specified folder as a .csv file for a specified number of days from today's date.

    .PARAMETER outputDir
        This is the destination folder of the report. Default value: D:\temp\
    
    .PARAMETER applicationLogs
        To get all Application logs. Default value: true.
    
    .PARAMETER systemLogs
        To get all System logs. Default value: true.

    .PARAMETER fromDate
        This is start day to receive logs. Default value: for the last 30 days.

    .PARAMETER severity
        This is the specified log level. Default value: [Error, Warning].

    .EXAMPLE
         PS C:\> Get-Logs-CSV -outputDir "D:\" -applicationLogs $false -fromDate MM/DD/YYYY -severity Error
    
    .EXAMPLE
         PS C:\> Get-Logs-CSV -outputDir "D:\" -systemLogs $false -fromDate MM-DD-YYYY

    .INPUTS
        Input (if any)

    .OUTPUTS
        Output (if any)
    #>

    [CmdletBinding()]
    param(
        [parameter()]
        [ValidatenotNullorEmpty()]
        [string]$outputDir = $DefaultOutputDir,

        [parameter()]
        [ValidatenotNullorEmpty()]
        [bool]$applicationLogs = $DefaultApplicationLogs,

        [parameter()]
        [ValidatenotNullorEmpty()]
        [bool]$systemLogs = $DefaultSystemLogs,

        [parameter()]
        [ValidatenotNullorEmpty()]
        [datetime]$fromDate = (Get-Date).adddays(-$DefaultDaysAgo),

        [parameter()]
        [ValidatenotNullorEmpty()]
        [string[]]$severity = $DefaultSeverity
    )
    
    $app = 'Application'
    $sys = 'System'

    #Check exicted directory
    if (!(Test-Path -Path $outputDir)) {
        Write-Host "There is no such directory. Creating new one: $outputDir"
        $null = New-Item -ItemType Directory -Path $outputDir 
    }

    #Run for Application Logs
    if ($applicationLogs -eq $true) {
        Export-To-CSV -LogType $app
    }

    #Run for System Logs
    if ($systemLogs -eq $true) {
        Export-To-CSV -LogType $sys
    }
}

# Export-To-CSV - helper function. Generate report and export to .csv file.
function Export-To-CSV {

    [CmdletBinding()]
    param(
        [parameter()]
        [ValidatenotNullorEmpty()]
        [string]$LogType
    )

    $DateNow = Get-Date
    $DateStart = $fromDate -as [datetime]
    $Array = @()

    $ExportFile = $outputDir + $LogType + "Logs" + "_" + $DateNow.ToString("yyyyMMddHHmmss") + ".csv"
    #Adding records to an array $Array
    foreach ($s in $severity) {
       $StrLog = Get-WinEvent -LogName $LogType | Where-Object { $_.TimeCreated -ge $DateStart -and $_.LevelDisplayName -eq $s }
       $Array += $StrLog
    }
    #Sorting and exporting array to file.
    $Array | Sort-Object TimeCreated -Descending | Select MachineName, @{n='TimeGenerated';e={$_.TimeCreated}}, @{n='EntryType';e={$_.LevelDisplayName}}, @{n='Source';e={$_.ProviderName}}, @{n='Message';e={$_.Message -replace '\s+', " "}} | Export-CSV $ExportFile -Encoding UTF8 -NoTypeInformation
    Write-Host "Exporting system logs to $ExportFile."
}
Get-Help "Get-Logs-CSV"