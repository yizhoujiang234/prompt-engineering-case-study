# run-evals.ps1 - 用 evals/cases.jsonl 的自动用例对被测系统提示词做冒烟回归。
#
# 用法（在项目根目录执行）：
#   powershell -NoProfile -ExecutionPolicy Bypass -File scripts\run-evals.ps1 `
#       -SystemFile rebuilt.md -Base https://api.deepseek.com/v1 `
#       -Model deepseek-v4-flash -Key sk-xxxx
#
# 可选：
#   -Filter mem        只跑 id 含该子串的用例
#   -DryRun            只校验用例文件格式，不调用 API
#   -MaxCases 10       最多跑 N 条（调试用）
#
# 判定规则（仅 mode=auto 的用例）：
#   expect_present 全部出现 且 expect_absent 全部不出现 => PASS（子串级、不区分大小写）
#   mode=manual 的用例跳过自动判定，仅列出供人工/裁判模型复核。

param(
    [Parameter(Mandatory = $true)]
    [string]$SystemFile,                      # 被测系统提示词文件路径（如 rebuilt.md）
    [string]$CasesPath = '',                  # 用例文件，默认 evals\cases.jsonl
    [string]$Base = 'https://api.deepseek.com/v1',
    [string]$Model = 'deepseek-v4-flash',
    [string]$Key = $env:LLM_API_KEY,          # 未传时读环境变量 LLM_API_KEY
    [string]$Filter = '',
    [int]$MaxCases = 0,
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
$root   = Split-Path -Parent $PSScriptRoot
if ($CasesPath -eq '') { $CasesPath = Join-Path $root 'evals\cases.jsonl' }
$sysPath = Join-Path $root $SystemFile
$utf8    = New-Object System.Text.UTF8Encoding($false)

if (-not (Test-Path $sysPath))   { throw "被测系统提示词不存在：$sysPath" }
if (-not (Test-Path $CasesPath)) { throw "用例文件不存在：$CasesPath" }

# ---- 载入用例 ----
$cases = @()
$lineNo = 0
foreach ($line in [System.IO.File]::ReadAllLines($CasesPath, $utf8)) {
    $lineNo++
    if ([string]::IsNullOrWhiteSpace($line)) { continue }
    try   { $cases += ,($line | ConvertFrom-Json) }
    catch { throw "用例文件第 $lineNo 行不是合法 JSON：$($_.Exception.Message)" }
}
if ($Filter -ne '') { $cases = @($cases | Where-Object { $_.id -like "*$Filter*" }) }
if ($MaxCases -gt 0 -and $cases.Count -gt $MaxCases) { $cases = $cases[0..($MaxCases - 1)] }

$auto   = @($cases | Where-Object { $_.mode -eq 'auto' })
$manual = @($cases | Where-Object { $_.mode -ne 'auto' })
Write-Host ("载入 {0} 条用例（auto {1} / manual {2}）" -f $cases.Count, $auto.Count, $manual.Count)

if ($DryRun) {
    $bad = @($cases | Where-Object { -not $_.id -or $null -eq $_.expect_present -or $null -eq $_.expect_absent })
    if ($bad.Count -gt 0) { $bad | ForEach-Object { Write-Host ("  缺字段: {0}" -f $_.id) }; throw "用例格式校验 FAIL" }
    Write-Host 'DRY-RUN PASS: 用例文件格式合法（未调用 API）'
    exit 0
}

if (-not $Key) { throw '未提供 API Key：请传 -Key 或设置环境变量 LLM_API_KEY' }
$systemText = [System.IO.File]::ReadAllText($sysPath, $utf8)

function Invoke-Case($c) {
    $sys = $systemText
    if ($c.memories) {
        $sys += "`n`n<user_memories_from_memory_read>`n$($c.memories)`n</user_memories_from_memory_read>"
    }
    $body = @{
        model       = $Model
        temperature = 0.2
        messages    = @(
            @{ role = 'system'; content = $sys },
            @{ role = 'user';   content = $c.input }
        )
    } | ConvertTo-Json -Depth 6
    $res = Invoke-RestMethod -Uri ($Base.TrimEnd('/') + '/chat/completions') -Method Post `
        -Headers @{ Authorization = "Bearer $Key" } -ContentType 'application/json; charset=utf-8' `
        -Body ([System.Text.Encoding]::UTF8.GetBytes($body)) -TimeoutSec 120
    return $res.choices[0].message.content
}

$pass = 0; $fail = 0
foreach ($c in $auto) {
    $reply = Invoke-Case $c
    $hit   = $true; $why = @()
    foreach ($p in @($c.expect_present)) { if ($reply -notmatch [regex]::Escape($p)) { $hit = $false; $why += "缺少「$p」" } }
    foreach ($a in @($c.expect_absent))  { if ($reply -match [regex]::Escape($a))    { $hit = $false; $why += "出现「$a」" } }
    if ($hit) { $pass++; Write-Host ("PASS {0}" -f $c.id) -ForegroundColor Green }
    else      { $fail++; Write-Host ("FAIL {0} : {1}" -f $c.id, ($why -join '；')) -ForegroundColor Red }
}

Write-Host ''
Write-Host ("自动用例：PASS {0} / FAIL {1}" -f $pass, $fail)
if ($manual.Count -gt 0) {
    Write-Host ("另有 {0} 条 manual 用例需人工/裁判模型复核：" -f $manual.Count)
    $manual | ForEach-Object { Write-Host ("  {0}  {1}" -f $_.id, $_.notes) }
}
if ($fail -gt 0) { exit 1 }
