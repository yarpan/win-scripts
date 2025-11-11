# Get the current drive letter where the script is being executed (ensure it's just the drive letter)
$currentDrive = (Get-Location).Drive.Name

# Automatically define the output CSV file path on the root of the current drive
$outputCsv = Join-Path -Path "${currentDrive}:\" -ChildPath "file_tree.csv"

# Initialize an ArrayList to store file details (ArrayList allows dynamic additions)
$fileList = New-Object System.Collections.ArrayList

# List of system folders to exclude (you can add more as needed)
$excludedFolders = @(
    "System Volume Information",
    "Program Files",
    "Program Files (x86)",
    "Windows",
    "Recovery",
    "$RECYCLE.BIN"
)

# Function to recursively scan a directory, excluding system folders
function Get-FolderTree {
    param (
        [string]$folderPath
    )

    # Skip system folders based on exclusion list
    foreach ($excludedFolder in $excludedFolders) {
        if ($folderPath -match "\\$excludedFolder\\") {
            Write-Host "Skipping excluded folder: $folderPath"
            return
        }
    }

    try {
        # Try to get all files and directories in the current folder (including subfolders)
        $items = Get-ChildItem -Path $folderPath -Recurse -Force -ErrorAction SilentlyContinue

        foreach ($item in $items) {
            # Skip directories that can't be accessed (access denied)
            if ($item.PSIsContainer -and !(Test-Path $item.FullName)) {
                continue
            }

            # Create a new PSObject for the file/folder and add it to the ArrayList
            $itemInfo = New-Object PSObject -property @{
                'FullPath'     = $item.FullName
                'Name'         = $item.Name
                'Type'         = if ($item.PSIsContainer) { 'Folder' } else { 'File' }
                'Extension'    = if ($item.PSIsContainer) { '' } else { $item.Extension }
                'SizeKB'       = if ($item.PSIsContainer) { 0 } else { [math]::round($item.Length / 1KB, 2) }
                'CreationTime' = $item.CreationTime
                'LastAccessTime' = $item.LastAccessTime
            }

            # Add the item to the ArrayList
            [void]$fileList.Add($itemInfo)
        }
    } catch {
        Write-Host "Error accessing folder: $folderPath"
        Write-Host $_.Exception.Message -ForegroundColor Red
    }
}

# Function to handle initial folder access
function Scan-Drive {
    param (
        [string]$drivePath
    )

    # Check if the root directory is accessible before attempting to scan
    if (Test-Path $drivePath) {
        Write-Host "Scanning directory: $drivePath"
        Get-FolderTree -folderPath $drivePath
    } else {
        Write-Host "Access denied or root folder not accessible: $drivePath" -ForegroundColor Red
    }
}

# Scan the root of the current drive
$rootDirectory = "${currentDrive}:\" 

# Start scanning from the root directory of the current drive
Scan-Drive -drivePath $rootDirectory

# Export the file list to a CSV with UTF8 encoding to handle non-ASCII characters
$fileList | Export-Csv -Path $outputCsv -NoTypeInformation -Encoding UTF8

Write-Host "Scan complete! File tree saved to: $outputCsv"
