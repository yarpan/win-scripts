
# === Load sensitive data from external config ===
$secretsFile = "$PSScriptRoot\secrets.json"
if (!(Test-Path $secretsFile)) {
    Write-Host "Secrets file not found: $secretsFile"
    exit 1
}
$secrets = Get-Content $secretsFile | ConvertFrom-Json

$routerUrl = $secrets.routerUrl
$username = $secrets.username
$password = $secrets.password
$webhook1 = $secrets.webhook1
$webhook2 = $secrets.webhook2
$checkIntervalMinutes = 60
$thresholdGB = $secrets.thresholdGB

# === Authorization header ===
$pair = $username + ':' + $password
$bytes = [System.Text.Encoding]::ASCII.GetBytes($pair)
$encoded = [Convert]::ToBase64String($bytes)
$headers = @{ Authorization = "Basic ${encoded}" }

# === Path to store 00:00 traffic snapshot ===
$baselineFile = "$env:LOCALAPPDATA\RouterTrafficBaseline.json"

# === Function: Fetch current traffic from router ===
function Get-RouterTrafficBytes {
    try {
        $response = Invoke-WebRequest -Uri "$routerUrl/ajax_core.nettraffic_status.asp" -Headers $headers -UseBasicParsing
        $json = $response.Content | ConvertFrom-Json
        return [double]($json.wan_rx + $json.wan_tx)
    } catch {
        Write-Host "Failed to fetch traffic data from router: $_"
        return $null
    }
}

# === Function: Load or initialize baseline traffic value ===
function Load-Or-Init-Baseline {
    if (!(Test-Path $baselineFile)) {
        $traffic = Get-RouterTrafficBytes
        if ($traffic) {
            $obj = @{ timestamp = (Get-Date).Date.ToString("o"); traffic = $traffic }
            $obj | ConvertTo-Json | Out-File $baselineFile
        }
        return $traffic
    } else {
        $data = Get-Content $baselineFile | ConvertFrom-Json
        return $data.traffic
    }
}

# === Main logic ===
$baseline = Load-Or-Init-Baseline
$current = Get-RouterTrafficBytes

if ($current -and $baseline) {
    $deltaBytes = $current - $baseline
    $deltaGB = [math]::Round($deltaBytes / 1GB, 2)

    Write-Host "Current daily usage: $deltaGB GB"

    # Always send hourly update to webhook1
    $updateJson = @{usage=$deltaGB; threshold=$thresholdGB} | ConvertTo-Json -Compress
    $updateCommand = "curl -X POST `"$webhook1`" -H `"Content-Type: application/json`" -d '$updateJson'"
    Invoke-Expression $updateCommand

    if ($deltaGB -gt $thresholdGB) {
        Write-Host "Threshold of $thresholdGB GB exceeded. Sending alert."

        $alertJson = @{alert="threshold_exceeded"; usage=$deltaGB; threshold=$thresholdGB} | ConvertTo-Json -Compress
        $alertCommand = "curl -X POST `"$webhook2`" -H `"Content-Type: application/json`" -d '$alertJson'"
        Invoke-Expression $alertCommand
    }
}

# === Update baseline at midnight ===
$now = Get-Date
if ($now.Hour -eq 0 -and $now.Minute -lt 5) {
    $obj = @{ timestamp = $now.ToString("o"); traffic = $current }
    $obj | ConvertTo-Json | Out-File $baselineFile
    Write-Host "Baseline reset for new day"
}
