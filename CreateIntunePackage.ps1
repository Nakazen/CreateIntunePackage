<#
.SYNOPSIS
This PowerShell script is used to set up utilities and tools for creating Intune packages. It checks for the existence of certain utilities and downloads them if they are not found. The script is designed to be used in a test environment.

.PARAMETERS
The script uses a hashtable `$Params` to store paths to various utilities and directories. These include:

- `IntuneWinAppUtil`: Path to the Intune Windows App Utility.
- `ConvertExe`: Path to the ImageMagick convert utility.
- `ExtractIcon`: Path to the ExtractIcon utility.
- `TempMsiExtract`: Path to the temporary directory for MSI extraction.
- `OutputFolder`: Path to the output directory.
- `IconOutput`: Path to the directory for storing icons.
- `ScriptDir`: Directory of the current script.
- `FolderName`: Name of the folder containing the current script.
- `CurrentScriptName`: Name of the current script.

.FUNCTIONS
The script defines several functions:

- `SetupUtilities`: This function checks if a utility exists at the specified path. If not, it prompts the user to download and set up the utility. The function takes three parameters: `utilityPath`, `downloadUrl`, `targetFolder`.

- `SetupTools`: This function checks if a utility exists at the specified path. If not, it attempts to set up the utility using the `SetupUtilities` function. If the setup fails, it prompts the user to manually download and place the utility at the specified path. The function takes three parameters: `UtilityPath`, `DownloadUrl`, `TargetFolder`.

- `CreateIntunePackage`: This function creates an Intune package using the Intune Windows App Utility. It takes several parameters including the source folder, setup file, output folder, and others.

- `ExtractIconFromExe`: This function extracts an icon from an executable file using the ExtractIcon utility. It takes two parameters: the path to the executable file and the output path for the icon.

- `ConvertIconToPng`: This function converts an icon file to a PNG image using the ImageMagick convert utility. It takes two parameters: the path to the icon file and the output path for the PNG image.

.USAGE
Run the script in a PowerShell console. If any of the utilities are missing, the script will prompt you to download and set up the utilities. If the automatic setup fails, you will be prompted to manually download and place the utility at the specified path.
#>

# ExtractIcon.exe:
# https://github.com/bertjohnson/ExtractIcon
#
# ImageMagick - Portable version - Only need convert.exe
# https://imagemagick.org/script/download.php#windows

# Settable parameters

# User settable variables
$Params = @{
    'IntuneWinAppUtil' = "C:\Intune\IntuneWinAppUtil.exe"
    'ConvertExe'       = "C:\Intune\Tools\ImageMagick\convert.exe"
    'ExtractIcon'      = "C:\Intune\Tools\Extracticon\extracticon.exe"
    'TempMsiExtract'   = "C:\Temp\msi_extraction\"
    'OutputFolder'     = "C:\Intune\Output"
    'IconOutput'       = "C:\Intune\Logos"
}

# Non-user settable variables
$Params += @{
    'ScriptDir'        = Split-Path -Parent $MyInvocation.MyCommand.Definition
    'FolderName'       = Split-Path -Parent $MyInvocation.MyCommand.Path | Split-Path -Leaf
    'CurrentScriptName'= $MyInvocation.MyCommand.Name
}


function SetupUtilities {
    param (
        [string]$utilityPath,
        [string]$downloadUrl,
        [string]$targetFolder
    )

    # Check if the utility exists
    if (-not (Test-Path $utilityPath)) {
        # Create target folder if it does not exist
        if (-not (Test-Path $targetFolder)) {
            New-Item -Path $targetFolder -ItemType Directory | Out-Null
        }

        # Prompt user for download permission
        $userConsent = Read-Host "The utility at '$utilityPath' is missing. Do you want to download and setup this utility? (Y/N)"
        if ($userConsent -eq 'Y') {
            # Download the file
            Write-Output "Downloading $utilityPath..."
            $webClient = New-Object System.Net.WebClient
            $webClient.DownloadFile($downloadUrl, $utilityPath)
            Write-Output "Download completed and utility placed at: $utilityPath"
        } else {
            Write-Output "Setup aborted by the user."
            return $false
        }
    }
    return $true
}

