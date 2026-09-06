# split.ps1 - 将 original/Claude-Fable-5.1.md 按行号切分为 19 个模块文件到 modules/
#
# 行尾规范：与原文保持一致（LF、UTF-8 无 BOM）。
# 每个模块文件的所有行（含末尾空行）均以换行符结尾，
# 保证模块尾部空行在 ReadAllLines 读回时不丢失（round-trip 无损）。
#
# 用法（在项目根目录执行）：
#   powershell -NoProfile -ExecutionPolicy Bypass -File scripts\split.ps1

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$src  = Join-Path $root 'original\Claude-Fable-5.1.md'
$out  = Join-Path $root 'modules'
$utf8 = New-Object System.Text.UTF8Encoding($false)

# 模块定义：start/end 为原文闭区间行号（基于 2195 行完整原文）
$modules = @(
    @{ id='01'; title='身份与产品信息';       start=1;    end=24;    pct='1.1%';  desc='模型身份、产品矩阵、知识截止日期' }
    @{ id='02'; title='安全与拒答策略';       start=25;   end=82;    pct='2.6%';  desc='儿童安全、危险内容拒绝、版权角色绘制边界、法律财务免责' }
    @{ id='03'; title='语气与格式规范';       start=83;   end=118;   pct='1.6%';  desc='语气、列表规则、工具调用后的回复要求' }
    @{ id='04'; title='用户心理关怀';         start=119;  end=151;   pct='1.5%';  desc='心理健康与饮食失调应对、危机资源、诊断边界' }
    @{ id='05'; title='价值观与知识边界';     start=152;  end=188;   pct='1.7%';  desc='提醒机制、政治中立、犯错回应、知识截止与搜索触发' }
    @{ id='06'; title='记忆系统';             start=189;  end=1026;  pct='38.2%'; desc='记忆文件系统全规范：格式、写入校准、隐私三层禁存、并发、应用规则与示例' }
    @{ id='07'; title='会话结束工具';         start=1027; end=1052;  pct='1.2%';  desc='end_conversation 使用条件与自伤/暴力安全例外' }
    @{ id='08'; title='Artifact持久化存储';   start=1054; end=1126;  pct='3.3%';  desc='Artifact 内 window.storage 键值存储 API 与使用模式' }
    @{ id='09'; title='MCP与应用生态';        start=1127; end=1193;  pct='3.1%';  desc='MCP 连接器建议流程、插件与技能目录推荐' }
    @{ id='10'; title='历史会话检索';         start=1195; end=1224;  pct='1.4%';  desc='conversation_search / recent_chats / read_conversation 规范' }
    @{ id='11'; title='计算机使用与文件产出'; start=1226; end=1439;  pct='9.7%';  desc='SKILL 强制阅读、文件路由、Artifact 判定、视觉路由决策表' }
    @{ id='12'; title='搜索与版权合规';       start=1441; end=1678;  pct='10.8%'; desc='搜索触发条件、版权硬限制（15 词 / 每源 1 次）、有害内容过滤' }
    @{ id='13'; title='图片搜索';             start=1679; end=1745;  pct='3.1%';  desc='图片搜索时机、调用规范、禁搜类别' }
    @{ id='14'; title='工具函数定义';         start=1746; end=1816;  pct='3.2%';  desc='46 个工具函数的 JSONSchema 定义及函数调用格式说明' }
    @{ id='15'; title='运行时注入占位块';     start=1817; end=1823;  pct='0.3%';  desc='profile 与 memory_listing 的运行时注入占位' }
    @{ id='16'; title='Artifact内API调用';    start=1824; end=2024;  pct='9.2%';  desc='Artifact 内调用 Anthropic API 指南：模型选择、结构化输出、文件输入、状态管理' }
    @{ id='17'; title='引用规范';             start=2025; end=2042;  pct='0.8%';  desc='搜索结果引用 cite 标签格式与原文复述禁令' }
    @{ id='18'; title='技能清单';             start=2043; end=2176;  pct='6.1%';  desc='11 个可用技能（SKILL 路由描述）与用户位置上下文' }
    @{ id='19'; title='网络与文件系统配置';   start=2177; end=2195;  pct='0.9%';  desc='bash 网络域名白名单、只读挂载目录' }
)

$lines = [System.IO.File]::ReadAllLines($src, $utf8)
if ($lines.Count -ne 2195) { throw "行数校验失败：期望 2195 行，实际 $($lines.Count) 行" }

foreach ($m in $modules) {
    $slice = $lines[($m.start - 1)..($m.end - 1)]
    $header = @(
        '<!--'
        '========================================================='
        "[模块 $($m.id)/19] $($m.title)"
        "原文行号 : $($m.start) - $($m.end)（共 $($slice.Count) 行，占全文 $($m.pct)）"
        "职责     : $($m.desc)"
        '组装说明 : 组装完整系统提示词时删除本注释块，按编号顺序拼接；'
        '          模块间空行规则见 modules/README.md，或直接运行 scripts/rebuild.ps1。'
        '========================================================='
        '-->'
    )
    $content = (($header + $slice) -join "`n") + "`n"
    $path = Join-Path $out ("{0}-{1}.md" -f $m.id, $m.title)
    [System.IO.File]::WriteAllText($path, $content, $utf8)
    Write-Host ("OK  {0}-{1}.md  行 {2}-{3}（{4} 行）" -f $m.id, $m.title, $m.start, $m.end, $slice.Count)
}

Write-Host ""
Write-Host ("完成：{0} 个模块已写入 {1}" -f $modules.Count, $out)
