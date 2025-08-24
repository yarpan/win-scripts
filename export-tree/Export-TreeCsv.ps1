param(
  [Parameter(Mandatory=$false)]
  [string]$Path = ".",

  [Parameter(Mandatory=$false)]
  [string]$OutFile = ".\tree.csv",

  # -1 = без обмеження; 0 = тільки корінь; 1 = корінь + діти; і т.д.
  [int]$MaxDepth = -1,

  [switch]$IncludeHidden,
  [switch]$IncludeSystem,

  # Якщо ваш CSV-редактор не любить юнікод-гілки, додайте -Ascii
  [switch]$Ascii
)

# --- Внутрішні допоміжні функції ---

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
    # Папки зверху, потім файли; сортування за іменем
    $kids | Sort-Object @{Expression={$_.PSIsContainer};Descending=$true}, Name
  } catch {
    @() # недоступна папка — повертаємо порожній список
  }
}

# Побудова префікса (│ / пробіли) за "маскою" предків, де $true означає є ще сусіди на цьому рівні
function _BuildPrefix {
  param([bool[]]$HasNextMask, [bool]$IsLast, [switch]$Ascii)
  $sb = New-Object System.Text.StringBuilder
  for ($i=0; $i -lt $HasNextMask.Count; $i++) {
    if ($HasNextMask[$i]) {
      [void]$sb.Append( if ($Ascii) { "|   " } else { "│   " } )
    } else {
      [void]$sb.Append("    ")
    }
  }
  if ($HasNextMask.Count -ge 0) {
    [void]$sb.Append( if ($Ascii) { ($IsLast ? "\-– " : "|– " ) } else { ($IsLast ? "└── " : "├── " ) } )
  }
  $sb.ToString()
}

# Рекурсивний обхід із побудовою "дерева"
function _Walk {
  param(
    [System.IO.FileSystemInfo]$Item,
    [int]$Depth,
    [System.Collections.Generic.List[bool]]$HasNextMask, # сліди гілок вище
    [switch]$IsRoot
  )

  $isDir = $Item.PSIsContainer
  $isLast = $HasNextMask.Count -gt 0 -and -not $HasNextMask[$HasNextMask.Count-1] # не використовується для кореня
  $treePrefix = if ($IsRoot) { if ($Ascii) { "." } else { "." } } else { _BuildPrefix $HasNextMask $isLast $Ascii }

  # Об’єкт рядка CSV
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

  # Якщо це папка — обходимо дітей
  if ($isDir) {
    if ($MaxDepth -ge 0 -and $Depth -ge $MaxDepth) { return }
    $children = _GetChildren -Dir $Item
    for ($i=0; $i -lt $children.Count; $i++) {
      $child = $children[$i]
      # Маска: копія, але для поточного рівня ставимо $true якщо буде ще елементи після цього (тобто "є сусіди")
      $nextMask = New-Object System.Collections.Generic.List[bool]
      if ($HasNextMask) { $null = $nextMask.AddRange($HasNextMask) }
      $hasMoreSiblings = ($i -lt $children.Count - 1)
      $null = $nextMask.Add($hasMoreSiblings)
      _Walk -Item $child -Depth ($Depth + 1) -HasNextMask $nextMask
    }
  }
}

# --- Основна логіка ---

# Перевірка шляху
try {
  $rootPath = (Resolve-Path -LiteralPath $Path).Path
} catch {
  Write-Error "Шлях '$Path' не знайдено."
  exit 1
}

$root = Get-Item -LiteralPath $rootPath -Force
if (-not (_ShouldIncludeItem $root)) {
  Write-Error "Кореневий об’єкт позначений як Hidden/System і відфільтрований. Додайте -IncludeHidden/-IncludeSystem."
  exit 1
}

# Колекція результатів
$script:Rows = New-Object System.Collections.Generic.List[object]

# Стартуємо з кореня (спеціальна позначка для Tree — '.')
_Walk -Item $root -Depth 0 -HasNextMask ([System.Collections.Generic.List[bool]]::new()) -IsRoot

# Експорт у CSV
$dir = Split-Path -Parent -Path (Resolve-Path -LiteralPath $OutFile -ErrorAction SilentlyContinue)
if ($dir -and -not (Test-Path -LiteralPath $dir)) {
  New-Item -ItemType Directory -Path $dir -Force | Out-Null
}

$Rows | Export-Csv -Path $OutFile -NoTypeInformation -Encoding UTF8
Write-Host "Готово! Записано $($Rows.Count) рядків у '$OutFile'."