function SetupTools {
    param (
        [string]$UtilityPath,
        [string]$DownloadUrl,
        [string]$TargetFolder
    )

    if (-not (Test-Path $UtilityPath)) {
        Write-Output "Error: Utility not found at: $UtilityPath"
        $checkUtility = SetupUtilities -utilityPath $UtilityPath -downloadUrl $DownloadUrl -targetFolder $TargetFolder
        if (-not $checkUtility) {
            Write-Output "Setup of $UtilityPath is required for the script to continue, but the automatic setup has failed. Please download it manually and place it at the specified path."
            Write-Output "You can download the file from: $DownloadUrl"
            Read-Host "Press Enter to continue..."
            while (-not (Test-Path $UtilityPath)) {
                Write-Output "$UtilityPath not found at the specified path. Please download it manually and place it at the specified path."
                Read-Host "Press Enter to continue..."
            }
        }
    }
}

function DisplayFilesAndPromptChoice($path, $extensions) {
    $files = Get-ChildItem -Path $path -File | Where-Object { $_.Extension -match $extensions }

    # Check if files are found
    if (-not $files) {
        Write-Host "No matching files found in the directory."
        exit
    }

    # Display files for user to choose using Write-Host
    $index = 1
    $files | ForEach-Object {
        Write-Host "$index. $($_.Name)"
        $index++
    }

    $choice = Read-Host "Enter the number of the file"
    while ($choice -lt 1 -or $choice -gt $files.Count) {
        Write-Host "Invalid choice. Please choose a valid file number."
        $choice = Read-Host "Enter the number of the file"
    }
    
    return $files[$choice - 1]
}
function ExtractIconFromExecutableOrMSI {
    $selectedFile = DisplayFilesAndPromptChoice $Params.ScriptDir ".(exe|msi)$"
    
    # If MSI, extract contents and allow user to choose .exe
    if ($selectedFile.Extension -eq ".msi") {
        $processedMsi = $true
        $msiexecArgs = "/a `"$($selectedFile.FullName)`" /qb TARGETDIR=`"$($Params.TempMsiExtract)`""
        Start-Process -FilePath "msiexec.exe" -ArgumentList $msiexecArgs -Wait
        
        $exeFilesInMsi = Get-ChildItem -Path $Params.TempMsiExtract -Recurse | Where-Object { $_.Extension -eq ".exe" }
        $exeFilesDirectory = Join-Path $Params.TempMsiExtract "ExeFiles"
        if (-not (Test-Path $exeFilesDirectory)) { 
            New-Item -Path $exeFilesDirectory -ItemType Directory -Force | Out-Null 
        }

        # Move files with handling for name collisions
        $exeFilesInMsi | ForEach-Object {
            $destinationPath = Join-Path $exeFilesDirectory $_.Name
            $uniqueId = 1
            while (Test-Path $destinationPath) {
                $destinationPath = Join-Path $exeFilesDirectory ("$($_.BaseName)_$uniqueId$($_.Extension)")
                $uniqueId++
            }
            Move-Item -Path $_.FullName -Destination $destinationPath
        }
        
        # Start Explorer
        Start-Process explorer.exe -ArgumentList $exeFilesDirectory
        $selectedFile = DisplayFilesAndPromptChoice $exeFilesDirectory ".exe$"
    }
    
    # Extract Icon
    $tempOutputPngPath = Join-Path $Params.ScriptDir "temp_icon.png"
    Start-Process "$($Params.ExtractIcon)" -ArgumentList "`"$($selectedFile.FullName)`" `"$tempOutputPngPath`"" -Wait

    # Rename and move operations for the .png and .ico files
    $tempOutputPngPath = Join-Path $Params.ScriptDir "temp_icon.png"
    $finalPngPath = Join-Path $Params.ScriptDir "$($Params.FolderName).png"

    # Check if a file with the desired name already exists and remove it
    if (Test-Path $finalPngPath) {
        Remove-Item -Path $finalPngPath -Force
    }

    # Rename the PNG to match the folder name
    Rename-Item -Path $tempOutputPngPath -NewName "$($Params.FolderName).png"

    # Move the extracted icon to the specified IconOutputFolder
    if (-not (Test-Path $Params.IconOutput)) {
        New-Item -Path $Params.IconOutput -ItemType Directory -Force | Out-Null
    }
    Copy-Item -Path (Join-Path $Params.ScriptDir "$($Params.FolderName).png") -Destination $Params.IconOutput -Force

    # Similar adjustments for the .ico file
    $pngFilePath = Join-Path $Params.ScriptDir "$($Params.FolderName).png"
    $icoOutputPath = Join-Path $Params.ScriptDir "$($Params.FolderName).ico"
    $ConvertExeLocation = $Params.ConvertExe
    Start-Process "$ConvertExeLocation" -ArgumentList "`"$pngFilePath`" -define icon:auto-resize=256,128,48,32,16 `"$icoOutputPath`"" -Wait


    # Remove the dedicated directory containing the .exe files
    if ($processedMsi -and (Test-Path $exeFilesDirectory)) {
        Remove-Item -Path $exeFilesDirectory -Recurse -Force
    }

    # Remove the temporary .png file
    if (Test-Path $pngFilePath) {
        Remove-Item -Path $pngFilePath -Force
    }

    # Clean up the temp MSI extraction directory
    $msiExtractionPath = $Params.TempMsiExtract
    if (Test-Path $msiExtractionPath) {
        Write-Output "Cleaning up MSI extraction directory..."
        Remove-Item -Path $msiExtractionPath -Recurse -Force
        Write-Output "MSI extraction directory cleaned up."
    }

        # Inform the user
        Write-Output "Icon extracted, renamed to $($Params.FolderName).png, and moved to $($Params.IconOutput)."
        Write-Output "PNG file converted to ICO and saved as $($Params.FolderName).ico."
        Write-Output "Temporary files have been cleaned up."
}
function GenerateIntuneWinPackages {
    $selectedFile = DisplayFilesAndPromptChoice $Params.ScriptDir ".(ps1|exe|bat|cmd|msi)$"
    
    $tempOutput = "$env:TEMP\IntuneOutput"
    if (-not (Test-Path $tempOutput)) {
        New-Item -Path $tempOutput -ItemType Directory -Force | Out-Null
    }

    & $Params.IntuneWinAppUtil -c "$($Params.ScriptDir)" -s "$($selectedFile.Name)" -o "$tempOutput"

    # Rename and move the output file
    $originalOutputFile = Get-ChildItem -Path $tempOutput -Filter *.intunewin
    Rename-Item -Path $originalOutputFile.FullName -NewName "$($Params.FolderName).intunewin"
    Move-Item -Path "$tempOutput\$($Params.FolderName).intunewin" -Destination "$($Params.OutputFolder)" -Force

    if ($selectedFile.Extension -eq ".ps1") {
        $baseName = [System.IO.Path]::GetFileNameWithoutExtension($selectedFile.Name)
        $logFileName = "$baseName.txt"
        $installCommand = "Powershell.exe -NoProfile -ExecutionPolicy ByPass -Command ""& { md C:\IT\logs -ErrorAction SilentlyContinue; .\$($selectedFile.Name) -Verbose *> C:\IT\logs\$logFileName }"""
    
        # Search for uninstall scripts
        $uninstallScript = Get-ChildItem -Path $Params.ScriptDir -Filter "*.ps1" | Where-Object {
            $_.Name -like "uninstall*" -or $_.Name -like "Undeploy*"
        } | Select-Object -First 1
    
        if ($null -eq $uninstallScript) {
            Write-Output "No specific uninstall script found, using install script for uninstall."
            $uninstallCommand = $installCommand
        } else {
            $uninstallLogFileName = "$($uninstallScript.BaseName).txt"
            $uninstallCommand = "Powershell.exe -NoProfile -ExecutionPolicy ByPass -Command ""& { md C:\IT\logs -ErrorAction SilentlyContinue; .\$($uninstallScript.Name) -Verbose *> C:\IT\logs\$uninstallLogFileName }"""
        }
    
        $commandText = 
@"
Install command:

$installCommand

Uninstall command:

$uninstallCommand
"@
        $commandsFilePath = Join-Path $Params.ScriptDir "Install_Uninstall_Commands.txt"
        $commandText | Out-File $commandsFilePath -Force
        Write-Output "Commands file created at: $commandsFilePath"
    }
    # Cleanup temporary folder
    Remove-Item -Path $tempOutput -Recurse -Force
}

# Script logic
# Check Utility Existence
SetupTools -UtilityPath $Params.ConvertExe -DownloadUrl "https://github.com/Nakazen/CreateIntunePackage/raw/main/Tools/convert.exe" -TargetFolder (Split-Path $Params.ConvertExe)
SetupTools -UtilityPath $Params.IntuneWinAppUtil -DownloadUrl "https://github.com/microsoft/Microsoft-Win32-Content-Prep-Tool/raw/v1.8.6/IntuneWinAppUtil.exe" -TargetFolder (Split-Path $Params.IntuneWinAppUtil)
SetupTools -UtilityPath $Params.ExtractIcon -DownloadUrl "https://github.com/Nakazen/CreateIntunePackage/raw/main/Tools/extracticon.exe" -TargetFolder (Split-Path $Params.ExtractIcon)

# Icon extraction
if ((Read-Host "Extract icon from executable or MSI? (Y/N)") -eq 'Y') {
    ExtractIconFromExecutableOrMSI
}

# Generate IntuneWin Packages
GenerateIntuneWinPackages

# Inform user
Read-Host "Press Enter to continue..."