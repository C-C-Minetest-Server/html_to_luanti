-- html_to_luanti/src/core.lua
-- Parse HTML into Luanti hypertext
-- Copyright (C) 2025  1F616EMO
-- SPDX-License-Identifier: LGPL-2.1-or-later'

local sub, gsub = string.sub, string.gsub
local utf8 = modlib.utf8

local htmlparser = html_to_luanti.htmlparser

local nbsp = " " -- non-breaking space
local list_marker = table.concat({ nbsp, "•", nbsp })
local tab = nbsp .. nbsp .. nbsp .. nbsp

local H = core and core.hypertext_escape or function(s) return s end

function html_to_luanti.html_unescape(s)
    -- Numeric entities
    s = gsub(s, "&#(%d+);", function(num)
        return utf8.char(tonumber(num))
    end)
    s = gsub(s, "&#x(%x+);", function(num)
        return utf8.char(tonumber(num, 16))
    end)

    -- HTML entities
    s = gsub(s, "&nbsp;", nbsp)
    s = gsub(s, "&lt;", "<")
    s = gsub(s, "&gt;", ">")
    s = gsub(s, "&quot;", '"')
    s = gsub(s, "&amp;", "&")
    return s
end

local function remove_concat_lf(s)
    return gsub(s, "\n+", "\n")
end

function html_to_luanti.parse_childs(node, config)
    local text = ""
    local childs = node.nodes
    local raw_text = node:getcontent()
    local last_touched = 0

    for _, child in ipairs(childs) do
        local offsetted_openstart = child._openstart - node._openend
        local offsetted_closeend = child._closeend - node._openend

        text =
            text ..
            H(html_to_luanti.html_unescape(sub(raw_text, last_touched + 1, offsetted_openstart - 1)))

        if html_to_luanti.block_elements[child.name] and sub(text, -1) ~= "\n" then
            text = text .. "\n"
        end

        if html_to_luanti.element_rules[child.name] then
            local result = html_to_luanti.element_rules[child.name](child, config)
            if result then
                text = text .. result
            end
        else
            text = text .. html_to_luanti.parse_element(child, config)
        end

        if html_to_luanti.block_elements[child.name] then
            text = text .. "\n"
        end

        last_touched = offsetted_closeend
    end

    text = text .. H(html_to_luanti.html_unescape(sub(raw_text, last_touched + 1)))
    text = string.trim(remove_concat_lf(text))

    return text
end

function html_to_luanti.parse_element(node, config)
    if table.indexof(node.classes, "noluanti") ~= -1 or html_to_luanti.invisible_elements[node.name] then
        return ""
    end
    local node_element = node.name

    if html_to_luanti.element_rules[node_element] then
        return html_to_luanti.element_rules[node_element](node, config)
    end

    local node_tag = html_to_luanti.elements_with_luanti_tag[node_element]
    if node_tag == true then
        node_tag = node_element
    end

    local text = ""

    if node_tag then
        text = text .. "<" .. node_tag .. ">"
    end

    text = text .. html_to_luanti.parse_childs(node, config)

    if node_tag then
        text = text .. "</" .. node_tag .. ">"
    end

    return text
end

html_to_luanti.block_elements = {
    address = true,
    article = true,
    aside = true,
    blockquote = true,
    canvas = true,
    dd = true,
    div = true,
    dl = true,
    dt = true,
    figcaption = true,
    figure = true,
    footer = true,
    form = true,
    h1 = true,
    h2 = true,
    h3 = true,
    h4 = true,
    h5 = true,
    h6 = true,
    header = true,
    hr = true,
    li = true,
    main = true,
    nav = true,
    ol = true,
    p = true,
    pre = true,
    section = true,
    table = true,
    tfoot = true,
    ul = true,
    video = true,
}

html_to_luanti.invisible_elements = {
    -- Per specification
    head = true,
    base = true,
    link = true,
    meta = true,
    noscript = true,
    script = true,
    style = true,
    template = true,
    title = true,

    -- Technical limitation
    img = true,
}

html_to_luanti.elements_with_luanti_tag = {
    b = true,
    i = true,
    u = true,
    big = true,
    center = true,

    strong = "b",
    em = "i",
    code = "mono",
    pre = "mono",

    h1 = true,
    h2 = true,
    h3 = true,
    h4 = true,
    h5 = true,
    h6 = true,
}

html_to_luanti.parse_list = function(list, ordered, config)
    local entries = list.nodes

    local fs_hypertext = {}

    for i, entry in ipairs(entries) do
        local text = html_to_luanti.parse_element(entry, config)
        text = gsub(text, "\n", "\n" .. tab)
        text = string.trim(text)
        fs_hypertext[#fs_hypertext + 1] =
            H(ordered and (nbsp .. tostring(i) .. "." .. nbsp) or list_marker) .. text
    end

    return table.concat(fs_hypertext, "\n")
end

html_to_luanti.element_rules = {
    html = function(node, config)
        local body = node("body")[1]
        return body and html_to_luanti.parse_element(body, config) or ""
    end,
    ol = function(node, config)
        return html_to_luanti.parse_list(node, true, config)
    end,
    ul = function(node, config)
        return html_to_luanti.parse_list(node, false, config)
    end,
    a = function(node, config)
        if node.attributes.href then
            local href = node.attributes.href
            if sub(href, 1, 1) == "/" then
                href = (config.url_base or "") .. href
            elseif sub(href, 1, 1) == "#" then
                href = (config.anchor_base or "") .. href
            end

            local name = "link-" .. math.random() .. "-" .. core.sha1(href)

            return "<action name=\"" .. name .. "\" url=\"" ..
                H(html_to_luanti.html_unescape(href)) .. "\">" ..
                html_to_luanti.parse_childs(node, config) .. "</action>"
        else
            return html_to_luanti.parse_childs(node, config)
        end
    end,
    br = function() return "\n" end,
}

html_to_luanti.hypertext_header = table.concat({
    "<tag name=h1 color=#AFF size=26>",
    "<tag name=h2 color=#FAA size=24>",
    "<tag name=h3 color=#AAF size=22>",
    "<tag name=h4 color=#FFA size=20>",
    "<tag name=h5 color=#AFF size=18>",
    "<tag name=h6 color=#FAF size=16>",
    "<tag name=mono color=#6F6 size=14>",
    "<tag name=action color=#7AF hovercolor=#FF005D>",
})

function html_to_luanti.parse(html, config)
    return html_to_luanti.hypertext_header .. html_to_luanti.parse_element(htmlparser.parse(html), config)
end
