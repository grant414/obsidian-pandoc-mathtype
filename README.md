# Obsidian → Pandoc → DOCX：保留 LaTeX 公式的 MathType 工作流

Obsidian 是一个强大的知识管理工具。然而，当 Obsidian 管理的 Markdown 文档中包含大量 LaTeX 公式，需要导出为 Word 格式时，公式处理就成了一个常见的痛点——默认方法导出的是 Word 原生公式（OMML），美观性稍差，且无法保留 LaTeX 源码供后续编辑。

本文提供一套**高效且美观的解决方案**：通过 Pandoc Lua Filter 保留完整的 LaTeX 源码，在 Word 中由 MathType 一键转换为高质量公式。同时提供两种工作流，以**方案 A（保留 LaTeX → MathType）**为主线详细展开，方案 B（Word 原生公式）作为备选。

---

## 两种工作流速览

| 工作流 | 适合对象 | 优点 | 缺点 |
|--------|----------|------|------|
| **A：保留 LaTeX → MathType** | 已使用 MathType 的用户，追求公式排版质量 | 保留完整 LaTeX 源码，MathType 公式更美观 | 需要 MathType + Lua Filter |
| **B：Word 原生公式（OMML）** | 大多数用户，无需额外软件 | 即开即用，兼容性好 | 公式不可逆为 LaTeX |

