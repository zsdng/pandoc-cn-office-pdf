---
name: pandoc-cn-office
description: 中文 Markdown 转 DOCX/PDF 专用：DOCX 输出宋体正文、黑体标题、纯黑白底；PDF 用 Chrome 内核渲染，与原 Markdown/Typora 视图一致。当用户要求 md 转 word/docx、markdown 转 pdf、批量转 PDF 或中文文档转换时使用。
license: MIT
allowed-tools: Read, Write, Bash
metadata:
  version: 1.0.0
  author: song.cai
---

# Markdown → 中文 DOCX / PDF

把 Markdown 转成能直接交付的中文文档：**正文宋体、标题黑体、全篇纯黑、白底**，不会被
Office/WPS 主题染成蓝标题绿背景，也不会把中文渲染成 MS Gothic。

## 触发条件

当用户表达以下意图时启用本 skill：
- "把 md 转成 word / docx"、"markdown 转 pdf"
- "中文文档转换"、"批量转换 md"
- "转出来的 word 字体不对"、"中文变成 MS Gothic"
- "word 背景是绿的"、"标题是蓝的"
- 与通用 pandoc skill 的区别：本 skill 专治中文环境下的字体与配色坑（WPS/Word 打开不跑版）。

## 环境依赖

- 需要 **pandoc 3.x**
- **转 PDF（推荐方式）**：本机需装 **Google Chrome 或 Microsoft Edge**（二选一，脚本自动探测）。
  原理是 pandoc 把 MD 转 HTML + GitHub 风格 CSS，再由 Chrome/Edge 的 headless 打印成 PDF——
  这与 Typora 的渲染内核（Chromium）完全一致，所以结果和原 Markdown/Typora 视图几乎一模一样。
- **转 PDF（备选方式）**：若环境无 Chrome/Edge（如 Linux 服务器/CI），可用 **typst** 引擎（见下文「备选：typst 引擎」）。
- **转 DOCX**：模板依赖 **Windows 系统字体 SimSun（宋体）与 SimHei（黑体）**；非 Windows 见下文第 5 节。

## 快速开始

### 转 DOCX（核心能力）

```bash
# 1) 先解码内嵌的 base64 模板到临时 docx
base64 -d "<skill-dir>/assets/cn-reference.b64" > /tmp/cn-ref.docx
# 2) 用解码出的模板转 DOCX（路径需 Windows 风格）
pandoc input.md -s \
  --reference-doc="$(cygpath -w /tmp/cn-ref.docx | sed 's|\\|/|g')" \
  -o output.docx
```

`<skill-dir>` 为本 skill 所在目录。`-s`（standalone）必须带，否则不套用模板。
> 注：原 `cn-reference.docx` 已改为 base64 文本 `cn-reference.b64` 内嵌（规避 SkillHub 禁止二进制文件的限制），运行时脚本自动解码还原，DOCX 效果不变。

### 转 PDF（推荐：Chrome 内核，与 Typora 渲染一致）

单文件：

```bash
PANDOC="E:/markdown/pandoc-3.10/pandoc.exe"
CHROME="/c/Program Files/Google/Chrome/Application/chrome.exe"
CSS="<skill-dir>/assets/github-md.css"

# 1) MD -> 独立 HTML（内联资源 + GitHub 风格 CSS）。CSS 必须是 Windows 风格绝对路径！
"$PANDOC" input.md -s --embed-resources --standalone --css="$(cygpath -w "$CSS" | sed 's|\\|/|g')" -o _tmp.html

# 2) Chrome headless 打印成 PDF（A4，无页眉页脚）
HTML_WIN="$(cygpath -w "$PWD/_tmp.html" | sed 's|\\|/|g')"
"$CHROME" --headless --disable-gpu --no-pdf-header-footer --print-to-pdf="output.pdf" "file:///$HTML_WIN"
rm -f _tmp.html
```

批量（推荐用脚本，自动探测 Chrome/Edge、循环整个目录）：

```bash
bash <skill-dir>/scripts/md2pdf.sh <md目录> [输出目录，默认与源同目录]
# 例：bash scripts/md2pdf.sh E:/333
```

> 加目录页：HTML 阶段加 `--toc --toc-depth=3`；纸张边距由 `assets/github-md.css` 的
> `body{padding}` 控制，打印参数用 `--no-pdf-header-footer` 去默认页眉页脚。
> pandoc + Chrome 整条链路**不需要 Python**。

### 转 PDF（备选：typst 引擎，无 Chrome 环境时）

