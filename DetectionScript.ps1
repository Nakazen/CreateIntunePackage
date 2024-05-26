# Detection script for Intune
if (-not ((Get-ItemProperty -Path 'HKLM:\Software\TestKey' -Name 'Naam' -ErrorAction SilentlyContinue).Naam -eq 'Waarde')) {
    Write-Host 'Step 1: Registry check failed for HKLM:\Software\TestKey\Naam'
    exit 1
}if (-not ((Get-ItemProperty -Path 'HKLM:\Software\TestKey' -Name 'TestValueSZ' -ErrorAction SilentlyContinue).TestValueSZ -eq 'TestValueSZ')) {
    Write-Host 'Step 2: Registry check failed for HKLM:\Software\TestKey\TestValueSZ'
    exit 1
}if (-not ((Get-ItemProperty -Path 'HKLM:\Software\TestKey' -Name 'TestValueExpandSZ' -ErrorAction SilentlyContinue).TestValueExpandSZ -eq 'TestValueExpandSZ')) {
    Write-Host 'Step 3: Registry check failed for HKLM:\Software\TestKey\TestValueExpandSZ'
    exit 1
}if (-not ((Get-ItemProperty -Path 'HKLM:\Software\TestKey' -Name 'TestValueMultiSZ' -ErrorAction SilentlyContinue).TestValueMultiSZ -eq 'TestValueMultiSZ')) {
    Write-Host 'Step 4: Registry check failed for HKLM:\Software\TestKey\TestValueMultiSZ'
    exit 1
}$actualValue = (Get-ItemProperty -Path 'HKLM:\Software\TestKey' -Name 'TestValueBinary' -ErrorAction SilentlyContinue).TestValueBinary
$expectedValue = [byte[]]@(65,66,67,68)
if ((Compare-Object -ReferenceObject $actualValue -DifferenceObject $expectedValue -SyncWindow 0).Count -ne 0) {
    Write-Host 'Step 5: Registry check failed for HKLM:\Software\TestKey\TestValueBinary'
    exit 1
}if (-not ((Get-ItemProperty -Path 'HKLM:\Software\TestKey' -Name 'TestValueDWORD' -ErrorAction SilentlyContinue).TestValueDWORD -eq '1')) {
    Write-Host 'Step 6: Registry check failed for HKLM:\Software\TestKey\TestValueDWORD'
    exit 1
}if (-not ((Get-ItemProperty -Path 'HKLM:\Software\TestKey' -Name 'TestValueQWORD' -ErrorAction SilentlyContinue).TestValueQWORD -eq '1')) {
    Write-Host 'Step 7: Registry check failed for HKLM:\Software\TestKey\TestValueQWORD'
    exit 1
}if (-not ((Get-ItemProperty -Path 'HKCU:\Software\TestKey2' -Name 'TestValueName2' -ErrorAction SilentlyContinue).TestValueName2 -eq 'TestValue2')) {
    Write-Host 'Step 8: Registry check failed for HKCU:\Software\TestKey2\TestValueName2'
    exit 1
}if (-not (Test-Path -Path 'C:\TestFolder')) {
    Write-Host 'Step 9: File check failed for C:\TestFolder'
    exit 1
}if (-not (Test-Path -Path 'C:\TestFolder\TestFile.txt')) {
    Write-Host 'Step 10: File check failed for C:\TestFolder\TestFile.txt'
    exit 1
}Write-Host 'All checks passed!'
exit 0