> **如果你已经在用 MathType**，方案 A 能让你的 Obsidian → Word 工作流无缝衔接，且 MathType 转出的公式排版优于 Word 原生公式。该方案适用于所有 Markdown 文档，不仅限于 Obsidian 环境。
>
> **如果你不用 MathType**，跳到[方案 B](#方案-b备选word-原生公式) 即可。

---

## 方案 A（主线）：保留 LaTeX → MathType

### 工作流全景

```
Obsidian（Export files from → Markdown）
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
| `--reference-doc=...` | 指定 Word 模板（样式、字体、页边距等）——`custom-reference.docx` 是你自己建的模板文件，Pandoc 安装目录下有一个参考模板可以修改 |

### 在 Obsidian 中使用

如果你使用 Obsidian 社区的 **Pandoc Plugin**，进行以下设置：

1. **Export files from HTML or markdown?** → 选择 **Markdown**（插件基于 HTML 导出时公式已被 MathJax 渲染，Pandoc 无法恢复）
2. 在 `Extra Pandoc arguments` 中填入：

```
--lua-filter=C:/Tools/pandoc/keep-tex-math.lua
--reference-doc=custom-reference.docx
```

> 将 Lua Filter 文件放在固定路径（如 `C:/Tools/pandoc/`），方便多个文档库共用。

### Lua Filter 原理

Pandoc 内部将文档解析为 AST（抽象语法树），数学表达式被表示为 `Math` 元素。默认情况下，Pandoc 的 docx Writer 会将 `Math` 元素转换为 Word 的 OMML（Office Math Markup Language）公式对象。

本 Filter 在写入之前拦截 `Math` 元素，将其替换为 `Code`（纯文本），从而保留原始的 LaTeX 源码，并对内容做以下自动处理：

```lua
-- keep-tex-math.lua

function Math(el)
    local tex = el.text

    -- Strip equation numbers and labels
    tex = tex:gsub("\\tag%s*%b{}", "")
    tex = tex:gsub("\\label%s*%b{}", "")

    -- Convert aligned → align (MathType supports align, not aligned)
    tex = tex:gsub("\\begin{aligned}", "\\begin{align}")
    tex = tex:gsub("\\end{aligned}", "\\end{align}")

    -- Move & before = to start of line (avoids extra spaces)
    local lines = {}
    for line in tex:gmatch("[^\n]+") do
        line = line:gsub("^(.-)&= *(.*)$", "& %1=%2")
        table.insert(lines, line)
    end
    tex = table.concat(lines, "\n")

    if el.mathtype == "DisplayMath" then
        return pandoc.Code("\\[" .. tex .. "\\]")
    else
        return pandoc.Code("$" .. tex .. "$")
    end
end
```

Filter 的自动处理说明：

| 处理 | 说明 |
|------|------|
| `\tag{...}` / `\label{...}` 剥离 | 移除公式编号标记，避免出现在 Word 中 |
| `aligned` → `align` 转换 | MathType 6.9 不支持 `aligned` 环境，转为 `align` 即可正常识别 |
| `&` 对齐标记前移 | 将 `&= ` 调整为 `& `，消除 `=` 旁的多余空格 |

如果你不需要这些自动处理，提供一个**简洁版** `keep-tex-math-clean.lua`，仅保留基本功能。

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
3. MathType → **Publish** 选项卡 → **Toggle TeX**（或快捷键 Alt+\）
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

### 写作建议：区分行内公式与斜体

MathType 的 Toggle TeX 并不是简单地把所有 `$...$` 内容都转换，它会先尝试按 TeX 语法解析。如果内容中**没有运算符、上下标、命令、括号等数学结构**（如单个字母 `$T$` 或纯单词 `$Mbasef$`），某些版本的 MathType 会认为这不是需要转换的数学表达式，Toggle TeX 时直接跳过。

因此建议在 Obsidian 中区分使用：

| 场景 | 写法 | 在 Word 中的效果 |
|------|------|------------------|
| 变量名、物理量符号 | `*T*`（Markdown 斜体） | 直接显示为斜体，不经过 MathType |
| 参数名、缩写代号 | `*Mbasef*`（Markdown 斜体） | 同上 |
| 真正的数学表达式 | `$a \cdot b$` | MathType Toggle TeX 转换为公式 |

这样变量名和公式各归其位——斜体文本由 Word 直接处理，数学表达式由 MathType 转换，不需要额外的人工检查步骤。

---

## 方案 B（备选）：Word 原生公式

如果你不需要 MathType，希望公式以 Word 原生格式（OMML）呈现：

### Pandoc 命令

```bash
pandoc input.md \
  --reference-doc=custom-reference.docx \
  -o output.docx
```

**关键点：**

- ✅ **Export files from → Markdown**（Obsidian Pandoc Plugin 中此选项选 Markdown）
- ❌ 不要加 `--mathml`（对 docx 无作用）
- ❌ 不要加 `--from markdown-tex_math_dollars`（会破坏公式）
- ✅ 不需任何数学参数，Pandoc 默认将 `$...$` / `$$...$$` 转为 OMML

这样得到的 Word 文档中，公式即为可编辑的 Word 原生公式对象。

---

## 踩坑记录

以下是在排查过程中实际遇到的问题，按"方法 → 结果 → 原因"整理。这些方案可能都有人试过，希望这张表能帮你省去反复尝试的时间。

| 导出方式 | Pandoc 参数 | 结果 | 原因 |
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

### Q: 为什么一定要从 Markdown 导出？

Pandoc 需要读取 Markdown 中的数学 AST（`$...$` / `$$...$$`）。如果用 HTML 格式导出，Obsidian 插件已调用 MathJax 将数学渲染为 HTML/CSS，Pandoc 无法从渲染结果中恢复数学表达式。

### Q: 为什么不用 `--from markdown-tex_math_dollars`？

这个参数告诉 Pandoc "不解析 `$...$` 为数学"，将其视为普通文本。问题在于 Pandoc 的 Markdown Reader 仍会处理反斜杠转义，导致 `\cdot`、`\operatorname` 等 LaTeX 命令中的反斜杠被消费，造成命令丢失。

### Q: 为什么显示公式用 `\[...\]` 而不是 `$$...$$`？

MathType 6.9 对 `\[...\]` 的支持更完整，Toggle TeX 后自动转换为居中公式，不会遗留 `$` 符号。同时 `\[...\]` 也是 LaTeX 的推荐标准写法。

### Q: 方案 A 得到的 docx 里公式是纯文本，还能在 Word 里正常编辑吗？

纯文本状态下的公式源码**不能编辑**——它只是文本。这是为下一步 MathType Toggle TeX 准备的中间状态。转换后公式成为 MathType 公式对象，可在 MathType 中双击编辑。

---

## 文件说明

| 文件 | 说明 |
|------|------|
| `keep-tex-math.lua` | Pandoc Lua Filter（完整版）—— 剥离 `\tag`/`\label`，`aligned`→`align`，`&` 前移 |
| `keep-tex-math-clean.lua` | Pandoc Lua Filter（简洁版）—— 仅剥离 `\tag`/`\label`，其余保持原样 |
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

然后在 Word 中打开生成的 `example.docx`，用 MathType Toggle TeX 一键转换即可。

---

## 许可证

MIT
