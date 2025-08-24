
PowerShell-скрипт, який експортує дерево файлів і папок у CSV.
Він малює гілки символами (│, ├──, └──) у стовпчику Tree, а також додає службові колонки (тип, розмір, дати, шлях тощо).

скопіюйте в файл Export-TreeCsv.ps1 і запустіть, наприклад:
.\Export-TreeCsv.ps1 -Path "C:\" -OutFile ".\tree.csv"

###

як це виглядає в CSV

.  
├── Program Files
│   ├── Common Files
│   └── SomeApp
└── Users
    ├── Public
    └── Private

###

Commands of PowerShell

# Повне дерево диска C:, без hidden/system, без ліміту глибини:
.\Export-TreeCsv.ps1 -Path "C:\" -OutFile ".\tree.csv"

# Те саме, але ASCII-гілки (на випадок проблем із юнікодом у редакторі CSV):
.\Export-TreeCsv.ps1 -Path "D:\" -OutFile ".\tree_ascii.csv" -Ascii

# Лише до 2-го рівня вкладеності:
.\Export-TreeCsv.ps1 -Path "C:\Projects" -OutFile ".\projects_top2.csv" -MaxDepth 2

# Включити приховані та системні:
.\Export-TreeCsv.ps1 -Path "C:\" -OutFile ".\full_tree.csv" -IncludeHidden -IncludeSystem