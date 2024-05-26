# Test script for Parse-ScriptForChecks

# Testing Registry Key Setting
Set-ItemProperty -Path "HKLM:\Software\TestKey" -Name "Naam" -Value "Waarde"
New-ItemProperty -Path "HKLM:\Software\TestKey" -Name "TestValueSZ" -Value "TestValueSZ" -PropertyType "String" -Force
New-ItemProperty -Path "HKLM:\Software\TestKey" -Name "TestValueExpandSZ" -Value "TestValueExpandSZ" -PropertyType "ExpandString" -Force
New-ItemProperty -Path "HKLM:\Software\TestKey" -Name "TestValueMultiSZ" -Value "TestValueMultiSZ" -PropertyType "MultiString" -Force
New-ItemProperty -Path "HKLM:\Software\TestKey" -Name "TestValueBinary" -Value ([byte[]](65,66,67,68)) -PropertyType "Binary" -Force
New-ItemProperty -Path "HKLM:\Software\TestKey" -Name "TestValueDWORD" -Value 1 -PropertyType "DWord" -Force
New-ItemProperty -Path "HKLM:\Software\TestKey" -Name "TestValueQWORD" -Value 1 -PropertyType "QWord" -Force

# Testing Folder/File Creation
New-Item -ItemType Directory -Path "C:\TestFolder"
New-Item -ItemType File -Path "C:\TestFolder\TestFile.txt"

# Add more dummy data to test parsing
Install-Module -Name Az
Set-ItemProperty -Path "HKCU:\Software\TestKey2" -Name "TestValueName2" -Value "TestValue2"

