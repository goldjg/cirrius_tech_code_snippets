#requires -Modules ScheduledTasks
#requires -Version 3.0
#requires -RunAsAdministrator

$TaskName = 'MyDynerUpdate'
$User= "<user>"
$NowDT = Get-Date
$RepeatSpan = New-TimeSpan -Minutes 5

$Trigger= New-ScheduledTaskTrigger -At $NowDT -Once -RepetitionInterval $RepeatSpan
$Action= New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-WindowStyle Hidden -executionpolicy bypass -noprofile -command ""Invoke-RestMethod -Method Post -Uri 'https://<app_name>.azurewebsites.net/api/<function_name>?code=<function_key>&name=<a_rec_name>&zone=<dns_zone>'"""
Register-ScheduledTask -TaskName $TaskName -Trigger $Trigger -User $User -Action $Action -RunLevel Highest -Force