当本机没有 Chrome/Edge（如 Linux 服务器、CI）时使用。缺点：typst 的排版哲学与
Typora/Chromium 不同，**视觉上与原 Markdown 视图不像**，且依赖 SimSun/SimHei 字体。

```bash
pandoc input.md -s \
  -V mainfont="SimSun" \
  --template="<skill-dir>/assets/typst-cn-heading.typst" \
  --pdf-engine="<typst-path>" \
  -o output.pdf
```

`typst-cn-heading.typst` 已内置「标题换 SimHei 黑体 + bold」补丁，避免标题被渲染成不粗的宋体。

### 批量转换

```bash
# DOCX：直接用打包脚本（自动解码 base64 模板、循环目录）
bash <skill-dir>/scripts/md2docx.sh <md目录> [输出目录]

# PDF：直接用打包脚本（自动探测 Chrome/Edge、循环目录）
bash <skill-dir>/scripts/md2pdf.sh <md目录> [输出目录]
```

## 环境探测（先跑这个）

```bash
pandoc --version              # 需要 3.x
# PDF 推荐引擎：Chrome / Edge（二选一）
ls "/c/Program Files/Google/Chrome/Application/chrome.exe" 2>/dev/null && echo "Chrome OK"
ls "/c/Program Files (x86)/Microsoft/Edge/Application/msedge.exe" 2>/dev/null && echo "Edge OK"
which typst                   # PDF 备选引擎（无 Chrome 时）
ls /c/Windows/Fonts/ | grep -i -E 'simsun|simhei|msyh'   # 确认中文字体
```

本机已知位置（2026-08 实测，可能变动，用时先验证）：

| 组件 | 路径 | 用途 |
|---|---|---|
| pandoc 3.10 | `E:\markdown\pandoc-3.10\pandoc.exe` | MD→HTML / MD→DOCX |
| typst 0.15.1 | `D:\Typst\typst-x86_64-pc-windows-msvc\typst.exe` | PDF 备选引擎 |
| Chrome | `C:\Program Files\Google\Chrome\Application\chrome.exe` | PDF 推荐引擎（headless 打印） |
| Edge | `C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe` | PDF 备选浏览器 |

## 避坑清单（本 skill 的核心价值）

### 1. pandoc 的 `--pdf-engine` 必须传 Windows 风格路径

Git Bash 的 `/d/Typst/...` 会被 pandoc 判为 not found，必须写 `D:/Typst/...`。
（与 Maven `-f` 参数同类问题。）

```
❌ --pdf-engine=/d/Typst/typst-x86_64-pc-windows-msvc/typst.exe
✅ --pdf-engine=D:/Typst/typst-x86_64-pc-windows-msvc/typst.exe
```

### 2. typst 模板没有 `CJKmainfont` 变量

`pandoc --print-default-template=typst` 里只有 mainfont / mathfont / codefont。
中文**必须**靠 `-V mainfont="SimSun"` 顶上，否则满页方块（tofu）。

### 3. DOCX 中文变 MS Gothic —— 真正的根因

pandoc 输出的每个 run 只写 `<w:rFonts w:hint="eastAsia" />`，**只声明"用东亚字体"但不指定
是哪个**，具体字体完全由 reference.docx 里 `styles.xml` 的 `w:docDefaults` 决定。

而 pandoc **官方** reference.docx 写的是主题引用：

```xml
<w:rFonts w:eastAsiaTheme="minorEastAsia" />   ← 间接引用
```

WPS 顺着 `theme1.xml` 解析出 **MS Gothic**（日文字体），中文就变味了。
本 skill 的模板已改为写死字体名：

```xml
<w:rFonts w:eastAsia="SimSun" />               ← 绕过主题，直接命中宋体
```

**不要试图用脚本去改输出文件**，改 reference.docx 的 docDefaults 才是正解。

### 4. 转换报 `permission denied`

目标 docx 正被 WPS/Word 打开，文件被锁。换文件名输出，或先关闭。

### 5. 模板用的是字体名，不是嵌入字体

模板只记录 `SimSun`/`SimHei` 这两个**名字**，不含字体文件。
Windows 上开箱即用；macOS/Linux 需改用 `Songti SC` / `Noto Serif CJK SC`，
或按下面的方法重新生成模板。

### 6. Chrome headless 打印 PDF：CSS 必须用 Windows 风格路径

pandoc 是原生 Windows 程序，读不到 Git Bash 的 `/d/...` 路径。若 `--css` 传
`/d/.../github-md.css`，会报 `Could not fetch resource` 且样式丢失（PDF 变无样式裸文本）。
**解决**：用 `cygpath -w` 转成 `D:/...` 再传（md2pdf.sh 已内置此处理）。

