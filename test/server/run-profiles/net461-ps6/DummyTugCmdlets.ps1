<#
 # PowerShell.org Tug DSC Pull Server
 # Copyright (c) The DevOps Collective, Inc.  All rights reserved.
 # Licensed under the MIT license.  See the LICENSE file in the project root for more information.
 #> 

###########################################################################
## This is a "dummy" set of Tug Cmdlets that implement a very simple
## back-end DSC Pull Handler but demonstrate some key features.
## These cmdlets cooperate to return a fixed Node Configuration
## named "Dummy" which contains 2 DSC resources in it, namely a
## temp directory at "C:\temp" and a temp file in that directory
## "dsc-dummy-file.txt".  The content of that file is dynamically
## calculated to contain a simple message and that computed MOF
## for this configuration is computed as if it were created at
## the top of the hour, so if a node checks for any updates, it
## should only detect them after the top of the hour has passed
###########################################################################

## At our disposal we have access to several contextual variables
##  [Tug.Server.Providers.PsLogger]$handlerLogger -
##    provides a logging object specific to the handler cmdlets
##    (this is a PS-friendly instance of the ILogger interface)
##
##  [Microsoft.Extensions.Configuration.IConfiguration]$handlerAppConfiguration -
##    this provides read-only access to the resolved application-wide configuration
##
##  [Tug.Server.Provider.Ps5DscHandlercontext]$handlerContext -
##    TODO:  NOT IMPLEMENTED YET

$handlerLogger.LogInformation("Loading DUMMY Tug Cmdlets...")
$handlerLogger.LogInformation("Got Config:  $handlerAppConfiguration")

function Register-TugNode {
    param(
        [guid]$AgentId,
        [Tug.Model.RegisterDscAgentRequestBody]$Details
    )
    $handlerLogger.LogInformation("REGISTER: $($PSBoundParameters | ConvertTo-Json -Depth 3)")

    ## Return:
    ##    SUCCESS:  n/a
    ##    FAILURE:  throw an exception
}

function Get-TugNodeAction {
    param(
        [guid]$AgentId,
        [Tug.Model.GetDscActionRequestBody]$Detail
    )
    $handlerLogger.LogInformation("GET-ACTION: $($PSBoundParameters | ConvertTo-Json -Depth 3)")

    ## Return:
    ##    SUCCESS:  return an instance of [Tug.Server.ActionStatus]
    ##    FAILURE:  throw an exception

    $dummyConfig = New-SimpleMof
    $dummyConfigBytes = [System.Text.Encoding]::UTF8.GetBytes($dummyConfig)
    $checksum = Get-Sha256Checksum $dummyConfigBytes

    $configStatus = "OK"
    if ($checksum -ne $Detail.ClientStatus.Checksum) {
        $configStatus = "GetConfiguration"
    }

    $status = [Tug.Server.ActionStatus]@{
        NodeStatus = $configStatus
        ConfigurationStatuses = [Tug.Model.ActionDetailsItem[]]@(
            [Tug.Model.ActionDetailsItem]@{
                ConfigurationName = "dummy"
                Status = $configStatus
            }
        )
    }

    $handlerLogger.LogInformation("RETURNING: $($status | ConvertTo-Json)");

    return $status
}

function Get-TugNodeConfiguration {
    param(
        [guid]$AgentId,
        [string]$ConfigName
    )
    $handlerLogger.LogInformation("GET-CONFIGURATION: $($PSBoundParameters | ConvertTo-Json -Depth 3)")

    ## Return:
    ##    SUCCESS:  return an instance of [Tug.Server.FileContent]
    ##    FAILURE:  throw an exception

    $dummyConfig = New-SimpleMof
    $dummyConfigBytes = [System.Text.Encoding]::UTF8.GetBytes($dummyConfig)
    $checksum = Get-Sha256Checksum $dummyConfigBytes

    return [Tug.Server.FileContent]@{
        ChecksumAlgorithm = "SHA-256"
        Checksum = $checksum
        Content = (New-Object System.IO.MemoryStream(,$dummyConfigBytes))
    }
}

