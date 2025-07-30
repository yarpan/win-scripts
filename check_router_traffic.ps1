# === Configuration ===
$routerUrl = "http://192.168.1.1"     # Router address
$username = "admin"                  # Router username
$password = "admin"                  # Router password
$thresholdGB = 100                   # Daily usage threshold in GB
$alertUrl = "https://example.com/alert"  # URL to notify when limit exceeded

# === Authorization header ===
$pair = "$username:$password"
$bytes = [System.Text.Encoding]::ASCII.GetBytes($pair)
$encoded = [Convert]::ToBase64String($bytes)
$headers = @{ Authorization = "Basic $encoded" }

# === Path to store 00:00 traffic snapshot ===
$baselineFile = "$env:LOCALAPPDATA\\RouterTrafficBaseline.json"

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

    if ($deltaGB -gt $thresholdGB) {
        Write-Host "Threshold of $thresholdGB GB exceeded"
        Invoke-RestMethod -Uri $alertUrl -Method Post -Body @{ usage = $deltaGB; threshold = $thresholdGB }
    }
}

# === Update baseline at midnight ===
$now = Get-Date
if ($now.Hour -eq 0 -and $now.Minute -lt 5) {
    $obj = @{ timestamp = $now.ToString("o"); traffic = $current }
    $obj | ConvertTo-Json | Out-File $baselineFile
    Write-Host "Baseline reset for new day"
}
