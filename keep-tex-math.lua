-- keep-tex-math.lua
-- Preserve LaTeX math as plain text in Pandoc docx output,
-- so that MathType Toggle TeX can convert them later.
--
-- Usage:
--   pandoc input.md --lua-filter=keep-tex-math.lua --reference-doc=... -o output.docx
--
-- Behaviour:
--   DisplayMath → \[...\]  (MathType 6.9+ handles this cleanly)
--   InlineMath  → $...$
--   Strips \tag{...} and \label{...}
--   Converts aligned → align (MathType 6.9 supports align, not aligned)
--   Moves & alignment marker from before = to start of line

function Math(el)
    local tex = el.text

    -- Strip equation numbers and labels
    tex = tex:gsub("\\tag%s*%b{}", "")
    tex = tex:gsub("\\label%s*%b{}", "")

    -- Convert aligned → align (MathType 6.9 handles align, not aligned)
    tex = tex:gsub("\\begin{aligned}", "\\begin{align}")
    tex = tex:gsub("\\end{aligned}", "\\end{align}")

    -- Move & from before = to start of line (avoids extra spaces)
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
