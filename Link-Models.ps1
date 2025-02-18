[CmdletBinding()]
param ()

$configPath = "E:/Tools/stable-diffusion-webui-models/configuration.json"

try {
    Write-Verbose "Reading configuration file from '$configPath'"
    $config = Get-Content -Path $configPath -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
    Write-Verbose "Configuration file successfully read and parsed."
} catch {
    Write-Error "Failed to read or parse the configuration file: $_"
    exit 1
}

$sourceDirectory = $config.sourceDirectory
$targetDirectories = $config.targetDirectories

function New-Hardlinks {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$sourcePath,
        
        [Parameter(Mandatory=$true)]
        [string]$targetPath,
        
        [Parameter(Mandatory=$true)]
        [hashtable]$mappings
    )

    $scriptName = [System.IO.Path]::GetFileName($MyInvocation.MyCommand.Path)
    $items = Get-ChildItem -Path $sourcePath -ErrorAction Stop

    foreach ($item in $items) {
        try {
            if ($item.PSIsContainer) {
                if ($mappings.ContainsKey($item.Name) -and $mappings[$item.Name] -eq 'nil') {
                    Write-Verbose "Skipping subdirectory '$($item.FullName)' as per mapping."
                    continue
                }

                $targetSubDirName = if ($mappings.ContainsKey($item.Name)) { $mappings[$item.Name] } else { $item.Name }
                $newTargetPath = Join-Path -Path $targetPath -ChildPath $targetSubDirName

                if (-not (Test-Path -Path $newTargetPath)) {
                    Write-Verbose "Creating directory '$newTargetPath'"
                    New-Item -ItemType Directory -Path $newTargetPath -ErrorAction Stop
                }

                Write-Verbose "Processing subdirectory '$($item.FullName)'"
                New-Hardlinks -sourcePath $item.FullName -targetPath $newTargetPath -mappings $mappings
            } elseif ($item.Name -ne $scriptName -and $item.Extension -ne ".ps1" -and $item.Name -ne "configuration.json") {
                $hardlinkPath = Join-Path -Path $targetPath -ChildPath $item.Name
                if (-not (Test-Path -Path $hardlinkPath)) {
                    Write-Verbose "Creating hardlink from '$($item.FullName)' to '$hardlinkPath'"
                    New-Item -ItemType HardLink -Path $hardlinkPath -Target $item.FullName -ErrorAction Stop
                }
            }
        } catch {
            Write-Error "Failed to create hardlink for item '$($item.FullName)': $_"
        }
    }
}

foreach ($targetDirectory in $targetDirectories) {
    try {
        $targetPath = $targetDirectory.Path
        $mappings = @{}
        foreach ($key in $targetDirectory.Mappings.PSObject.Properties.Name) {
            $mappings[$key] = $targetDirectory.Mappings.$key
        }
        Write-Verbose "Processing target directory '$targetPath'"
        New-Hardlinks -sourcePath $sourceDirectory -targetPath $targetPath -mappings $mappings
    } catch {
        Write-Error "Failed to process target directory '$($targetDirectory.Path)': $_"
    }
}

Write-Output "Hardlinks creation process completed."
