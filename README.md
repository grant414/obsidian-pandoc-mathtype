# Obsidian → Pandoc → DOCX：保留 LaTeX 公式的 MathType 工作流

从 Obsidian 导出 Markdown，用 Pandoc 生成 Word 文档时，公式处理是个常见痛点。

本文提供**两种工作流**，以**方案 B（保留 LaTeX → MathType）**为主线详细展开，方案 A（Word 原生公式）作为备选。

---

## 两种工作流速览

| 工作流 | 适合对象 | 优点 | 缺点 |
|--------|----------|------|------|
| **A：Word 原生公式（OMML）** | 大多数用户，无需额外软件 | 即开即用，兼容性好 | 公式不可逆为 LaTeX |
| **B：保留 LaTeX → MathType** | 已使用 MathType 的用户，追求公式排版质量 | 保留完整 LaTeX 源码，MathType 公式更美观 | 需要 MathType + Lua Filter |

> **如果你已经在用 MathType**，方案 B 能让你的 Obsidian → Word 工作流无缝衔接，且 MathType 转出的公式排版优于 Word 原生公式。
>
> **如果你不用 MathType**，跳到[方案 A](#方案-a-word-原生公式推荐给大多数人) 即可。

---

## 方案 B（主线）：保留 LaTeX → MathType

### 工作流全景

```
Obsidian（Export Markdown）
       ↓
Pandoc（--lua-filter=keep-tex-math.lua）
       ↓
Word（LaTeX 源码以纯文本形式保留）
       ↓
MathType Toggle TeX（一键转换所有公式）
       ↓
MathType 公式 ✓
```

### Pandoc 命令

```bash
pandoc input.md \
  --lua-filter=keep-tex-math.lua \
  --reference-doc=custom-reference.docx \
  -o output.docx
```

**参数说明：**

| 参数 | 作用 |
|------|------|
| `--lua-filter=keep-tex-math.lua` | **核心**——将数学 AST 输出为纯文本 LaTeX 源码 |
| `--reference-doc=...` | 指定 Word 模板（样式、字体、页边距等） |

**不需要**以下参数：

- ❌ `--mathml` —— 只影响 HTML Writer，对 docx 无效
- ❌ `--from markdown-tex_math_dollars` —— 会破坏部分 LaTeX 命令

### Lua Filter 原理

Pandoc 内部将文档解析为 AST（抽象语法树），数学表达式被表示为 `Math` 元素。默认情况下，Pandoc 的 docx Writer 会将 `Math` 元素转换为 Word 的 OMML（Office Math Markup Language）公式对象。

本 Filter 在写入之前拦截 `Math` 元素，将其替换为 `Code`（纯文本），从而保留原始的 LaTeX 源码：

```lua
-- keep-tex-math.lua

function Math(el)
    if el.mathtype == "DisplayMath" then
        return pandoc.Code("\\[" .. el.text .. "\\]")
    else
        return pandoc.Code("$" .. el.text .. "$")
    end
end
```

### 为什么显示公式用 `\[...\]` 而不是 `$$...$$`

MathType 6.9 的 Toggle TeX 对两种格式的处理不同：

| 格式 | MathType Toggle TeX 结果 |
|------|------------------------|
| `\[...\]` | ✅ 正常转换，自动居中 |
| `$$...$$` | ⚠️ 遗留多余的 `$` 符号 |

此外，`\[...\]` 也是 LaTeX（amsmath）推荐的标准写法，对 TeXstudio、Overleaf 等其他工具兼容性更好。

### MathType 操作

1. 在 Word 中打开生成的 `.docx` 文件
2. 全选（Ctrl+A）
3. MathType 选项卡 → Toggle TeX（或快捷键 Alt+\）
4. 所有 `$...$` 和 `\[...\]` 一键转换为 MathType 公式

### 示例

**Markdown 输入：**

```markdown
这是行内公式 $a \cdot b$。

这是显示公式：
$$
\int_{0}^{1} x^2 \, dx
$$
```

**Word 输出（使用 Filter 后）：**

```
这是行内公式 $a \cdot b$。

\[
\int_{0}^{1} x^2 \, dx
\]
```

**MathType Toggle TeX 后：**

行内公式和显示公式均转换为 MathType 公式对象，所有 LaTeX 命令（`\cdot`、`\int`、`\begin{aligned}` 等）完整保留。

### 额外好处

这套方法不仅适用于 MathType。`\[...\]` 格式对以下工具同样友好：

- TeXstudio / Overleaf —— 直接粘贴可用
- VS Code + LaTeX Workshop —— 语法高亮正常
- 任何支持 LaTeX 的编辑器

如果你将来迁移到纯 LaTeX 工作流，Markdown 中的数学表达式无需额外修改。

---

## 方案 A（备选）：Word 原生公式

如果你不需要 MathType，希望公式以 Word 原生格式（OMML）呈现：

### Pandoc 命令

```bash
pandoc input.md \
  --reference-doc=custom-reference.docx \
  -o output.docx
```

**关键点：**

- ✅ **Export from → Markdown**（Obsidian 导出时选 Markdown 格式）
- ❌ 不要加 `--mathml`（对 docx 无作用）
- ❌ 不要加 `--from markdown-tex_math_dollars`（会破坏公式）
- ✅ 不需任何数学参数，Pandoc 默认将 `$...$` / `$$...$$` 转为 OMML

这样得到的 Word 文档中，公式即为可编辑的 Word 原生公式对象。

---

## 踩坑记录（核心价值）

以下是在排查过程中实际遇到的问题，按"方法 → 结果 → 原因"整理。这张表是整个文档中价值最高的部分，因为大多数遇到同样问题的人都在这些方案之间反复尝试。

| 导出格式 | Pandoc 参数 | 结果 | 原因 |
|----------|-------------|------|------|
| **HTML** | 默认 | ❌ 公式丢失 | HTML 已由 MathJax 渲染为图形或样式，Pandoc 无法恢复数学 AST |
| **Markdown** | 默认 | ✅ Word 原生公式（OMML） | Pandoc 正常识别 `$...$` / `$$...$$`，转换为 Word 数学对象 |
| **HTML** | `--from markdown-tex_math_dollars` | ❌ 模板样式异常 | `--from` 强制按 Markdown 解析，但实际输入是 HTML，两者不匹配 |
| **Markdown** | `--from markdown-tex_math_dollars` | ⚠️ 保留 TeX 但部分命令丢失 | 数学不以 Math AST 解析，Markdown Reader 会处理反斜杠 |
| **Markdown** | `--lua-filter=keep-tex-math.lua` | ✅ 完整保留 TeX | 先正常解析数学，再由 Filter 输出为纯文本 |
| **Markdown** | Lua + `pandoc.Str()` | ⚠️ 基本可用但有兼容风险 | `Str` 在某些 Pandoc Writer 中可能被转义 |
| **Markdown** | **Lua + `pandoc.Code()`** | ✅ **推荐方案** | `Code` 是内联代码节点，所有 Writer 一致处理 |
| — | DisplayMath 输出 `$$...$$` | ⚠️ MathType 遗留 `$` | MathType 6.9 Toggle TeX 对 `$$` 兼容不完整 |
| — | **DisplayMath 输出 `\[...\]`** | ✅ **推荐** | MathType 6.9 正常识别并自动居中 |

---

## FAQ

### Q: 为什么不用 `--mathml`？

`--mathml` 只影响 Pandoc 的 **HTML Writer**，对 docx Writer 无作用。它告诉 Pandoc "将数学输出为 MathML 标签"，但 docx 格式不使用 MathML。

### Q: 为什么一定要 Export Markdown？

Pandoc 需要读取 Markdown 中的数学 AST（`$...$` / `$$...$$`）。如果用 HTML 导出，Obsidian 插件已调用 MathJax 将数学渲染为 HTML/CSS，Pandoc 无法从渲染结果中恢复数学表达式。

### Q: 为什么不用 `--from markdown-tex_math_dollars`？

这个参数告诉 Pandoc "不解析 `$...$` 为数学"，将其视为普通文本。问题在于 Pandoc 的 Markdown Reader 仍会处理反斜杠转义，导致 `\cdot`、`\operatorname` 等 LaTeX 命令中的反斜杠被消费，造成命令丢失。

### Q: 为什么显示公式用 `\[...\]` 而不是 `$$...$$`？

MathType 6.9 对 `\[...\]` 的支持更完整，Toggle TeX 后自动转换为居中公式，不会遗留 `$` 符号。同时 `\[...\]` 也是 LaTeX 的推荐标准写法。

### Q: 方案 B 得到的 docx 里公式是纯文本，还能在 Word 里正常编辑吗？

纯文本状态下的公式源码**不能编辑**——它只是文本。这是为下一步 MathType Toggle TeX 准备的中间状态。转换后公式成为 MathType 公式对象，可在 MathType 中双击编辑。

---

## 文件说明

| 文件 | 说明 |
|------|------|
| `keep-tex-math.lua` | Pandoc Lua Filter —— 将数学 AST 输出为纯文本 LaTeX |
| `example.md` | 示例 Markdown 文档，覆盖行内公式、显示公式、矩阵、分段函数等 |
| `example.docx` | 示例输出（使用 Filter 后的结果，供参考） |

### 使用示例

```bash
# 安装 Pandoc 后，在仓库目录下执行：
pandoc example.md \
  --lua-filter=keep-tex-math.lua \
  --reference-doc=your-template.docx \
  -o example.docx
```

然后在 Word 中打开 `example-output.docx`，用 MathType Toggle TeX 一键转换即可。

---

## 许可证

MIT
