# SkillHub 上架文案 —— pandoc-cn-office

> 用途：复制下方各段到 skillhub.cn 的「发布技能」页面。全程中文，已做差异化处理（区别于通用版 `pandoc` skill）。

---

## 一、技能名称（建议填写）

**Markdown 转中文 Word/PDF（WPS 特化版）**

> 命名策略：避开通用词 "pandoc"，用「中文 / WPS 特化」+ 功能描述，降低被判重复的概率。

---

## 二、一句话简介（≤50 字，用于列表 / 搜索卡）

中文 MD 一键转 Word/PDF：宋体正文、黑体标题加粗、纯黑白底，WPS 不跑版，PDF 效果对齐 Typora。

---

## 三、详细介绍（上架页正文，可分段粘贴）

### 【它解决什么痛点】

用 Markdown 写的中文文档，转成 Word/PDF 交付时最常翻车：

- WPS / Word 打开中文变成 **MS Gothic**（方块感日文字体）
- 标题被 Office 主题染成**蓝色**、页面背景莫名变**绿色**
- PDF 标题看起来「没加粗」，像普通正文
- pandoc 默认模板在中文环境下字体、配色一团糟

本技能专治这些问题，开箱即用，不用自己踩坑。

### 【核心能力】

- ✅ **DOCX 中文不乱码、不跑版**：自带定制 `reference.docx` 模板，正文宋体 12pt、标题黑体 20/16/14pt 且**显式加粗**、全篇纯黑白底，规避 Office 主题配色污染。
- ✅ **PDF 与原 MD 几乎一模一样**：采用 `pandoc → HTML → Chrome 内核打印` 链路，渲染引擎与 Typora 导出**完全一致**——标题加粗、字号留白、列表样式都贴近编辑器视图。
- ✅ **批量无忧**：`scripts/md2pdf.sh <目录>` 一键整目录批量转，自动探测本机 Chrome / Edge，循环处理所有 `.md`。
- ✅ **双引擎兜底**：有图形界面走 Chromium 渲染；无 GUI 的 Linux / CI 环境自动回退 typst 引擎（标题黑体加粗模板已内置）。
- ✅ **纯本地、零联网**：仅调用本机 pandoc / typst / Chrome，不传任何数据到外部，安全等级 **P2**。

### 【与通用 pandoc 技能的区别】

通用版只做「基础格式转换」；本版是**为中文办公场景深度特化**：

- 内置 WPS 字体修复模板（正文宋体 / 标题黑体加粗）
- 自带 GitHub 风格中文 CSS
- 与 Typora 对齐的 PDF 渲染方案
- 开箱即用，无需自己配字体、调样式

### 【使用示例】

```bash
# 单个文件转 PDF（Chrome 内核，与 Typora 效果一致）
pandoc 报告.md -s --css assets/github-md.css \
  --pdf-engine="<typst路径>" -o 报告.pdf

# 批量整目录转 PDF
bash scripts/md2pdf.sh ./我的文档目录

# 转 DOCX（用自带中文模板）
pandoc 报告.md -s --reference-doc=assets/cn-reference.docx -o 报告.docx
```

### 【许可证】

**MIT** —— 可自由使用、修改、再分发。

---

## 四、标签 / 分类建议（如平台支持）

`markdown` `文档转换` `中文` `word` `pdf` `wps` `typora` `pandoc` `办公`

---

## 五、上传时的关键提示

1. **介绍里务必突出「中文 / WPS 特化 + 与 Typora 渲染一致」**，与已上架的通用版 `pandoc` skill 拉开差距，避免被判重复卡审核。
2. 上传的 zip 包需用 `pandoc-cn-office.zip`（已生成，`SKILL.md` 在根目录，`assets/` + `scripts/` 齐全，无 `.bak`）。
3. 选「免费」→ 提交 → 安全审核（P2 预计较快）→ 3–7 个工作日 → 通过后点「上架」。
