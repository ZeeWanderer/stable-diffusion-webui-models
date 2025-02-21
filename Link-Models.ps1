<#
.SYNOPSIS
    Recursively creates hard links for files from a source directory to one or more target directories based on configuration mappings.
.DESCRIPTION
    This script reads a JSON configuration file (by default “configuration.json” in the script directory) that specifies:
        • A source directory
        • One or more target directories, with optional directory name mappings.
    It then recursively creates hard links from the source to each target, while skipping the script file, configuration files,
    markdown (.md) files, and any PowerShell script (.ps1) files.
.PARAMETER ConfigFile
    Optional path to a configuration file.
.EXAMPLE
    .\Link-Models.ps1 -WhatIf
    .\Link-Models.ps1 -Confirm
    .\Link-Models.ps1 -Verbose
#>

[CmdletBinding(SupportsShouldProcess=$true)]
param (
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$ConfigFile = (Join-Path -Path $PSScriptRoot -ChildPath "configuration.json")
)

try {
    Write-Verbose "Reading configuration file from '$ConfigFile'."
    $config = Get-Content -Path $ConfigFile -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
    Write-Verbose "Configuration file successfully read and parsed."
} catch {
    Write-Error "Failed to read or parse the configuration file: $_"
    exit 1
}

$sourceDirectory = $config.sourceDirectory
$targetDirectories = $config.targetDirectories

if (-not (Test-Path -Path $sourceDirectory)) {
    Write-Error "Source directory '$sourceDirectory' does not exist."
    exit 1
}

function New-Hardlinks {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param (
        [Parameter(Mandatory = $true)]
        [string]$SourcePath,
        
        [Parameter(Mandatory = $true)]
        [string]$TargetPath,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$Mappings
    )

    $scriptName = [System.IO.Path]::GetFileName($MyInvocation.MyCommand.Path)
    try {
        $items = Get-ChildItem -Path $SourcePath -ErrorAction Stop
    } catch {
        Write-Error "Unable to retrieve items from '$SourcePath': $_"
        return
    }

    foreach ($item in $items) {
        try {
            if ($item.PSIsContainer) {
                if ($Mappings.ContainsKey($item.Name) -and $Mappings[$item.Name] -eq 'nil') {
                    Write-Verbose "Skipping subdirectory '$($item.FullName)' as per mapping."
                    continue
                }

                $targetSubDirName = if ($Mappings.ContainsKey($item.Name)) { $Mappings[$item.Name] } else { $item.Name }
                $newTargetPath = Join-Path -Path $TargetPath -ChildPath $targetSubDirName

                if (-not (Test-Path -Path $newTargetPath)) {
                    if ($PSCmdlet.ShouldProcess($newTargetPath, "Create directory")) {
                        Write-Verbose "Creating directory '$newTargetPath'."
                        New-Item -ItemType Directory -Path $newTargetPath -ErrorAction Stop | Out-Null
                    }
                }

                Write-Verbose "Processing subdirectory '$($item.FullName)'."
                New-Hardlinks -SourcePath $item.FullName -TargetPath $newTargetPath -Mappings $Mappings
            }
            elseif ($item.Name -ne $scriptName -and `
                    $item.Extension -notin @(".ps1", ".md") -and `
                    $item.Name -notin @("configuration.json", "example_configuration.json")) {
                $hardlinkPath = Join-Path -Path $TargetPath -ChildPath $item.Name
                if (-not (Test-Path -Path $hardlinkPath)) {
                    if ($PSCmdlet.ShouldProcess($hardlinkPath, "Create hardlink from '$($item.FullName)'")) {
                        Write-Verbose "Creating hardlink from '$($item.FullName)' to '$hardlinkPath'."
                        New-Item -ItemType HardLink -Path $hardlinkPath -Target $item.FullName -ErrorAction Stop | Out-Null
                    }
                }
            }
        } catch {
            Write-Error "Failed to create hardlink for '$($item.FullName)': $_"
        }
    }
}

foreach ($targetDirectory in $targetDirectories) {
    try {
        $targetPath = $targetDirectory.Path
        if (-not (Test-Path -Path $targetPath)) {
            if ($PSCmdlet.ShouldProcess($targetPath, "Create target directory")) {
                Write-Verbose "Target directory '$targetPath' does not exist. Creating it."
                New-Item -ItemType Directory -Path $targetPath -ErrorAction Stop | Out-Null
            }
        }

        $mappings = @{}
        foreach ($key in $targetDirectory.Mappings.PSObject.Properties.Name) {
            $mappings[$key] = $targetDirectory.Mappings.$key
        }
        Write-Verbose "Processing target directory '$targetPath'."
        New-Hardlinks -SourcePath $sourceDirectory -TargetPath $targetPath -Mappings $mappings
    } catch {
        Write-Error "Failed to process target directory '$($targetDirectory.Path)': $_"
    }
}

Write-Output "Hardlinks creation process completed."
