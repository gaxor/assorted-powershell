#Requires -Version 5
# Script not complete

# You'll need Get-GzipContent from https://mcardletech.com/blog/reading-and-writing-gzip-files-with-powershell/

# Objectives:
#     Download CloudTrail log files
#     Put data into searchable format (SQL database?)
#     Multiple search queries
#         CloudTrail Event History: https://console.aws.amazon.com/cloudtrail/home?region=us-east-1#/events
#         Supported services: https://docs.aws.amazon.com/awscloudtrail/latest/userguide/view-cloudtrail-events-supported-services.html
#     GUI for searching

Enum CloudTrailAttributes
{
    EventId
    EventName
    Username
    ResourceType
    ResourceName
    EventSource
}

#Function Get-CloudTrailLogFiles{}

$FilePath  = 'C:\Users\Greg\Downloads\08'
$ZipFiles  = Get-ChildItem -Path $FilePath -Recurse -File | Select Name, FullName
$JsonFiles = [System.Collections.ArrayList] @()

ForEach ( $File in $ZipFiles )
{
    $JsonFiles.Add( ( Get-GzipContent -FilePath $File.FullName | ConvertFrom-Json ) )
}