-- filters/appendix-numbering.lua
--
-- Rewrites appendix header numbering and internal reference text for HTML.
-- Designed for LaTeX input parsed by Pandoc, with labels like:
--   sec:appendix-a-...
--   sec:appendix-b-...

local appendix_map = {}

local function stringify(x)
  return pandoc.utils.stringify(x)
end

local function trim(s)
  return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function appendix_letter_from_id(id)
  if not id then
    return nil
  end
  local a = id:match("^sec:appendix%-([a-z])%-")
  if a then
    return string.upper(a)
  end
  return nil
end

local function strip_manual_prefix(text, letter)
  -- Removes visible manual numbering already embedded in titles.
  -- Examples:
  --   "Appendix A. Raw Configurations..."
  --   "A.1 Host Network Configurations"
  --   "A.1.1 radius-splunk Netplan Configuration"
  text = text:gsub("^Appendix%s+" .. letter .. "%.%s*", "")
  text = text:gsub("^" .. letter .. "%.%d+%.%d+%.%d+%.%s*", "")
  text = text:gsub("^" .. letter .. "%.%d+%.%d+%.%s*", "")
  text = text:gsub("^" .. letter .. "%.%d+%.%s*", "")
  text = text:gsub("^" .. letter .. "%.%d+%s*", "")
  return trim(text)
end

local function make_header_content(number, title_text)
  return {
    pandoc.Span(
      { pandoc.Str(number) },
      pandoc.Attr("", { "header-section-number" })
    ),
    pandoc.Space(),
    pandoc.Str(title_text)
  }
end

local function collect_and_rewrite_headers(doc)
  local current_appendix = nil
  local counters = {}

  for _, block in ipairs(doc.blocks) do
    if block.t == "Header" then
      local id = block.identifier
      local letter = appendix_letter_from_id(id)

      if block.level == 1 and letter then
        current_appendix = letter
        counters[letter] = { section = 1, subsection = 0, subsubsection = 0, level4 = 0 }
        appendix_map[id] = letter

        local title = strip_manual_prefix(stringify(block.content), letter)
        block.content = make_header_content(letter, title)

      elseif current_appendix and block.level == 2 then
        local c = counters[current_appendix]
        c.subsection = c.subsection + 1
        c.subsubsection = 0
        c.level4 = 0

        local num = string.format("%s.%d", current_appendix, c.subsection)
        appendix_map[id] = num

        local title = strip_manual_prefix(stringify(block.content), current_appendix)
        block.content = make_header_content(num, title)

      elseif current_appendix and block.level == 3 then
        local c = counters[current_appendix]
        c.subsubsection = c.subsubsection + 1
        c.level4 = 0

        local num = string.format("%s.%d.%d", current_appendix, c.subsection, c.subsubsection)
        appendix_map[id] = num

        local title = strip_manual_prefix(stringify(block.content), current_appendix)
        block.content = make_header_content(num, title)

      elseif current_appendix and block.level == 4 then
        local c = counters[current_appendix]
        c.level4 = c.level4 + 1

        local num = string.format(
          "%s.%d.%d.%d",
          current_appendix, c.subsection, c.subsubsection, c.level4
        )
        appendix_map[id] = num

        local title = strip_manual_prefix(stringify(block.content), current_appendix)
        block.content = make_header_content(num, title)
      end
    end
  end

  return doc
end

local function rewrite_link_text(link)
  local target = link.target or ""
  local id = target:match("^#(.+)$")
  if not id then
    return link
  end

  local appendix_num = appendix_map[id]
  if not appendix_num then
    return link
  end

  local text = stringify(link.content)

  -- Rewrite bare numeric refs:
  --   13
  --   13.1
  --   13.1.2
  --   13.1.2.3
  if text:match("^%d+$")
    or text:match("^%d+%.%d+$")
    or text:match("^%d+%.%d+%.%d+$")
    or text:match("^%d+%.%d+%.%d+%.%d+$")
  then
    link.content = { pandoc.Str(appendix_num) }
    return link
  end

  -- Rewrite forms like:
  --   Section 13.1.2
  --   Section 13.1
  local secnum = text:match("^Section%s+(%d+[%d%.]*)$")
  if secnum then
    link.content = {
      pandoc.Str("Section"),
      pandoc.Space(),
      pandoc.Str(appendix_num)
    }
    return link
  end

  -- Rewrite forms like:
  --   Appendix 13
  local appnum = text:match("^Appendix%s+(%d+[%d%.]*)$")
  if appnum then
    link.content = {
      pandoc.Str("Appendix"),
      pandoc.Space(),
      pandoc.Str(appendix_num)
    }
    return link
  end

  return link
end

function Pandoc(doc)
  doc = collect_and_rewrite_headers(doc)
  doc = doc:walk({
    Link = rewrite_link_text
  })
  return doc
end
