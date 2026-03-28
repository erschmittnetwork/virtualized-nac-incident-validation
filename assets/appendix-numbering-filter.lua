-- filters/appendix-numbering.lua
--
-- Purpose:
--   Rewrite appendix header numbering and internal section references
--   for HTML output when the source is LaTeX parsed by Pandoc.
--
-- Assumptions:
--   - Appendix labels use the pattern:
--       sec:appendix-a-...
--       sec:appendix-b-...
--   - Appendix A and B are top-level \section blocks.
--   - Subsection and subsubsection titles may already contain manual
--     prefixes like "A.1 ..." or "A.1.2 ..."; those prefixes are
--     stripped from the visible heading text so the generated number
--     is not duplicated.
--
-- Result:
--   - Appendix section headings display as:
--       A Appendix A. Raw Configurations and Automation Artifacts
--   - Appendix subsection headings display as:
--       A.1 Host Network Configurations
--       A.1.1 radius-splunk Netplan Configuration
--   - Internal links pointing to those appendix labels display the same
--     appendix-style numbering in HTML.

local appendix_mode = nil
local appendix_letter = nil

local appendix_counters = {
  A = { section = 0, subsection = 0, subsubsection = 0 },
  B = { section = 0, subsection = 0, subsubsection = 0 },
}

local ref_map = {}

local function starts_with(str, prefix)
  return str ~= nil and str:sub(1, #prefix) == prefix
end

local function clone_inlines(inlines)
  local out = {}
  for i = 1, #inlines do
    out[i] = inlines[i]
  end
  return out
end

local function stringify(inlines)
  return pandoc.utils.stringify(inlines or {})
end

local function trim(s)
  return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function strip_manual_appendix_prefix(text, letter)
  -- Removes prefixes like:
  --   "A.1 "
  --   "A.1.2 "
  --   "Appendix A. "
  --   "Appendix B. "
  --
  -- This is intentionally conservative.
  text = text:gsub("^Appendix%s+" .. letter .. "%.%s*", "")
  text = text:gsub("^" .. letter .. "%.%d+%.%d+%.%s*", "")
  text = text:gsub("^" .. letter .. "%.%d+%.%s*", "")
  text = text:gsub("^" .. letter .. "%.%d+%s*", "")
  return trim(text)
end

local function make_numbered_span(num)
  return pandoc.Span(
    { pandoc.Str(num) },
    pandoc.Attr("", { "header-section-number" }, {})
  )
end

local function replace_heading_text(el, new_text)
  el.content = { pandoc.Str(new_text) }
  return el
end

local function format_ref(letter, level, counters)
  if level == 1 then
    return letter
  elseif level == 2 then
    return string.format("%s.%d", letter, counters.subsection)
  elseif level == 3 then
    return string.format("%s.%d.%d", letter, counters.subsection, counters.subsubsection)
  else
    return letter
  end
end

local function header_belongs_to_appendix(identifier)
  if starts_with(identifier, "sec:appendix-a-") then
    return "A"
  elseif starts_with(identifier, "sec:appendix-b-") then
    return "B"
  else
    return nil
  end
end

function Header(el)
  local id = el.identifier or ""
  local letter = header_belongs_to_appendix(id)

  if el.level == 1 and letter ~= nil then
    appendix_mode = true
    appendix_letter = letter
    appendix_counters[letter].section = appendix_counters[letter].section + 1
    appendix_counters[letter].subsection = 0
    appendix_counters[letter].subsubsection = 0

    local plain = stringify(el.content)
    local cleaned = strip_manual_appendix_prefix(plain, letter)

    ref_map[id] = letter

    el.content = {
      make_numbered_span(letter),
      pandoc.Space(),
      pandoc.Str(cleaned)
    }
    return el
  end

  if appendix_mode and appendix_letter ~= nil and el.level == 2 then
    local counters = appendix_counters[appendix_letter]
    counters.subsection = counters.subsection + 1
    counters.subsubsection = 0

    local plain = stringify(el.content)
    local cleaned = strip_manual_appendix_prefix(plain, appendix_letter)
    local num = string.format("%s.%d", appendix_letter, counters.subsection)

    if id ~= "" then
      ref_map[id] = num
    end

    el.content = {
      make_numbered_span(num),
      pandoc.Space(),
      pandoc.Str(cleaned)
    }
    return el
  end

  if appendix_mode and appendix_letter ~= nil and el.level == 3 then
    local counters = appendix_counters[appendix_letter]
    counters.subsubsection = counters.subsubsection + 1

    local plain = stringify(el.content)
    local cleaned = strip_manual_appendix_prefix(plain, appendix_letter)
    local num = string.format("%s.%d.%d", appendix_letter, counters.subsection, counters.subsubsection)

    if id ~= "" then
      ref_map[id] = num
    end

    el.content = {
      make_numbered_span(num),
      pandoc.Space(),
      pandoc.Str(cleaned)
    }
    return el
  end

  return el
end

function Link(el)
  local target = el.target or ""
  local id = target:match("^#(.+)$")

  if not id then
    return el
  end

  local replacement = ref_map[id]
  if not replacement then
    return el
  end

  local label_text = stringify(el.content)

  -- Replace links that are effectively cross-references.
  -- This catches common Pandoc-rendered cases like:
  --   "13.4.3"
  --   "14.1.2"
  --   "Section 13.4.3"
  --   "Section~13.4.3"
  --
  -- It avoids rewriting arbitrary prose links.
  if label_text:match("^%d+%.%d+%.%d+$")
    or label_text:match("^%d+%.%d+$")
    or label_text:match("^%d+$")
  then
    el.content = { pandoc.Str(replacement) }
    return el
  end

  local section_prefix = label_text:match("^(Section%s+).+$")
  if section_prefix then
    el.content = {
      pandoc.Str(section_prefix:match("^Section")),
      pandoc.Space(),
      pandoc.Str(replacement)
    }
    return el
  end

  return el
end