```bash
# ❌ 报错且丢样式
pandoc in.md -s --css="/d/skill/assets/github-md.css" -o out.html
# ✅ 正确
CSS_WIN="$(cygpath -w "/d/skill/assets/github-md.css" | sed 's|\\|/|g')"
pandoc in.md -s --css="$CSS_WIN" -o out.html
```

### 7. Chrome/Edge 版本与 headless 参数

- 必须带 `--headless --disable-gpu`；新版 Chrome 用 `--headless=new` 也行。
- `--no-pdf-header-footer` 去掉默认页眉页脚（否则每页带文件路径/日期）。
- 打印纸张默认 A4；边距由 CSS 的 `body{padding}` 与 `@page` 控制。
- 本机 Typora 是 **0.9.78 老版本，没有命令行导出能力**（`--export-to` 会报 bad option），
  所以"调用 Typora 批量导出"走不通，本方案用 Chrome 内核等价替代。

## 自制 / 修改模板

当默认字体不满足需求（比如要微软雅黑、要改字号）时，按此流程重做：

```bash
# 1. 取出 pandoc 官方模板（注意用 > 重定向，-o 会把二进制吐到 stdout）
pandoc --print-default-data-file=reference.docx > orig.docx
unzip -q orig.docx -d refwork && cd refwork

# 2. docDefaults 主题引用 → 具体字体名（正文）
sed -i 's|<w:rFonts w:asciiTheme="minorHAnsi" w:eastAsiaTheme="minorEastAsia" w:hAnsiTheme="minorHAnsi" w:cstheme="minorBidi" />|<w:rFonts w:ascii="Times New Roman" w:eastAsia="SimSun" w:hAnsi="Times New Roman" w:cs="Times New Roman" />|' word/styles.xml

# 3. 标题的 major* 主题引用 → 黑体
sed -i 's/w:asciiTheme="majorHAnsi"/w:ascii="SimHei"/g; s/w:eastAsiaTheme="majorEastAsia"/w:eastAsia="SimHei"/g; s/w:hAnsiTheme="majorHAnsi"/w:hAnsi="SimHei"/g' word/styles.xml

# 4. 颜色全部刷黑（跨行元素 sed 够不着，必须用 node）
node -e 'const fs=require("fs");let x=fs.readFileSync("word/styles.xml","utf8");x=x.replace(/<w:color[^>]*>/g,"<w:color w:val=\"000000\" />");fs.writeFileSync("word/styles.xml",x)'

# 5. 打包（本机无 zip 命令，用 PowerShell）
#    PowerShell: Compress-Archive -Path "refwork\*" -DestinationPath out.zip -Force
mv out.zip cn-reference.docx
# 6. 把 docx 编码成 base64 文本（上架 SkillHub 必须，不能放二进制）
base64 -w0 cn-reference.docx > cn-reference.b64
```

**注意**：第 4 步里 `w:color` 元素常跨行（`themeColor` 后换行、`themeTint` 在次行），
sed 的 `<w:color[^>]*\/>` 匹配不到，必须用 node 跨行正则。本机无 perl。

## 验证方法（别用肉眼扫）

```bash
# PDF 中文渲染校验（可选）：用 pypdf 统计首页汉字数与乱码符。
# 注意：转换本身（pandoc + Chrome）不需要 Python，此步仅用于自动核验。
python -c "
import pypdf
t = pypdf.PdfReader('out.pdf').pages[0].extract_text()
print('汉字', sum(1 for c in t if '\u4e00'<=c<='\u9fff'), '| 乱码', t.count('\ufffd'))
"
# 不装 Python 时，直接打开 PDF 肉眼确认即可。
```

```bash
# DOCX：确认 docDefaults 字体 + 无主题残留
unzip -p out.docx word/styles.xml | tr '>' '>\n' | grep -A 4 rPrDefault | grep rFonts
unzip -p out.docx word/styles.xml | grep -o 'Theme="' | wc -l      # 应为 0

# 按样式块抽查某个样式的字体与颜色
unzip -p out.docx word/styles.xml | tr '>' '>\n' \
  | awk '/w:styleId="Heading1"/,/<\/w:style>/' | grep -E 'rFonts|w:color|w:sz'
```

## 排查技巧

- styles.xml 是**单行超长 XML**，`grep -o` 经常失效，先 `tr '>' '>\n'` 拆行再 grep/awk。
- pandoc 会自动往输出注入约 15 个 `*Tok` 语法高亮样式（红/蓝/绿等），是代码高亮配色；
  纯文本文档用不到，不必清理，也不影响显示。
- 单文件验证通过后再批量，避免 12 个文件一起返工。
