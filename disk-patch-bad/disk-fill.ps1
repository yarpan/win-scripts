# --- CONFIGURATION ---
$diskPath = "D:\"             # Target drive letter
$targetFiles = 4650           # Approx number of 1GB files for a 5TB drive
$fileSizeGB = 1               # Size of each block
$blockSize = 64MB             # Write buffer size (64MB is stable for failing drives)
# --------------------

$totalBytes = [int64]$fileSizeGB * 1GB
$buffer = New-Object Byte[] $blockSize
$logFile = Join-Path $diskPath "disk_scan_log.txt"

Write-Host "Starting Disk Isolation Process on $diskPath" -ForegroundColor Cyan

for ($i = 1; $i -le $targetFiles; $i++) {
    $fileName = Join-Path $diskPath "block_$i.bin"
    
    # Skip if file already exists (allows resuming after a crash/reboot)
    if (Test-Path $fileName) {
        Write-Host "File $i exists, skipping..." -ForegroundColor Gray
        continue
    }

    Write-Host "Writing file $i of $targetFiles ($fileName)... " -NoNewline
    
    try {
        $stream = [System.IO.File]::Create($fileName)
        $bytesWritten = 0
        
        # Physically writing data to the disk surface
        while ($bytesWritten -lt $totalBytes) {
            $stream.Write($buffer, 0, $buffer.Length)
            $bytesWritten += $buffer.Length
        }
        
        $stream.Close()
        $stream.Dispose()
        Write-Host "[OK]" -ForegroundColor Green
        
        # Log successful write
        Add-Content -Path $logFile -Value "$(Get-Date): Block $i written successfully."
    }
    catch {
        Write-Host "[FAILED]" -ForegroundColor Red
        Add-Content -Path $logFile -Value "$(Get-Date): !!! ERROR AT BLOCK $i !!!"
        
        if ($null -ne $stream) { $stream.Close(); $stream.Dispose() }
        
        # DO NOT delete the failed file. Rename it to isolate the bad sector.
        $badFileName = Join-Path $diskPath "BAD_ZONE_$i.bad"
        Rename-Item -Path $fileName -NewName $badFileName -ErrorAction SilentlyContinue
        
        Write-Host "Physical sector isolated in $badFileName" -ForegroundColor Yellow
        continue
    }
}
Write-Host "Process Complete!" -ForegroundColor Cyan