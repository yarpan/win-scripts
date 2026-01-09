# --- CONFIGURATION ---
$diskPath = "D:\"
# --------------------

Write-Host "Starting cleanup of healthy segments..." -ForegroundColor Cyan

# 1. Identify and remove healthy files (.bin)
$goodFiles = Get-ChildItem -Path $diskPath -Filter "block_*.bin"

if ($goodFiles.Count -eq 0) {
    Write-Host "No healthy .bin files found." -ForegroundColor Yellow
} else {
    Write-Host "Found $($goodFiles.Count) healthy files. Deleting to free up space..."
    $goodFiles | Remove-Item -Force
    Write-Host "Cleanup successful. Healthy space is now available." -ForegroundColor Green
}

# 2. Protect and hide the bad sector files (.bad)
$badFiles = Get-ChildItem -Path $diskPath -Filter "*.bad"

if ($badFiles.Count -gt 0) {
    Write-Host "--------------------------------------------------"
    Write-Host "Found $($badFiles.Count) bad sector zones. Protecting them..." -ForegroundColor Red
    
    foreach ($file in $badFiles) {
        # Set attributes to Read-Only, Hidden, and System to prevent accidental deletion
        $file.Attributes = 'ReadOnly', 'Hidden', 'System'
        Write-Host "Locked: $($file.Name)" -ForegroundColor Gray
    }
    Write-Host "Bad sectors are now isolated and hidden from normal use." -ForegroundColor Green
} else {
    Write-Host "No bad sectors were isolated during this run." -ForegroundColor Gray
}