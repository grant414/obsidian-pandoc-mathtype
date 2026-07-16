-- keep-tex-math-clean.lua
-- Preserve LaTeX math as plain text, strip equation numbers (\tag, \label)
--
-- Usage:
--   pandoc input.md --lua-filter=keep-tex-math-clean.lua --reference-doc=... -o output.docx
--
-- Behaviour:
--   DisplayMath → \[...\]  (MathType 6.9+ handles this cleanly)
--   InlineMath  → $...$
--   Strips \tag{...} and \label{...} from math content

function Math(el)
    local tex = el.text

    -- Strip equation numbers and labels
    tex = tex:gsub("\\tag%s*%b{}", "")
    tex = tex:gsub("\\label%s*%b{}", "")

    if el.mathtype == "DisplayMath" then
        return pandoc.Code("\\[" .. tex .. "\\]")
    else
        return pandoc.Code("$" .. tex .. "$")
    end
end
