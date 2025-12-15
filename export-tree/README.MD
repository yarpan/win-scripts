# Export-TreeCsv.ps1

A PowerShell script that exports a directory tree structure of files and folders to CSV format.

## Overview

This script recursively traverses a directory and generates a CSV file containing a tree-like visualization of the file system structure. Tree branches are drawn using Unicode characters (│, ├──, └──) in the `Tree` column, with additional metadata columns for file properties.

## Features

- **Tree Visualization**: Displays directory hierarchy with visual branch characters (Unicode or ASCII)
- **Flexible Depth Control**: Limit recursion depth with the `-MaxDepth` parameter
- **Hidden & System Files**: Optional inclusion of hidden and system files
- **Comprehensive Metadata**: Exports file/folder information including:
  - **Tree**: Visual tree representation with branch characters
  - **Type**: "Dir" for directories, "File" for files
  - **Name**: File or folder name
  - **Extension**: File extension (empty for directories)
  - **SizeBytes**: File size in bytes (null for directories)
  - **LastWriteTime**: Last modified timestamp
  - **Attributes**: File system attributes
  - **FullPath**: Complete file path
  - **Depth**: Directory nesting level (0 = root)
  - **ParentPath**: Parent directory path

## Usage

### Basic Syntax

```powershell
.\Export-TreeCsv.ps1 -Path <source_path> -OutFile <output_file> [options]
```

### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `-Path` | string | "." | Source directory path to scan |
| `-OutFile` | string | ".\tree.csv" | Output CSV file path |
| `-MaxDepth` | int | -1 | Maximum nesting depth (-1 = unlimited, 0 = root only) |
| `-IncludeHidden` | switch | false | Include hidden files/folders |
| `-IncludeSystem` | switch | false | Include system files/folders |
| `-Ascii` | switch | false | Use ASCII characters instead of Unicode for tree branches |

## Examples

### Full directory tree of C: drive
```powershell
.\Export-TreeCsv.ps1 -Path "C:\" -OutFile ".\tree.csv"
```

### Same with ASCII tree characters (for Unicode compatibility issues)
```powershell
.\Export-TreeCsv.ps1 -Path "D:\" -OutFile ".\tree_ascii.csv" -Ascii
```

### Limited depth to 2 levels
```powershell
.\Export-TreeCsv.ps1 -Path "C:\Projects" -OutFile ".\projects_top2.csv" -MaxDepth 2
```

### Include hidden and system files
```powershell
.\Export-TreeCsv.ps1 -Path "C:\" -OutFile ".\full_tree.csv" -IncludeHidden -IncludeSystem
```

### Current directory with all options
```powershell
.\Export-TreeCsv.ps1 -MaxDepth 3 -IncludeHidden -Ascii -OutFile ".\detailed_tree.csv"
```

## Output Example

CSV content visualization:

```
Tree                    Type    Name            Extension   SizeBytes   LastWriteTime           FullPath                Depth   ParentPath
.                       Dir     C:\             ""          (null)      12/15/2025 10:30:00 AM  C:\                     0       
├── Program Files       Dir     Program Files   ""          (null)      12/15/2025 10:30:00 AM  C:\Program Files        1       C:\
│   ├── Common Files    Dir     Common Files    ""          (null)      12/15/2025 10:30:00 AM  C:\Program Files\...    2       C:\Program Files
│   └── SomeApp         Dir     SomeApp         ""          (null)      12/15/2025 10:30:00 AM  C:\Program Files\...    2       C:\Program Files
└── Users               Dir     Users           ""          (null)      12/15/2025 10:30:00 AM  C:\Users                1       C:\
    ├── Public          Dir     Public          ""          (null)      12/15/2025 10:30:00 AM  C:\Users\Public         2       C:\Users
    └── Private         Dir     Private         ""          (null)      12/15/2025 10:30:00 AM  C:\Users\Private        2       C:\Users
```

## How It Works

1. **Path Validation**: Resolves and validates the input path
2. **Recursive Traversal**: Uses the `_Walk` function to recursively process directories
3. **Filtering**: Applies include/exclude rules based on `-IncludeHidden` and `-IncludeSystem` flags
4. **Tree Building**: Constructs visual tree prefixes using the `_BuildPrefix` function
5. **Data Collection**: Gathers file metadata and stores in memory
6. **CSV Export**: Exports all collected data to CSV with UTF-8 encoding

## Key Functions

- **`_ShouldIncludeItem`**: Filters items based on Hidden/System attributes
- **`_GetChildren`**: Retrieves and sorts child items (directories first, then files)
- **`_BuildPrefix`**: Generates tree branch characters (│, ├──, └──, etc.)
- **`_Walk`**: Main recursive function that traverses the directory tree

## Notes

- **Sorting**: Directories are listed first, then files, both sorted alphabetically
- **Depth Counter**: The depth counter starts at 0 for the root directory
- **Error Handling**: Inaccessible folders are skipped with an empty child list
- **Unicode Support**: Use `-Ascii` parameter if your CSV editor has Unicode rendering issues
- **Performance**: Large directory trees may take time to process; consider using `-MaxDepth` to limit scope

## Output File Format

- **Encoding**: UTF-8
- **Delimiter**: Comma (,)
- **Headers**: Yes (column names included)
- **Quote Type**: Double quotes for fields containing special characters