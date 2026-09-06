# check-refs.ps1 - 校验全项目的行号引用没有失效。
#
# 检查两件事：
#   1) 每个模块文件头部声明的「原文行号 : X - Y」与 split.ps1 的模块定义表一致；
#   2) docs/ templates/ README.md modules/README.md 中所有 L<n> / L<a>–<b> 引用
#      落在 1..2195 范围内（防模块边界变动后引用静默失效）。
#
# 用法（在项目根目录执行，可挂在 rebuild.ps1 之后一起跑）：
#   powershell -NoProfile -ExecutionPolicy Bypass -File scripts\check-refs.ps1

$ErrorActionPreference = 'Stop'
$root   = Split-Path -Parent $PSScriptRoot
$utf8   = New-Object System.Text.UTF8Encoding($false)
$total  = 2195   # 原文总行数；若模块边界重划导致行数变化，同步更新此处

# ---- 1. 解析 split.ps1 的模块定义表 ----
$splitText = [System.IO.File]::ReadAllText((Join-Path $root 'scripts\split.ps1'), $utf8)
$table = @{}
foreach ($m in [regex]::Matches($splitText, "id='(\d{2})';\s*title='([^']*)';\s*start=(\d+);\s*end=(\d+)")) {
    $table[$m.Groups[1].Value] = @{ title = $m.Groups[2].Value; start = [int]$m.Groups[3].Value; end = [int]$m.Groups[4].Value }
}
if ($table.Count -ne 19) { throw "split.ps1 解析到 $($table.Count) 个模块定义，期望 19 个" }

# ---- 2. 模块文件头部声明 vs 定义表 ----
$errs = @()
$modDir = Join-Path $root 'modules'
foreach ($f in (Get-ChildItem "$modDir\*.md" | Where-Object { $_.Name -match '^\d{2}-' } | Sort-Object Name)) {
    $id = $f.Name.Substring(0, 2)
    $head = ([System.IO.File]::ReadAllText($f.FullName, $utf8) -split "`n")[0..14] -join "`n"
    $hm = [regex]::Match($head, '原文行号\s*:\s*(\d+)\s*-\s*(\d+)')
    if (-not $hm.Success) { $errs += "模块 $id 头部未找到「原文行号 : X - Y」声明"; continue }
    $hs = [int]$hm.Groups[1].Value; $he = [int]$hm.Groups[2].Value
    $t = $table[$id]
    if (-not $t) { $errs += "模块 $id 不在 split.ps1 定义表中"; continue }
    if ($hs -ne $t.start -or $he -ne $t.end) {
        $errs += ("模块 {0} 头部声明 {1}-{2} 与定义表 {3}-{4} 不一致" -f $id, $hs, $he, $t.start, $t.end)
    }
}

# ---- 3. 文档中的 L<n> / L<a>–<b> 引用 ----
$scanFiles = @(
    (Get-ChildItem "$root\docs\*.md"),
    (Get-ChildItem "$root\templates\*.md"),
    (Get-ChildItem "$root\README.md"),
    (Get-ChildItem "$root\modules\README.md")
) | ForEach-Object { $_ }
$refCount = 0
foreach ($f in $scanFiles) {
    $lines = [System.IO.File]::ReadAllLines($f.FullName, $utf8)
    for ($i = 0; $i -lt $lines.Count; $i++) {
        foreach ($m in [regex]::Matches($lines[$i], 'L(\d+)(?:\s*[–—-]\s*(\d+))?')) {
            $refCount++
            $lo = [int]$m.Groups[1].Value
            $hi = if ($m.Groups[2].Success) { [int]$m.Groups[2].Value } else { $lo }
            if ($lo -lt 1 -or $hi -gt $total -or $lo -gt $hi) {
                $errs += ("{0}:{1} 行号引用越界: {2}（原文共 {3} 行）" -f $f.Name, ($i + 1), $m.Value, $total)
            }
        }
    }
}

# ---- 结果 ----
if ($errs.Count -eq 0) {
    Write-Host ("PASS: 19 个模块头部声明与 split.ps1 一致；{0} 处 L 引用全部在 1..{1} 范围内" -f $refCount, $total)
    exit 0
} else {
    $errs | ForEach-Object { Write-Host "FAIL: $_" -ForegroundColor Red }
    Write-Host ("共 {0} 处问题" -f $errs.Count)
    exit 1
}
