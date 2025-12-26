$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$ConfigPath = Join-Path $ScriptRoot "browsers.json"
$LogFile = Join-Path $ScriptRoot "log.txt"

function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )

    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$ts [$Level] $Message" | Out-File -Append $LogFile -Encoding UTF8
}

Write-Log "=== Cache cleanup started ==="

$browsers = Get-Content $ConfigPath -Raw | ConvertFrom-Json

foreach ($browser in $browsers) {

    $root = [Environment]::ExpandEnvironmentVariables($browser.profileRoot)

    if (-not (Test-Path $root)) {
        Write-Log "Browser not found: $($browser.name)"
        continue
    }

    Write-Log "Browser detected: $($browser.name)"

    # Stop browser process (safe)
    Get-Process -Name $browser.process -ErrorAction SilentlyContinue |
    Stop-Process -Force -ErrorAction SilentlyContinue

    # === Chromium-based browsers ===
    if ($browser.name -notmatch "Firefox") {

        Get-ChildItem $root -Directory -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -match "^(Default|Profile \d+)$" } |
        ForEach-Object {

            $profile = $_.FullName
            Write-Log "Profile detected: $($_.Name)"

            foreach ($cacheDir in @("Cache", "Code Cache", "GPUCache")) {
                $path = Join-Path $profile $cacheDir

                if (Test-Path $path) {
                    Remove-Item "$path\*" -Recurse -Force -ErrorAction SilentlyContinue
                    Write-Log "Cleared: $path"
                }
            }
        }
    }

    # === Firefox + Firefox Developer Edition ===
    else {
        $profilesIni = Join-Path $root "profiles.ini"

        if (-not (Test-Path $profilesIni)) {
            Write-Log "profiles.ini not found (Firefox)"
            continue
        }

        $ini = Get-Content $profilesIni -ErrorAction SilentlyContinue

        $profilePaths = $ini |
        Where-Object { $_ -match "^Path=" } |
        ForEach-Object {
            $p = ($_ -replace "^Path=", "")
            Join-Path $root $p
        }

        foreach ($profile in $profilePaths) {
            $cachePath = Join-Path $profile "cache2"

            if (Test-Path $cachePath) {
                Remove-Item "$cachePath\*" -Recurse -Force -ErrorAction SilentlyContinue
                Write-Log "Cleared Firefox cache: $cachePath"
            }
        }
    }
}

Write-Log "=== Cache cleanup finished ==="
