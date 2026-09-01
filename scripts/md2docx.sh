#!/usr/bin/env bash
# 批量 md -> docx，使用本 skill 内置的中文参考模板
# 模板：assets/cn-reference.docx（正文宋体、标题黑体加粗、纯黑白底）
# 用法: bash md2docx.sh <md目录> [输出目录，默认与源同目录]
#
# 依赖：pandoc 3.x
# 可选环境变量：PANDOC  指定 pandoc 路径（默认 E:/markdown/pandoc-3.10/pandoc.exe）

set -euo pipefail

PANDOC="${PANDOC:-E:/markdown/pandoc-3.10/pandoc.exe}"
SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
REF="$SKILL_DIR/assets/cn-reference.docx"

usage() { echo "用法: bash md2docx.sh <md目录> [输出目录]"; exit 1; }
[ $# -lt 1 ] && usage
INDIR="$1"
OUTDIR="${2:-$INDIR}"
mkdir -p "$OUTDIR"

if [ ! -f "$PANDOC" ]; then echo "找不到 pandoc: $PANDOC（可用 PANDOC=... 覆盖）"; exit 1; fi
if [ ! -f "$REF" ]; then echo "找不到模板: $REF"; exit 1; fi

# pandoc 是 Windows 程序，reference-doc 需传 Windows 风格路径
REF_WIN="$(cygpath -w "$REF" | tr '\\' '/')"

count=0
for f in "$INDIR"/*.md; do
  [ -e "$f" ] || continue
  name="$(basename "${f%.md}")"
  "$PANDOC" "$f" -s --reference-doc="$REF_WIN" -o "$OUTDIR/$name.docx"
  echo "OK -> $OUTDIR/$name.docx"
  count=$((count + 1))
done
echo "完成：共生成 $count 个 docx"
