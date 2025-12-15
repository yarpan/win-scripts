param(
  [Parameter(Mandatory=$false)]
  [string]$Path = ".",

  [Parameter(Mandatory=$false)]
  [string]$OutFile = ".\tree.csv",

  # -1 = unlimited; 0 = root only; 1 = root + children; etc.
  [int]$MaxDepth = -1,

  [switch]$IncludeHidden,
  [switch]$IncludeSystem,

  # If your CSV editor doesn't like Unicode tree characters, add -Ascii
  [switch]$Ascii
)

# --- Internal helper functions ---

function _ShouldIncludeItem {
  param([System.IO.FileSystemInfo]$Item)
  if (-not $IncludeHidden) {
    if ($Item.Attributes -band [IO.FileAttributes]::Hidden) { return $false }
  }
  if (-not $IncludeSystem) {
    if ($Item.Attributes -band [IO.FileAttributes]::System) { return $false }
  }
  return $true
}

function _GetChildren {
  param([System.IO.DirectoryInfo]$Dir)
  try {
    $kids = Get-ChildItem -LiteralPath $Dir.FullName -Force -ErrorAction Stop
    $kids = $kids | Where-Object { _ShouldIncludeItem $_ }
    # Folders first, then files; sorted by name
    $kids | Sort-Object @{Expression={$_.PSIsContainer};Descending=$true}, Name
  } catch {
    @() # Inaccessible folder — return empty list
  }
}

# Build prefix (│ / spaces) based on "mask" of ancestors, where $true means there are more siblings at this level
function _BuildPrefix {
  param([bool[]]$HasNextMask, [bool]$IsLast, [switch]$Ascii)
  $sb = New-Object System.Text.StringBuilder
  for ($i=0; $i -lt $HasNextMask.Count; $i++) {
    if ($HasNextMask[$i]) {
      if ($Ascii) {
        [void]$sb.Append("|   ")
      } else {
        [void]$sb.Append("│   ")
      }
    } else {
      [void]$sb.Append("    ")
    }
  }
  if ($HasNextMask.Count -ge 0) {
    if ($Ascii) {
      if ($IsLast) {
        [void]$sb.Append("\-– ")
      } else {
        [void]$sb.Append("|– ")
      }
    } else {
      if ($IsLast) {
        [void]$sb.Append("└── ")
      } else {
        [void]$sb.Append("├── ")
      }
    }
  }
  $sb.ToString()
}

# Recursive traversal with tree building
function _Walk {
  param(
    [System.IO.FileSystemInfo]$Item,
    [int]$Depth,
    [System.Collections.Generic.List[bool]]$HasNextMask, # traces of branches above
    [switch]$IsRoot
  )

  $isDir = $Item.PSIsContainer
  $isLast = $HasNextMask.Count -gt 0 -and -not $HasNextMask[$HasNextMask.Count-1] # not used for root
  $treePrefix = if ($IsRoot) { "." } else { _BuildPrefix $HasNextMask $isLast $Ascii }

  # CSV row object
  $row = [PSCustomObject]@{
    Tree          = $treePrefix + $Item.Name
    Type          = if ($isDir) { "Dir" } else { "File" }
    Name          = $Item.Name
    Extension     = if ($isDir) { "" } else { $Item.Extension }
    SizeBytes     = if ($isDir) { $null } else { $Item.Length }
    LastWriteTime = $Item.LastWriteTime
    Attributes    = $Item.Attributes.ToString()
    FullPath      = $Item.FullName
    Depth         = $Depth
    ParentPath    = if ($IsRoot) { "" } else { Split-Path -LiteralPath $Item.FullName -Parent }
  }
  $script:Rows.Add($row) | Out-Null

  # If it's a folder — traverse children
  if ($isDir) {
    if ($MaxDepth -ge 0 -and $Depth -ge $MaxDepth) { return }
    $children = _GetChildren -Dir $Item
    for ($i=0; $i -lt $children.Count; $i++) {
      $child = $children[$i]
      # Mask: copy, but for current level set $true if there will be more elements after this (i.e., "has siblings")
      $nextMask = New-Object System.Collections.Generic.List[bool]
      if ($HasNextMask) { $null = $nextMask.AddRange($HasNextMask) }
      $hasMoreSiblings = ($i -lt $children.Count - 1)
      $null = $nextMask.Add($hasMoreSiblings)
      _Walk -Item $child -Depth ($Depth + 1) -HasNextMask $nextMask
    }
  }
}

# --- Main logic ---

# Validate path
try {
  $rootPath = (Resolve-Path -LiteralPath $Path).Path
} catch {
  Write-Error "Path '$Path' not found."
  exit 1
}

$root = Get-Item -LiteralPath $rootPath -Force
if (-not (_ShouldIncludeItem $root)) {
  Write-Error "Root object is marked as Hidden/System and filtered. Add -IncludeHidden/-IncludeSystem."
  exit 1
}

# Results collection
$script:Rows = New-Object System.Collections.Generic.List[object]

# Start from root (special marker for Tree — '.')
_Walk -Item $root -Depth 0 -HasNextMask ([System.Collections.Generic.List[bool]]::new()) -IsRoot

# Export to CSV
$dir = Split-Path -Parent -Path (Resolve-Path -LiteralPath $OutFile -ErrorAction SilentlyContinue)
if ($dir -and -not (Test-Path -LiteralPath $dir)) {
  New-Item -ItemType Directory -Path $dir -Force | Out-Null
}

$Rows | Export-Csv -Path $OutFile -NoTypeInformation -Encoding UTF8
Write-Host "Done! Exported $($Rows.Count) rows to '$OutFile'."
