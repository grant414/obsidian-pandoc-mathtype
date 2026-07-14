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

function Math(el)
    if el.mathtype == "DisplayMath" then
        return pandoc.Code("\\[" .. el.text .. "\\]")
    else
        return pandoc.Code("$" .. el.text .. "$")
    end
end
