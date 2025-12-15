# export-tree.sh - Linux/Unix Version

A Bash shell script that exports a directory tree structure to CSV format. This is the Linux/Unix equivalent of the PowerShell `Export-TreeCsv.ps1` script.

## Overview

This script recursively traverses a directory and generates a CSV file containing a tree-like visualization of the file system structure. Tree branches are drawn using Unicode characters (│, ├──, └──) in the `Tree` column, with additional metadata columns for file properties.

## Requirements

- Bash 4.0+
- Standard Unix utilities: `find`, `stat`, `sort`, `mktemp`
- No external dependencies beyond POSIX tools

## Features

- **Tree Visualization**: Displays directory hierarchy with visual branch characters (Unicode or ASCII)
- **Flexible Depth Control**: Limit recursion depth with the `--max-depth` parameter
- **Hidden Files**: Optional inclusion of files starting with `.`
- **Comprehensive Metadata**: Exports file/folder information including:
  - **Tree**: Visual tree representation with branch characters
  - **Type**: "Dir" for directories, "File" for files
  - **Name**: File or folder name
  - **Extension**: File extension (empty for directories and files without extension)
  - **SizeBytes**: File size in bytes (empty for directories)
  - **LastWriteTime**: Last modified timestamp
  - **Attributes**: File permissions (rwx format)
  - **FullPath**: Absolute file path
  - **Depth**: Directory nesting level (0 = root)
  - **ParentPath**: Parent directory path (empty for root)

## Installation

```bash
# Make the script executable
chmod +x export-tree.sh

# Optional: Copy to a directory in your PATH for global access
sudo cp export-tree.sh /usr/local/bin/export-tree
```

## Usage

### Basic Syntax

```bash
./export-tree.sh --path <source_path> --output <output_file> [OPTIONS]
```

### Options

| Option | Short | Argument | Default | Description |
|--------|-------|----------|---------|-------------|
| `--path` | `-p` | PATH | "." | Source directory path to scan |
| `--output` | `-o` | FILE | "./tree.csv" | Output CSV file path |
| `--max-depth` | `-d` | DEPTH | -1 | Maximum nesting depth (-1 = unlimited, 0 = root only) |
| `--include-hidden` | `-h` | none | false | Include hidden files/folders (files starting with .) |
| `--include-system` | `-s` | none | false | Include system files/folders (reserved names) |
| `--ascii` | `-a` | none | false | Use ASCII characters instead of Unicode for tree branches |
| `--help` | | none | | Show help message and exit |

## Examples

### Full directory tree of home directory
```bash
./export-tree.sh -p ~ -o ~/tree.csv
```

### Same with ASCII tree characters (for compatibility)
```bash
./export-tree.sh -p /home -o tree_ascii.csv -a
```

### Limited depth to 2 levels
```bash
./export-tree.sh -p ~/Projects -d 2 -o projects_top2.csv
```

### Include hidden files (dotfiles)
```bash
./export-tree.sh -p . -h -o full_tree.csv
```

### All options combined
```bash
./export-tree.sh -p /var -d 3 -h -a -o system_tree.csv
```

### Specific directory scanning
```bash
./export-tree.sh --path /usr/local --output local_tree.csv --max-depth 3
```

## Output Example

CSV content visualization:

```
Tree,Type,Name,Extension,SizeBytes,LastWriteTime,Attributes,FullPath,Depth,ParentPath
.,Dir,home,,,drwxr-xr-x,/home,0,
├── user,Dir,user,,,drwx------,/home/user,1,/home
│   ├── Documents,Dir,Documents,,,drwxr-xr-x,/home/user/Documents,2,/home/user
│   │   ├── report.pdf,File,report.pdf,pdf,1048576,2025-12-15 10:30:00,-rw-r--r--,/home/user/Documents/report.pdf,3,/home/user/Documents
│   │   └── notes.txt,File,notes.txt,txt,2048,2025-12-15 09:15:00,-rw-r--r--,/home/user/Documents/notes.txt,3,/home/user/Documents
│   └── Downloads,Dir,Downloads,,,drwxr-xr-x,/home/user/Downloads,2,/home/user
└── admin,Dir,admin,,,drwx------,/home/admin,1,/home
    └── config.conf,File,config.conf,conf,512,2025-12-14 14:22:00,-rw-r-----,/home/admin/config.conf,2,/home/admin
```

## How It Works

1. **Argument Parsing**: Processes command-line options and sets parameters
2. **Path Validation**: Checks that the source directory exists and resolves to absolute path
3. **Temporary File**: Creates a temporary file to buffer CSV rows
4. **Recursive Traversal**: Uses the `walk` function to recursively process directories
5. **Filtering**: Applies include rules based on `--include-hidden` flag
6. **Sorting**: Directories listed first, then files, both alphabetically sorted
7. **Tree Building**: Constructs visual tree prefixes using the `build_prefix` function
8. **Data Collection**: Gathers file metadata using `stat` and other utilities
9. **CSV Export**: Writes header and all collected rows to CSV file
10. **Cleanup**: Removes temporary file via trap handler

## Key Functions

- **`should_include_item`**: Filters items based on naming conventions (hidden files)
- **`get_extension`**: Extracts file extension from filename
- **`get_size`**: Retrieves file size in bytes using `stat`
- **`get_mtime`**: Gets last modification timestamp
- **`get_attributes`**: Extracts file permissions using `stat`
- **`build_prefix`**: Generates tree branch characters (│, ├──, └──, etc.)
- **`escape_csv`**: Properly escapes and quotes CSV fields containing special characters
- **`walk`**: Main recursive function that traverses the directory tree

## Notes

- **Sorting**: Directories are listed first, then files, both sorted alphabetically by filename
- **Depth Counter**: The depth counter starts at 0 for the root directory
- **Error Handling**: Directories that cannot be accessed are silently skipped
- **Unicode Support**: Use `--ascii` parameter if your CSV editor has Unicode rendering issues
- **Temporary Files**: Uses `mktemp` for secure temporary file creation; automatically cleaned up
- **Performance**: Large directory trees may take time to process; use `--max-depth` to limit scope
- **Paths**: All paths in output are absolute paths for consistency

## Output File Format

- **Encoding**: UTF-8 (locale dependent)
- **Delimiter**: Comma (,)
- **Quoting**: Fields with special characters are quoted with double quotes
- **Escaping**: Double quotes within fields are escaped as `""`
- **Headers**: Yes (column names in first row)

## Troubleshooting

### Permission Denied Errors
The script skips directories it cannot access. Run with appropriate permissions:
```bash
sudo ./export-tree.sh -p /root -o root_tree.csv
```

### Unicode Characters Not Displaying
Use the ASCII mode:
```bash
./export-tree.sh -p . -a -o tree_ascii.csv
```

### Script Not Executing
Make sure the script is executable:
```bash
chmod +x export-tree.sh
```

### Large Output Files
Use `--max-depth` to limit recursion:
```bash
./export-tree.sh -p / -d 3 -o limited_tree.csv
```

## Performance Tips

1. Use `--max-depth` to limit the scope of scanning
2. For very large trees, consider redirecting output to monitor progress
3. Avoid scanning mounted network filesystems for better performance
4. Use absolute paths for better performance

## Compatibility

- Linux (all distributions)
- macOS (with GNU coreutils installed via Homebrew)
- BSD variants
- WSL (Windows Subsystem for Linux)
- Any POSIX-compliant Unix system

## Related

See `Export-TreeCsv.ps1` for the Windows PowerShell equivalent.
