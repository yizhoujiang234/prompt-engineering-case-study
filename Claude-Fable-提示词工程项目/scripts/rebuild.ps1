# rebuild.ps1 - 将 modules/ 下 19 个模块重组为 rebuilt.md，并与原文逐字节比对。
#
# 重组规则：
#   1. 按文件名编号升序拼接
#   2. 剥离每个模块头部的 <!-- ... --> 注释块
#   3. 在 07 / 09 / 10 / 11 号模块之后各补一个空行（对应原文 1053/1194/1225/1440 行）
#   4. 全文 LF、UTF-8 无 BOM，末尾保留一个换行符
#
# 用法（在项目根目录执行）：
#   powershell -NoProfile -ExecutionPolicy Bypass -File scripts\rebuild.ps1
# 变体组装（只拼子集，输出 rebuilt-variant.md，不做逐字节比对）：
#   powershell -NoProfile -ExecutionPolicy Bypass -File scripts\rebuild.ps1 -Include '01,02,03,05,14'

param(
    # 要组装的模块编号列表（逗号分隔）；留空 = 全量 19 模块 + 逐字节比对
    [string]$Include = ''
)

$ErrorActionPreference = 'Stop'
$root    = Split-Path -Parent $PSScriptRoot
$modDir  = Join-Path $root 'modules'
$orig    = Join-Path $root 'original\Claude-Fable-5.1.md'
$utf8    = New-Object System.Text.UTF8Encoding($false)

$isVariant = ($Include -ne '')
$outPath   = Join-Path $root $(if ($isVariant) { 'rebuilt-variant.md' } else { 'rebuilt.md' })

$gapAfter = @('07','09','10','11')

$files = Get-ChildItem (Join-Path $modDir '*.md') |
    Where-Object { $_.Name -match '^\d{2}-' } |
    Sort-Object Name

if ($files.Count -ne 19) { throw "期望 19 个模块文件，实际找到 $($files.Count) 个" }

if ($isVariant) {
    $want = $Include -split '\s*,\s*' | Where-Object { $_ -ne '' }
    $known = @($files | ForEach-Object { $_.Name.Substring(0, 2) })
    $unknown = @($want | Where-Object { $known -notcontains $_ })
    if ($unknown.Count -gt 0) { throw "-Include 含未知模块编号：$($unknown -join ',')" }
    $files = @($files | Where-Object { $want -contains $_.Name.Substring(0, 2) } | Sort-Object Name)
    Write-Host ("变体模式：组装 {0} 个模块 -> {1}" -f $files.Count, 'rebuilt-variant.md')
}

$parts  = New-Object System.Collections.Generic.List[string]
$prevId = $null
foreach ($f in $files) {
    $id  = $f.Name.Substring(0, 2)
    $raw = [System.IO.File]::ReadAllLines($f.FullName, $utf8)
    $i = 0
    while ($i -lt $raw.Count -and $raw[$i] -notmatch '^-->\s*$') { $i++ }
    if ($i -ge $raw.Count) { throw "未找到模块头注释结束标记 '-->' ： $($f.Name)" }
    if ($null -ne $prevId -and $gapAfter -contains $prevId) { $parts.Add('') }
    foreach ($ln in $raw[($i + 1)..($raw.Count - 1)]) { $parts.Add($ln) }
    $prevId = $id
}

$rebuilt = ($parts -join "`n") + "`n"
[System.IO.File]::WriteAllText($outPath, $rebuilt, $utf8)

if ($isVariant) {
    $lines = ($rebuilt -split "`n").Count
    Write-Host ("PASS: rebuilt-variant.md 已生成（{0} 个模块 / {1} 行）。变体不与原文比对。" -f $files.Count, $lines)
    exit 0
}

$origText = [System.IO.File]::ReadAllText($orig, $utf8)
if ($origText -ceq $rebuilt) {
    Write-Host 'PASS: rebuilt.md 与 original/Claude-Fable-5.1.md 逐字节一致（LF / UTF-8 无 BOM / 2195 行）'
} else {
    $a = $origText -split "`n"
    $b = $rebuilt    -split "`n"
    Write-Host ("FAIL: 原文 {0} 行，重组 {1} 行" -f $a.Count, $b.Count)
    $n = [Math]::Min($a.Count, $b.Count)
    for ($j = 0; $j -lt $n; $j++) {
        if ($a[$j] -cne $b[$j]) {
            Write-Host ("首个差异在第 {0} 行:" -f ($j + 1))
            Write-Host ("  原文   : {0}" -f $a[$j].Substring(0, [Math]::Min(100, $a[$j].Length)))
            Write-Host ("  重组后 : {0}" -f $b[$j].Substring(0, [Math]::Min(100, $b[$j].Length)))
            break
        }
    }
}
