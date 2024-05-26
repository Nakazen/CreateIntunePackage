function Parse-ScriptForChecks {
    param (
        [string]$ScriptPath
    )

    $scriptContent = Get-Content -Path $ScriptPath
    $checkableValues = @{
        RegistryKeys = @()
        Files = @()
    }

    foreach ($line in $scriptContent) {
        if ($line -match "Set-ItemProperty\s+-Path\s+([^\s]+)\s+-Name\s+([^\s]+)\s+-Value\s+([^\s]+)") {
            $registryPath = $matches[1].Trim('"')
            $registryName = $matches[2].Trim('"')
            $registryValue = $matches[3].Trim('"')
            $checkableValues.RegistryKeys += @{Path=$registryPath; Name=$registryName; Value=$registryValue; PropertyType='String'}
        }
        elseif ($line -match "New-ItemProperty\s+-Path\s+([^\s]+)\s+-Name\s+([^\s]+)\s+-Value\s+([^\s]+)\s+-PropertyType\s+([^\s]+)") {
            $registryPath = $matches[1].Trim('"')
            $registryName = $matches[2].Trim('"')
            $registryValue = $matches[3].Trim('"')
            $propertyType = $matches[4].Trim('"')

            if ($propertyType -eq "Binary") {
                $registryValue = $registryValue -replace '[^\d,]', ''
                $registryValue = $registryValue.Split(',') | ForEach-Object { [byte]$_ }
            }
            
            $checkableValues.RegistryKeys += @{Path=$registryPath; Name=$registryName; Value=$registryValue; PropertyType=$propertyType}
        }
        elseif ($line -match "New-Item\s+-ItemType\s+[^\s]+\s+-Path\s+`"([^`"]+)`"") {
            $filePath = $matches[1].Trim('"')
            $checkableValues.Files += $filePath
        }
    }
    return $checkableValues
}

function Generate-DetectionScript {
    param (
        [string]$InputFile,
        [string]$OutputPath = $Params.ScriptDir
    )

    # Use the updated Parse-ScriptForChecks function
    $checkableValues = Parse-ScriptForChecks -ScriptPath $InputFile

    $detectionScriptPath = Join-Path -Path $OutputPath -ChildPath "detection.ps1"

    # Initialize the detection script content
    $detectionScriptContent = @"
# Detection script for Intune

"@

    $step = 1

    # Append check for registry keys
    if ($checkableValues.RegistryKeys) {
        foreach ($reg in $checkableValues.RegistryKeys) {
            if ($reg.PropertyType -eq "Binary") {
                $binaryValue = [string]::Join(',', $reg.Value)
                $detectionScriptContent += @"
`$actualValue = (Get-ItemProperty -Path '$($reg.Path)' -Name '$($reg.Name)' -ErrorAction SilentlyContinue).$($reg.Name)
`$expectedValue = [byte[]]@($binaryValue)
if ((Compare-Object -ReferenceObject `$actualValue -DifferenceObject `$expectedValue -SyncWindow 0).Count -ne 0) {
    Write-Host 'Step ${step}: Registry check failed for $($reg.Path)\$($reg.Name)'
    exit 1
}
"@
            } else {
                $detectionScriptContent += @"
if (-not ((Get-ItemProperty -Path '$($reg.Path)' -Name '$($reg.Name)' -ErrorAction SilentlyContinue).$($reg.Name) -eq '$($reg.Value)')) {
    Write-Host 'Step ${step}: Registry check failed for $($reg.Path)\$($reg.Name)'
    exit 1
}
"@
            }
            $step++
        }
    }

    # Append check for files
    if ($checkableValues.Files) {
        foreach ($file in $checkableValues.Files) {
            $detectionScriptContent += @"
if (-not (Test-Path -Path '$file')) {
    Write-Host 'Step ${step}: File check failed for $file'
    exit 1
}
"@
            $step++
        }
    }

    # Append the final exit code
    $detectionScriptContent += @"
Write-Host 'All checks passed!'
exit 0
"@

    # Write the detection script content to the file
    Set-Content -Path $detectionScriptPath -Value $detectionScriptContent -Force

    # Output the path of the generated script
    Write-Output "Detection script created at: $detectionScriptPath"
    Write-Output ""
}

# Main execution
$inputFile = "C:\Intune\R&D\CreateIntunePackage\CreateIntunePackage\Sample-Detection-script.ps1"

Generate-DetectionScript -InputFile $inputFile -OutputPath $outputPath