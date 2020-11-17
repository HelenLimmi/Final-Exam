param(
    [parameter()]
    [ValidatenotNullorEmpty()]
    [string]$outputDir = "D:\temp\",

    [parameter()]
    [ValidatenotNullorEmpty()]
    [bool]$applicationLogs = $true,

    [parameter()]
    [ValidatenotNullorEmpty()]
    [bool]$systemLogs = $true,

    [parameter()]
    [ValidatenotNullorEmpty()]
    [datetime]$fromDate = (Get-Date).adddays(-30),

    [parameter()]
    [ValidatenotNullorEmpty()]
    # For Windows with russian default language
    [string[]]$severity = @("Ошибка", "Предупреждение")

    # For Windows with english default language
    #[string[]]$severity = @("Error", "Warning")
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

# Generate report and export to .csv file.
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