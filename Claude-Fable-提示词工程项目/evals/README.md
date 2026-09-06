# evals/ — 回归用例库

> 把原文自带的示例（docs/03 第 6 节所说的"现成 eval 用例库"）落成了可执行的用例文件。
> 用例来源与断言依据均出自 `original/Claude-Fable-5.1.md`，`source` 字段为原文行号。

## 文件

- `cases.jsonl` — 26 条用例（记忆 17 + 版权 3 + 搜索路由 5 + 拒答 1），每行一个 JSON。

## 用例字段

| 字段 | 含义 |
|---|---|
| `id` | 用例编号（mem-* / c-* / s-* / r-*） |
| `category` / `module` / `group` | 类别、所属模块、示例组（对应 docs/02 模式 8 的四类分组） |
| `source` | 原文行号范围 |
| `memories` | 仅记忆用例：模拟 memory_read 返回的用户记忆 |
| `input` | 用户输入 |
| `expect_present` | 自动断言：回复中必须出现的子串（不区分大小写，全部满足才 PASS） |
| `expect_absent` | 自动断言：回复中不得出现的子串（出现任一即 FAIL） |
| `mode` | `auto`（脚本自动判定）/ `manual`（需人工或裁判模型，`rubric` 为评分要点） |
| `notes` | 出题理由，通常即原文 rationale 的浓缩 |

## 怎么跑

### 自动用例（15 条）

```powershell
# -SystemFile 传被测系统提示词（全量 rebuilt.md 或变体文件均可）
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\run-evals.ps1 `
    -SystemFile rebuilt.md `
    -Base https://api.deepseek.com/v1 `
    -Model deepseek-v4-flash `
    -Key sk-xxxx

# 只跑记忆类：
#   追加 -Filter mem
# 只校验用例文件格式、不调 API：
#   追加 -DryRun
```

断言是**子串级冒烟检查**，不是语义判定——PASS 只说明行为关键词出现/翻车词未出现，
不等于回答质量达标。

### 人工 / 裁判模型用例（11 条）

`mode:"manual"` 的用例（版权对比 c-02、搜索路由 s-01~s-05、拒答 r-01）断言的是
"要不要搜索、路由到哪个工具、是否构成变体侵权"这类需要理解上下文的判断，
脚本子串匹配会误判，请按 `rubric` 字段人工复核，或把 rubric 喂给裁判模型打分。

搜索路由类的正确跑法：给被测系统提示词挂上真实工具（web_search / 连接器），
观察工具调用行为，而不是只看文本回复。

## 已知局限

1. 记忆用例把 `memories` 作为系统提示词附注注入，模拟的是 memory_read 返回后的状态；
2. auto 断言关键词取自原文 good/bad response 的特征词，被测模型换个说法可能误判；
3. 这批用例是**原文在理想模型上的参考行为**，换到新模型上应先跑基线记录得分，
   再用于改动后的回归对比——目标是"不退化"，不是"必须满分"。
