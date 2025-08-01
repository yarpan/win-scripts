$scriptPath = "C:\Scripts\check_router_traffic.ps1"
$taskName = "CheckRouterTrafficHourly"
$taskDescription = "Checks router traffic every hour and sends alerts if threshold is exceeded"


$trigger = New-ScheduledTaskTrigger -Hourly -At (Get-Date).Date.AddHours(1)


$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"$scriptPath`""


$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable


Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Description $taskDescription -Settings $settings -User "$env:USERNAME" -RunLevel Highest -Force
