param([string]$EvidenceName='native-current')
$adb="$env:LOCALAPPDATA\Android\sdk\platform-tools\adb.exe"
$dumpResult = & $adb -s emulator-5554 shell uiautomator dump /sdcard/acceptance.xml 2>&1
if(($dumpResult -join " ") -notmatch "dumped to") { throw "Native UI tree unavailable; previous XML is not current evidence." }
& $adb -s emulator-5554 pull /sdcard/acceptance.xml .validation/environment/emulator-ui.xml 2>$null | Out-Null
[xml]$tree=Get-Content .validation/environment/emulator-ui.xml
$tree.SelectNodes('//node') | Where-Object { $_.text -or $_.'content-desc' -or $_.class -match 'EditText' } | ForEach-Object { ((@($_.text,$_.'content-desc',$_.bounds) -join ' ') -replace '\b\d{6}\b','[OTP REDACTED]') } | Tee-Object "artifacts/live-retry/$EvidenceName.txt"

