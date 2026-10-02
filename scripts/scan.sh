#!/usr/bin/env bash
# 开源雷达 · 扫描脚本
# 用法：bash scripts/scan.sh [YYYY-MM-DD]
# 依赖：gh（已认证）、queries.txt
# 说明：逻辑独立成文件，避免塞在 GitHub Actions 的 YAML 里受缩进规则限制。

set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT" || exit 1

DATE="${1:-$(date -u '+%Y-%m-%d')}"
OUT="reports/${DATE}.md"
QUERIES="queries.txt"

if [ ! -f "$QUERIES" ]; then
  echo "错误：找不到 $QUERIES（当前目录 $ROOT）" >&2
  exit 1
fi

# Go 模板：$'...' 会把 \n 变成真实换行，避免在源码里写多行字符串
TPL=$'{{range .}}- **[{{.fullName}}](https://github.com/{{.fullName}})** · {{.stargazersCount}} star{{if .language}} · {{.language}}{{end}} · {{slice .pushedAt 0 10}}\n  {{.description}}\n{{end}}'

mkdir -p reports

{
  echo "# 开源雷达 · ${DATE}"
  echo
  echo "> 自动生成，**未经人工验证**。所有条目仅为线索，可用性需另行核查（走 github-reuse 的源码核查流程）。"
  echo
} > "$OUT"

i=0
fail=0
while IFS= read -r q || [ -n "$q" ]; do
  case "$(printf '%s' "$q" | tr -d '[:space:]')" in
    ''|\#*) continue ;;
  esac
  i=$((i+1))
  echo "扫描 ${i}: ${q}"

  { echo "## ${i}. \`${q}\`"; echo; } >> "$OUT"

  if out="$(gh search repos "$q" \
        --sort=stars --limit 10 --archived=false \
        --json fullName,stargazersCount,language,pushedAt,description \
        --template "$TPL" 2>/dev/null)"; then
    if [ -n "$out" ]; then
      printf '%s\n' "$out" >> "$OUT"
    else
      echo "_本次查询无结果_" >> "$OUT"
    fi
  else
    fail=$((fail+1))
    echo "_查询失败（可能触到 GitHub 搜索速率限制）_" >> "$OUT"
  fi

  echo >> "$OUT"
  sleep 7
done < "$QUERIES"

{
  echo "---"
  echo
  echo "共扫描 ${i} 组关键词，失败 ${fail} 组 · 生成于 $(date -u '+%Y-%m-%d %H:%M UTC')"
} >> "$OUT"

echo "已生成 $OUT（${i} 组关键词，失败 ${fail} 组）"
[ "$fail" -eq 0 ]
