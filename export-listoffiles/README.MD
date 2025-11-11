```markdown
# PowerShell File Tree Scanner

##  Overview
This PowerShell script scans the **entire current drive** (where the script is executed) and generates a detailed **CSV file** containing information about all files and folders.  
It automatically skips common **system directories** to avoid access issues and irrelevant data.

The output is saved as:
```
file_tree.csv
```
in the **root directory of the current drive** (e.g., `C:\file_tree.csv`).

---

##  Features
- Automatically detects the current drive.
- Recursively scans all folders and files.
- Excludes system and protected directories.
- Handles **access-denied** folders gracefully.
- Exports results to **UTF-8 CSV** format for compatibility.
- Includes metadata for each item:
  - Full path  
  - File or folder name  
  - Type (`File` / `Folder`)  
  - Extension (for files)  
  - Size (in KB)  
  - Creation time  
  - Last access time  

---

##  Example Output
| FullPath | Name | Type | Extension | SizeKB | CreationTime | LastAccessTime |
|-----------|------|------|------------|--------|----------------|----------------|
| C:\Users\John\Documents\report.docx | report.docx | File | .docx | 512.34 | 2024-03-14 10:42 | 2024-11-10 18:05 |
| C:\Users\John\Pictures | Pictures | Folder |  | 0 | 2023-07-21 09:10 | 2025-01-05 16:22 |

---

##  Excluded Folders
The script automatically skips the following system folders:
- `System Volume Information`
- `Program Files`
- `Program Files (x86)`
- `Windows`
- `Recovery`
- `$RECYCLE.BIN`

You can add more by editing the `$excludedFolders` array.

---

##  How It Works
1. Detects the current drive using:
   \`\`\`powershell
   $currentDrive = (Get-Location).Drive.Name
   \`\`\`
2. Sets the output path to:
   \`\`\`
   {drive}:\file_tree.csv
   \`\`\`
3. Recursively scans folders via the `Get-FolderTree` function.
4. Collects file information in a dynamic `ArrayList`.
5. Exports all results to CSV:
   \`\`\`powershell
   $fileList | Export-Csv -Path $outputCsv -NoTypeInformation -Encoding UTF8
   \`\`\`

---

## ▶️ Usage

### Option 1 — Run from PowerShell Console
1. Save the script as `scan_drive.ps1`.
2. Open **PowerShell as Administrator**.
3. Navigate to the directory containing the script.
4. Run:
   \`\`\`powershell
   .\scan_drive.ps1
   \`\`\`
5. Wait until the message appears:
   \`\`\`
   Scan complete! File tree saved to: C:\file_tree.csv
   \`\`\`

### Option 2 — Run Directly from Command Line
\`\`\`powershell
powershell -ExecutionPolicy Bypass -File "D:\path\to\scan_drive.ps1"
\`\`\`

---

##  Customization
You can modify:
- **Excluded folders** — edit `$excludedFolders`.
- **Output file name or location** — change `$outputCsv`.
- **Scanned drive** — modify `$rootDirectory`.

---

##  Requirements
- Windows PowerShell 5.1 or newer  
- Administrator privileges recommended  
- Enough access rights to read all non-system folders

---

##  Output Location
| Example | Output File |
|----------|--------------|
| Running on `C:` | `C:\file_tree.csv` |
| Running on `D:` | `D:\file_tree.csv` |

---

##  Example Completion Message
\`\`\`
Scanning directory: C:\
Skipping excluded folder: C:\Windows
Skipping excluded folder: C:\Program Files
Scan complete! File tree saved to: C:\file_tree.csv
\`\`\`

---

