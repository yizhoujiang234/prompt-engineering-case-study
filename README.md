# Claude Fable 5.1 · 提示词工程项目

**🚀 在线体验提示词优化器（免安装、无需配置）：<https://yizhoujiang234.github.io/prompt-engineering-case-study/>**

把一份 **2195 行 / 约 275 KB 的生产级消费类 AI 助手系统提示词**当作软件工程对象来研究：
无损拆解为 19 个可维护模块，提炼 10 个可复用的提示词设计模式，配套评审清单、
变体组装脚本、回归用例库，以及一个基于同一方法论的**提示词优化器**网页工具。

```
提示词/
├── Claude-Fable-提示词工程项目/   # 核心研究项目（模块化拆解 + 文档 + 脚本 + evals）
│   ├── original/                  #   原文基准副本（只读）
│   ├── modules/                   #   19 个模块（可逐字节还原原文）
│   ├── docs/                      #   架构总览 / 设计模式解析 / 维护与复用指南
│   ├── templates/                 #   系统提示词骨架 / 评审清单
│   ├── evals/                     #   26 条回归用例（源自原文自带示例）
│   └── scripts/                   #   split / rebuild / check-refs / run-evals
└── 提示词优化器/                  # 网页工具：输入粗略想法 → 生成结构化提示词
    ├── index.html                 #   Vue 3 单文件应用（本地运行时，离线可用）
    └── vue.global.prod.js
```

## 两个部分

### 1. Claude-Fable-提示词工程项目

对原文的五层架构解剖（身份/安全/行为/能力/运行时）与设计模式提炼，
亮点是**全程可校验**：

| 校验 | 命令 | 说明 |
|---|---|---|
| 无损还原 | `scripts\rebuild.ps1` | 19 个模块重组后与原文逐字节一致（PASS） |
| 变体组装 | `scripts\rebuild.ps1 -Include '01,02,03,05,14'` | 按配方只拼子集 → rebuilt-variant.md |
| 引用防失效 | `scripts\check-refs.ps1` | 校验 19 个模块头声明 + 全文档 58 处行号引用 |
| 回归冒烟 | `scripts\run-evals.ps1 -SystemFile rebuilt.md -Base <API> -Model <模型> -Key <KEY>` | 19 条自动断言 + 7 条人工评审 |

快速开始、模块清单、方法论文档见 [Claude-Fable-提示词工程项目/README.md](Claude-Fable-提示词工程项目/README.md)。

### 2. 提示词优化器（网页工具）

把上述方法论做成产品：左侧简单写"我要干嘛"，右侧得到结构化优化后的提示词
（任务提示词 / 系统提示词两种骨架），附评审检查与方法论溯源。

- **本地模式**：纯浏览器内运行，不联网、无需任何配置；
- **AI 模式**：可选接入 DeepSeek / Kimi / 通义 / OpenAI / Anthropic（密钥只存本机 localStorage）；
- **双视图**：Markdown 渲染 / 源码，复制得到纯文本。

打开方式：直接双击 `提示词优化器/index.html`，或用在线版：<https://yizhoujiang234.github.io/prompt-engineering-case-study/>（GitHub Pages，自动跳转）。

## 核心发现（TL;DR）

1. **记忆系统独占 38.2%**——这份提示词的重心不是"聊天"而是"跨会话个性化"，
   含完整三层隐私禁存模型与行为护栏；
2. **示例即规范**：26 个示例几乎都配正反两面，"何时不用"与"边界"两组反直觉地重要；
3. **用判断测试代替死规则**："一个月后还成立吗"、"引用 <15 词"；
4. **能力靠路由组织**：多出口场景必有显式决策顺序 + 兜底出口；
5. **工具 description 本身就是提示词工程**：何时用 / 何时不用 / 优先级全写在描述里。

## 环境要求

- 脚本：Windows PowerShell 5.1+（或 PowerShell 7，跨平台）；无需其他依赖
- 优化器：任意现代浏览器；AI 模式需自行准备模型服务商的 API Key
- run-evals：调用任意 OpenAI 兼容 API（DeepSeek / Kimi / 通义 / OpenAI 等）

## 免责声明

本仓库包含的原始系统提示词文本（`original/`、`modules/` 等）版权归原作者所有，
此处仅以研究与学习为目的进行引用和分析，不代表作者立场，也不构成任何使用授权。
若你是权利人并认为不妥，请提 issue，我会及时处理。

## 许可证

本仓库原创衍生内容（docs/、templates/、evals/、scripts/、提示词优化器及各 README）
以 [MIT License](LICENSE) 发布；`original/` 与 `modules/` 中的第三方系统提示词原文
**不在** MIT 覆盖范围内，版权归原作者所有（详见 LICENSE 文件末尾的许可范围说明）。

## Star 路线

- 只对工具感兴趣 → 直接用 `提示词优化器/index.html`
- 想学提示词工程 → 读 `docs/02-设计模式解析.md`（10 个模式，含原文行号证据）
- 想搭建自己的系统提示词 → 套 `templates/系统提示词骨架.md`，过 `templates/提示词评审清单.md`
- 想基于原文二次开发 → 先读 `docs/03-维护与复用指南.md`，改动后跑三道校验
