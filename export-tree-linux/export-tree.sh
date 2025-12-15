#!/bin/bash

# export-tree.sh - Export directory tree to CSV format
# Similar to Export-TreeCsv.ps1 but for Linux/Unix systems

set -euo pipefail

# Default parameters
PATH_TO_SCAN="."
OUTPUT_FILE="./tree.csv"
MAX_DEPTH=-1
INCLUDE_HIDDEN=false
INCLUDE_SYSTEM=false
USE_ASCII=false

# Temporary file for storing rows
TEMP_FILE=$(mktemp)
trap "rm -f $TEMP_FILE" EXIT

# CSV header
csv_header="Tree,Type,Name,Extension,SizeBytes,LastWriteTime,Attributes,FullPath,Depth,ParentPath"

# Function: Print usage information
usage() {
  cat << EOF
Usage: $0 [OPTIONS]

OPTIONS:
  -p, --path PATH           Source directory path (default: .)
  -o, --output FILE         Output CSV file path (default: ./tree.csv)
  -d, --max-depth DEPTH     Maximum nesting depth (-1 = unlimited, default: -1)
  -h, --include-hidden      Include hidden files/folders (files starting with .)
  -s, --include-system      Include system files/folders (reserved names)
  -a, --ascii               Use ASCII tree characters instead of Unicode
  --help                    Show this help message

EXAMPLES:
  # Full tree of home directory
  $0 -p ~/Documents -o tree.csv

  # Limited to 2 levels with ASCII characters
  $0 -p /home -d 2 -a -o tree.csv

  # Include hidden files and directories
  $0 -p . -h -o full_tree.csv

EOF
  exit 0
}

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -p|--path)
      PATH_TO_SCAN="$2"
      shift 2
      ;;
    -o|--output)
      OUTPUT_FILE="$2"
      shift 2
      ;;
    -d|--max-depth)
      MAX_DEPTH="$2"
      shift 2
      ;;
    -h|--include-hidden)
      INCLUDE_HIDDEN=true
      shift
      ;;
    -s|--include-system)
      INCLUDE_SYSTEM=true
      shift
      ;;
    -a|--ascii)
      USE_ASCII=true
      shift
      ;;
    --help)
      usage
      ;;
    *)
      echo "Unknown option: $1"
      usage
      ;;
  esac
done

# Function: Check if item should be included
should_include_item() {
  local item="$1"
  local filename=$(basename "$item")
  
  # Check for hidden files (starting with .)
  if [[ "$filename" == .* ]] && ! $INCLUDE_HIDDEN; then
    return 1
  fi
  
  return 0
}

# Function: Get file extension
get_extension() {
  local filename="$1"
  if [[ "$filename" == *.* ]]; then
    echo "${filename##*.}"
  else
    echo ""
  fi
}

# Function: Get file size in bytes
get_size() {
  local item="$1"
  if [[ -f "$item" ]]; then
    stat -c%s "$item" 2>/dev/null || echo ""
  else
    echo ""
  fi
}

# Function: Get last modification time
get_mtime() {
  local item="$1"
  stat -c"%y" "$item" 2>/dev/null | cut -d. -f1 || echo ""
}

# Function: Get file permissions as attributes
get_attributes() {
  local item="$1"
  stat -c"%A" "$item" 2>/dev/null || echo ""
}

