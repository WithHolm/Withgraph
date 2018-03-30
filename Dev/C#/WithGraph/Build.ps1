param(
	$TargetFile
	)

#[void][Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
#[void][System.Windows.Forms.MessageBox]::Show("It works.")
#[Console]::Beep(600, 800)
$start = Get-ChildItem -Filter $TargetFile|select -First 1|select -ExpandProperty fullname
Start-Process powershell -ArgumentList "-noexit","-command import-module .\$targetfile -verbose"

#Write-Host $TargetFile
#set-content $target -Value $config -Force