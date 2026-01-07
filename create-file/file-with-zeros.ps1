$path = "$HOME\Desktop\testfile_zeros.dat"
$sizeInBytes = 1GB

$stream = [System.IO.File]::Create($path)
$stream.SetLength($sizeInBytes)
$stream.Close()

Write-Host "One gigabyte file with zeros has been successfully generated."