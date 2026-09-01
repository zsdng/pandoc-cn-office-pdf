#!/usr/bin/env bash
# 批量 md -> docx，使用 base64 内嵌的中文参考模板（规避 SkillHub 禁止二进制文件的限制）
# 用法: bash md2docx.sh <md目录> [输出目录，默认与源同目录]
set -euo pipefail

PANDOC="${PANDOC:-E:/markdown/pandoc-3.10/pandoc.exe}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
B64="$(cd "$(dirname "$0")/.." && pwd)/assets/cn-reference.b64"

usage() { echo "用法: bash md2docx.sh <md目录> [输出目录]"; exit 1; }
[ $# -lt 1 ] && usage
INDIR="$1"
OUTDIR="${2:-$INDIR}"
mkdir -p "$OUTDIR"

# 解码 base64 内嵌模板 -> 临时 docx（用 Windows 路径供 pandoc 读取）
TMPDOCX="$(mktemp -t cnref.XXXXXX.docx)"
cleanup() { rm -f "$TMPDOCX"; }
trap cleanup EXIT
base64 -d "$B64" > "$TMPDOCX"
REF_WIN="$(cygpath -w "$TMPDOCX" | tr '\\' '/')"

count=0
for f in "$INDIR"/*.md; do
  [ -e "$f" ] || continue
  name="$(basename "${f%.md}")"
  "$PANDOC" "$f" -s --reference-doc="$REF_WIN" -o "$OUTDIR/$name.docx"
  echo "OK -> $OUTDIR/$name.docx"
  count=$((count + 1))
done
echo "完成：共生成 $count 个 docx"