function Get-TugModule {
    param(
        [guid]$AgentId,
        [string]$ModuleName,
        [string]$ModuleVersion
    )
    $handlerLogger.LogInformation("GET-MODULE: $($PSBoundParameters | ConvertTo-Json -Depth 3)")

    throw "NOT IMPLEMENTED"
}

function New-TugNodeReport {
    $handlerLogger.LogInformation("NEW-REPORT: $($PSBoundParameters | ConvertTo-Json -Depth 3)")

    throw "NOT IMPLEMENTED"
}

function Get-TugNodeReports {
    $handlerLogger.LogInformation("GET-REPORTS: $($PSBoundParameters | ConvertTo-Json -Depth 3)")

    throw "NOT IMPLEMENTED"
}


function New-SimpleMof {
    param(
        [string]$NodeName="Dummy",
        [string]$TempDirName="c:\\temp",
        [string]$TempFileName="c:\\temp\\dsc-dummy-file.txt",
        [string]$TempFileContent=$null,
        ## By default we round down to the top of the hour
        [datetime]$MofDate=[datetime]::Now.ToString("yyyy/MM/dd HH:00")
    )
    $mofCreatedOn = $env:COMPUTERNAME
    $mofCreatedBy = $env:USERNAME
    $mofCreatedAt = $MofDate.ToString('MM/dd/yyyy hh:mm:ss')

    if (-not $TempFileContent) {
        $TempFileContent = "THIS FILE GENERATED BY TUG PS5 DSC CONFIGURATION [$NodeName] @ [$mofCreatedAt]"
    }

    @"
/*
@TargetNode='$NodeName'
@GeneratedBy=$mofCreatedBy
@GenerationDate=$mofCreatedAt
@GenerationHost=$mofCreatedOn
*/

instance of MSFT_FileDirectoryConfiguration as `$MSFT_FileDirectoryConfiguration1ref
{
 ResourceID = "[File]TempDir";
 Type = "Directory";
 Ensure = "Present";
 DestinationPath = "$TempDirName";
 ModuleName = "PSDesiredStateConfiguration";
 SourceInfo = "C:\\ezsops\\devops\\StaticTestConfig.dsc.ps1::4::9::File";
 ModuleVersion = "1.0";
 ConfigurationName = "$NodeName";
};

instance of MSFT_FileDirectoryConfiguration as `$MSFT_FileDirectoryConfiguration2ref
{
 ResourceID = "[File]TempFile";
 Type = "File";
 Ensure = "Present";
 Contents = "$TempFileContent";
 DestinationPath = "$TempFileName";
 ModuleName = "PSDesiredStateConfiguration";
 SourceInfo = "C:\\ezsops\\devops\\StaticTestConfig.dsc.ps1::10::9::File";
 ModuleVersion = "1.0";
 DependsOn = {
    "[File]TempDir"};
    ConfigurationName = "$NodeName";
};

instance of OMI_ConfigurationDocument
{
 Version="2.0.0";
 MinimumCompatibleVersion = "1.0.0";
 CompatibleVersionAdditionalProperties= {"Omi_BaseResource:ConfigurationName"};
 Author="$mofCreatedBy";
 GenerationDate="$mofCreatedAt";
 GenerationHost="$mofCreatedOn";
 Name="$NodeName";
};

"@
}

function Get-Sha256Checksum {
    param(
        [byte[]]$Bytes
    )

    $sha256 = [System.Security.Cryptography.SHA256]::Create()
    $checksumBytes = $sha256.ComputeHash($Bytes)
    $checksum = [System.BitConverter]::ToString($checksumBytes).Replace("-", "")
    $sha256.Dispose()
    return $checksum
}

Write-Output "All DUMMY Tug Cmdlets are defined"
