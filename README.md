# 开源雷达（open-source-radar）

**一句话**：每周自动去 GitHub 发现"值得吸收的项目"，产出报告，不依赖你电脑开机。

它补的是这样一个缺口——你已装的 `open-source-updates-report` 只能追踪**固定的 3 个仓库**（llama.cpp / hermes-agent / opencode），
做不到"开放式发现更好的新项目"。这个雷达做的就是开放式发现。

---

## 为什么放在 GitHub Actions 上跑

本机定时任务有个硬伤：**你电脑关机、或「设置 → 通用 → 锁屏运行」是关闭状态，任务就不会触发。**
GitHub Actions 的定时工作流跑在 GitHub 的服务器上，与你本机无关。

成本：公开仓库的 Actions 分钟数**免费无限**；私有仓库用你 Pro 的 3,000 分钟/月，这个任务每周只跑一次、每次不到 1 分钟。

---

## 目录结构

```
open-source-radar/
├── README.md                      本文件
├── queries.txt                    搜索关键词配置（改这里就能换方向）
└── .github/workflows/weekly-radar.yml   云端定时工作流
```

跑起来之后会自动多出：

```
└── reports/2026-10-06.md          每周一自动生成的报告
```

---

## 本地先跑一次（不推仓库也能验证）

```bash
cd "C:/Users/asus/WorkBuddy/2026-10-02-09-49-26/open-source-radar"
bash scripts/scan.sh
```

产出写到 `reports/YYYY-MM-DD.md`。这是一条真实可用的本地路径，不依赖云端。

> **踩过的坑**：`cd open-source-radar` 会失败——`open-source-radar` 在 WorkBuddy 工作区里，
> **不在你的用户主目录**。在 `~` 下执行会报 `No such file or directory`，接着 `gh` 会提示
> `current directory is not a git repository`。所以请用上面的绝对路径。

## 怎么部署到云端（2 条命令）

前提：`gh` 已登录（你本机已满足：账号 `bobo070314`），且当前在该目录下。

```bash
gh repo create open-source-radar --public --source=. --push
gh workflow run weekly-radar.yml          # 立刻手动跑一次验证
```

`gh repo create` 要求当前目录**已经是一个 git 仓库**（本仓库已在本地 `git init` 并完成首次提交）。

跑完后看结果：

```bash
gh run list --limit 5
gh run view --log
```

> **想先不公开？** 把 `--public` 换成 `--private`。功能一样，只是会消耗 Pro 的 3,000 分钟配额（每周一约 1 分钟，够用几十年）。

> **注意**：你的令牌没有 `delete_repo` 权限，我无法替你删仓库。所以仓库一旦创建只能你自己删——这也是我没有替你直接创建的原因。

---

## 改方向

打开 `queries.txt`，一行一个 GitHub 搜索表达式。默认按你的实际技术栈配好了：

- `topic:ai-agent` 高星活跃项目
- `agent harness / skills / memory` 方向
- 本年度新起的高星项目
- 定时运行 / 自动化方向

想加"前端""数据""量化"就自己加一行，格式即 GitHub 搜索语法，例如：

```
topic:quantitative-trading stars:>300 pushed:>2026-06-01
```

---

## 频率

默认 **每周一 09:00（北京时间）**，即 UTC 周一 01:00，写在 workflow 的 `cron` 里：

```yaml
- cron: "0 1 * * 1"
```

改成每天：`0 1 * * *`；改成工作日：`0 1 * * 1-5`。

---

## 和其他技能的分工

| 环节 | 由谁负责 | 状态 |
|---|---|---|
| 追踪已知的 3 个仓库更新 | `open-source-updates-report` | 已装 |
| **开放式发现新项目** | **本雷达** | 本次新增 |
| 拆解、审查许可证与适配性、验证后集成 | `github-reuse` | 已装 |
| 模糊议题收敛成可回答的问题 | `hourglass-asking-method` | 已装 |

报告产出后，把感兴趣的项目丢给 `github-reuse` 深挖即可。

---

## 验证记录（2026-10-02，端到端）

**两次云端运行全部 success**，产出已自动提交回仓库。

| 检查项 | 结果 |
|---|---|
| 工作流 YAML 语法 | 通过（PyYAML 解析） |
| `scripts/scan.sh` bash 语法 | 通过（`bash -n`） |
| 本地实跑 | 11 组关键词，失败 0 组 |
| 仓库内换行符 | 全部 LF，CR 字符数 0 |
| 云端运行 1（checkout@v4） | success，1m30s，产出已提交 |
| 云端运行 2（checkout@v7） | success，1m29s，无弃用告警 |

### 过程中修掉的三个坑（每一个都会让云端直接失败）

1. **YAML 缩进被模板字符串撑破** —— 最初把含真实换行的 Go 模板塞进 `run: |` 块标量，
   PyYAML 在第 56 行报 `ScannerError: could not find expected ':'`。
   已把扫描逻辑抽成独立文件 `scripts/scan.sh`，workflow 只负责调用，彻底规避缩进规则。
2. **CRLF 换行污染** —— Windows 的 `core.autocrlf=true` 会在检出时把 `.sh` 变成 CRLF，
   推到 Linux runner 上 bash 直接报 `$'\r': command not found`。已加 `.gitattributes` 强制 `eol=lf`。
3. **Markdown 表格被撑破** —— 项目简介里只要出现 `|` 就会破坏表格结构。输出已改为列表格式。

### 运行信息

- 仓库：https://github.com/bobo070314/open-source-radar （公开）
- 工作流：`weekly-open-source-radar`，状态 `active`
- 排程：每周一 09:00 北京时间（UTC `0 1 * * 1`）
- 手动触发：`gh workflow run weekly-radar.yml`
- 查看运行：`gh run list --limit 5`

---

## 一个诚实的说明

雷达只做**发现**：它输出的是"候选清单 + 元数据"，**不代表这些项目可用**。
star 数高不等于代码好，更不等于适合你。真正的判断要走 `github-reuse` 的证据分层
（源码核查 → 局部实测 → 集成验证），在没走完之前，一切都只能算"未验证线索"。
