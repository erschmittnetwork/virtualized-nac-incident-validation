-- filters/appendix-numbering.lua

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
  text = trim(text)

  -- Top-level appendix titles:
  -- "Appendix A. Title"
  -- "Appendix A Title"
  text = text:gsub("^Appendix%s+" .. letter .. "%.??%s*", "")

  -- Numbered appendix subsection titles:
  -- "A.1 Title"
  -- "A.1.2 Title"
  -- "A.1.2.3 Title"
  -- optional trailing period before the space is tolerated
  text = text:gsub("^" .. letter .. "%.%d+%.%d+%.%d+%.?%s+", "")
  text = text:gsub("^" .. letter .. "%.%d+%.%d+%.?%s+", "")
  text = text:gsub("^" .. letter .. "%.%d+%.?%s+", "")

  return trim(text)
end

local function make_header_content(number, title_text, is_appendix_top)
  if is_appendix_top then
    return {
      pandoc.Span(
        { pandoc.Str("Appendix"), pandoc.Space(), pandoc.Str(number .. ".") },
        pandoc.Attr("", { "header-section-number" })
      ),
      pandoc.Space(),
      pandoc.Str(title_text)
    }
  else
    return {
      pandoc.Span(
        { pandoc.Str(number) },
        pandoc.Attr("", { "header-section-number" })
      ),
      pandoc.Space(),
      pandoc.Str(title_text)
    }
  end
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
        counters[letter] = { subsection = 0, subsubsection = 0, level4 = 0 }
        appendix_map[id] = letter

        local title = strip_manual_prefix(stringify(block.content), letter)
        block.content = make_header_content(letter, title, true)

      elseif current_appendix and block.level == 2 and id ~= "" and appendix_letter_from_id(id) == current_appendix then
        local c = counters[current_appendix]
        c.subsection = c.subsection + 1
        c.subsubsection = 0
        c.level4 = 0

        local num = string.format("%s.%d", current_appendix, c.subsection)
        appendix_map[id] = num

        local title = strip_manual_prefix(stringify(block.content), current_appendix)
        block.content = make_header_content(num, title, false)

      elseif current_appendix and block.level == 3 and id ~= "" and appendix_letter_from_id(id) == current_appendix then
        local c = counters[current_appendix]
        c.subsubsection = c.subsubsection + 1
        c.level4 = 0

        local num = string.format("%s.%d.%d", current_appendix, c.subsection, c.subsubsection)
        appendix_map[id] = num

        local title = strip_manual_prefix(stringify(block.content), current_appendix)
        block.content = make_header_content(num, title, false)

      elseif current_appendix and block.level == 4 and id ~= "" and appendix_letter_from_id(id) == current_appendix then
        local c = counters[current_appendix]
        c.level4 = c.level4 + 1

        local num = string.format(
          "%s.%d.%d.%d",
          current_appendix, c.subsection, c.subsubsection, c.level4
        )
        appendix_map[id] = num

        local title = strip_manual_prefix(stringify(block.content), current_appendix)
        block.content = make_header_content(num, title, false)
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

  if text:match("^%d+$")
    or text:match("^%d+%.%d+$")
    or text:match("^%d+%.%d+%.%d+$")
    or text:match("^%d+%.%d+%.%d+%.%d+$")
  then
    link.content = { pandoc.Str(appendix_num) }
    return link
  end

  if text:match("^Section%s+%d+[%d%.]*$") then
    link.content = {
      pandoc.Str("Section"),
      pandoc.Space(),
      pandoc.Str(appendix_num)
    }
    return link
  end

  if text:match("^Appendix%s+%d+[%d%.]*$") then
    local visible = appendix_num:match("^[A-Z]$") and ("Appendix " .. appendix_num) or appendix_num
    link.content = { pandoc.Str(visible) }
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