# Function: Build tree prefix
build_prefix() {
  local has_next_mask="$1"
  local is_last="$2"
  local depth="$3"
  
  local prefix=""
  
  # Process each level
  for ((i=0; i<${#has_next_mask}; i++)); do
    if [[ "${has_next_mask:$i:1}" == "1" ]]; then
      if $USE_ASCII; then
        prefix+="|   "
      else
        prefix+="│   "
      fi
    else
      prefix+="    "
    fi
  done
  
  # Add final branch character
  if [[ ${#has_next_mask} -ge 0 ]]; then
    if $USE_ASCII; then
      if [[ "$is_last" == "1" ]]; then
        prefix+="\-– "
      else
        prefix+="|– "
      fi
    else
      if [[ "$is_last" == "1" ]]; then
        prefix+="└── "
      else
        prefix+="├── "
      fi
    fi
  fi
  
  echo "$prefix"
}

# Function: Escape CSV field
escape_csv() {
  local field="$1"
  # Escape quotes and wrap in quotes if needed
  if [[ "$field" == *","* ]] || [[ "$field" == *'"'* ]] || [[ "$field" == *$'\n'* ]]; then
    field="${field//\"/\"\"}"
    echo "\"$field\""
  else
    echo "$field"
  fi
}

# Function: Recursive tree walk
walk() {
  local item="$1"
  local depth="$2"
  local has_next_mask="$3"
  local is_root="$4"
  
  # Check depth limit
  if [[ $MAX_DEPTH -ge 0 ]] && [[ $depth -gt $MAX_DEPTH ]]; then
    return
  fi
  
  local filename=$(basename "$item")
  local is_dir=0
  local is_last=0
  
  [[ -d "$item" ]] && is_dir=1
  
  # Check if last in parent's list
  if [[ ${#has_next_mask} -gt 0 ]]; then
    is_last="${has_next_mask: -1}"
  fi
  
  # Build tree prefix
  if [[ "$is_root" == "1" ]]; then
    tree_prefix="."
  else
    tree_prefix=$(build_prefix "$has_next_mask" "$is_last" "$depth")
  fi
  
  # Determine type
  local type="File"
  [[ $is_dir -eq 1 ]] && type="Dir"
  
  # Get file properties
  local name="$filename"
  local extension=""
  local size_bytes=""
  local last_write_time=""
  local attributes=""
  local full_path="$item"
  local parent_path=""
  
  if [[ $is_dir -eq 0 ]]; then
    extension=$(get_extension "$filename")
    size_bytes=$(get_size "$item")
  fi
  
  last_write_time=$(get_mtime "$item")
  attributes=$(get_attributes "$item")
  
  if [[ "$is_root" != "1" ]]; then
    parent_path=$(dirname "$item")
  fi
  
  # Build CSV row
  local tree_field=$(escape_csv "${tree_prefix}${name}")
  local name_field=$(escape_csv "$name")
  local extension_field=$(escape_csv "$extension")
  local full_path_field=$(escape_csv "$full_path")
  local parent_path_field=$(escape_csv "$parent_path")
  
  local csv_row="${tree_field},${type},${name_field},${extension_field},${size_bytes},${last_write_time},${attributes},${full_path_field},${depth},${parent_path_field}"
  echo "$csv_row" >> "$TEMP_FILE"
  
  # Recursively process children
  if [[ $is_dir -eq 1 ]]; then
    local children=()
    local dirs=()
    local files=()
    
    # Read items
    while IFS= read -r -d '' child; do
      if should_include_item "$child"; then
        if [[ -d "$child" ]]; then
          dirs+=("$child")
        else
          files+=("$child")
        fi
      fi
    done < <(find "$item" -maxdepth 1 -not -path "$item" -print0 2>/dev/null | sort -z)
    
    # Combine: directories first, then files
    children=("${dirs[@]}" "${files[@]}")
    
    # Process each child
    for ((i=0; i<${#children[@]}; i++)); do
      local child="${children[$i]}"
      local child_is_last=0
      
      if [[ $((i + 1)) -eq ${#children[@]} ]]; then
        child_is_last=1
      fi
      
      # Build mask for next level
      local next_mask="$has_next_mask"
      if [[ "$is_root" != "1" ]]; then
        next_mask="${next_mask}${is_last}"
      fi
      next_mask="${next_mask}${child_is_last}"
      
      walk "$child" $((depth + 1)) "$next_mask" "0"
    done
  fi
}

# Main execution

# Validate path
if [[ ! -d "$PATH_TO_SCAN" ]]; then
  echo "Error: Path '$PATH_TO_SCAN' not found." >&2
  exit 1
fi

# Get absolute path
PATH_TO_SCAN=$(cd "$PATH_TO_SCAN" && pwd)

echo "Scanning: $PATH_TO_SCAN"
echo "Output: $OUTPUT_FILE"

# Create output directory if needed
OUTPUT_DIR=$(dirname "$OUTPUT_FILE")
if [[ "$OUTPUT_DIR" != "." ]] && [[ ! -d "$OUTPUT_DIR" ]]; then
  mkdir -p "$OUTPUT_DIR"
fi

# Clear temp file
> "$TEMP_FILE"

# Write header
echo "$csv_header" > "$OUTPUT_FILE"

# Start walking from root
walk "$PATH_TO_SCAN" 0 "" "1"

# Append all rows to output file
cat "$TEMP_FILE" >> "$OUTPUT_FILE"

# Count rows
row_count=$(wc -l < "$OUTPUT_FILE")
row_count=$((row_count - 1))  # Subtract header

echo "Done! Exported $row_count items to '$OUTPUT_FILE'."
