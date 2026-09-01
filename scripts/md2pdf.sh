#!/bin/bash
# 批量把目录下所有 .md 转成「与 Typora 渲染一致」的 PDF
# 原理：pandoc 转 HTML（GitHub 风格 CSS） + Chrome/Edge headless 打印（同 Typora 的 Chromium 内核）
# 用法：bash md2pdf.sh <md目录>  [输出目录，默认与源同目录]
#
# 依赖：
#   - pandoc 3.x
#   - 本机已装 Google Chrome 或 Microsoft Edge（二选一自动探测）
#   - 无需 Python / 无需 Typora
# 可选环境变量：
#   PANDOC  指定 pandoc 可执行文件路径（默认 E:/markdown/pandoc-3.10/pandoc.exe）

set -u

SRC_DIR="${1:-.}"
OUT_DIR="${2:-$SRC_DIR}"

# ---- pandoc 路径：可用环境变量覆盖 ----
PANDOC="${PANDOC:-E:/markdown/pandoc-3.10/pandoc.exe}"

# ---- 浏览器探测：Chrome 优先，其次 Edge ----
CHROME_CANDIDATES=(
  "/c/Program Files/Google/Chrome/Application/chrome.exe"
  "/c/Program Files (x86)/Google/Chrome/Application/chrome.exe"
  "/c/Program Files/Microsoft/Edge/Application/msedge.exe"
  "/c/Program Files (x86)/Microsoft/Edge/Application/msedge.exe"
)
CHROME=""
for c in "${CHROME_CANDIDATES[@]}"; do
  if [ -f "$c" ]; then CHROME="$c"; break; fi
done

# ---- CSS：skill 的 assets/github-md.css（脚本在 scripts/，上溯一级即 skill 根） ----
CSS_SRC="$(cd "$(dirname "$0")/.." && pwd)/assets/github-md.css"
if command -v cygpath >/dev/null 2>&1; then
  CSS="$(cygpath -w "$CSS_SRC" | tr '\\' '/')"
else
  CSS="$CSS_SRC"
fi

if [ ! -d "$SRC_DIR" ]; then echo "源目录不存在: $SRC_DIR"; exit 1; fi
if [ ! -f "$PANDOC" ]; then echo "找不到 pandoc: $PANDOC（可用 PANDOC=... 环境变量覆盖）"; exit 1; fi
if [ -z "$CHROME" ]; then echo "未找到 Chrome/Edge，请安装其一"; exit 1; fi
if [ ! -f "$CSS" ]; then echo "找不到 CSS: $CSS"; exit 1; fi

mkdir -p "$OUT_DIR"
count=0
for f in "$SRC_DIR"/*.md; do
  [ -e "$f" ] || continue
  name="$(basename "$f" .md)"
  html="$OUT_DIR/${name}__tmp.html"
  pdf="$OUT_DIR/${name}.pdf"

  # 1) MD -> 独立 HTML（内联资源 + GitHub 风格 CSS）
  "$PANDOC" "$f" -s --embed-resources --standalone --css="$CSS" -o "$html" || { echo "FAIL md: $f"; continue; }

  # 2) Chrome/Edge headless 把 HTML 打印成 PDF（A4 默认纸张，无页眉页脚）
  html_win="$(cygpath -w "$html" 2>/dev/null || echo "$html")"
  file_url="file:///$(echo "$html_win" | tr '\\' '/')"
  "$CHROME" --headless --disable-gpu --no-pdf-header-footer --print-to-pdf="$pdf" "$file_url" >/dev/null 2>&1
  rc=$?
  rm -f "$html"
  if [ $rc -eq 0 ] && [ -f "$pdf" ]; then
    echo "OK  -> $pdf"
    count=$((count+1))
  else
    echo "FAIL pdf: $f (chrome rc=$rc)"
  fi
done
echo "完成：成功转换 $count 个文件"
