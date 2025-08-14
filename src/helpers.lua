-- html_to_luanti/src/helpers.lua
-- html_to_luanti helpers
-- Copyright (C) 2025  1F616EMO
-- SPDX-License-Identifier: LGPL-2.1-or-later

html_to_luanti.helpers = {}

-- Parse a simple web page
function html_to_luanti.helpers.parse_website(http, url, callback)
    return http.fetch({
        url = url,
    }, function(result)
        if not result.succeeded then
            core.log("error", "Failed to fetch website: " .. result.code .. " - " .. result.data)
            return callback(nil)
        end

        local html = result.data
        if not html or html == "" then
            return callback("")
        end

        return callback(html_to_luanti.parse(html))
    end)
end

-- Parse a MediaWiki page
local siteconfig_cache = {}
function html_to_luanti.helpers.parse_mediawiki_page(http, api, page, callback)
    local function process(responce_page)
        if not siteconfig_cache[api] then
            return core.after(0.1, process, responce_page)
        end

        if not responce_page.succeeded then
            core.log("error", "Failed to fetch MediaWiki page: " .. responce_page.code .. " - " .. responce_page.data)
            return callback(nil)
        end

        local data, err = core.parse_json(responce_page.data, nil, true)

        if err then
            core.log("error", "Failed to parse JSON in MediaWiki page fetch: " .. err)
            return callback(nil)
        end

        if data.error then
            core.log("error", "Error in MediaWiki page fetch: " .. data.error.code .. ": " .. data.error.info)
            return callback(nil)
        end

        local html = data.parse and data.parse.text

        if not html then
            core.log("error", "No HTML content found in MediaWiki page fetch")
            return callback(nil)
        end

        return callback(html_to_luanti.parse(html, {
            url_base = siteconfig_cache[api].wgserver,
            anchor_base = siteconfig_cache[api].wgserver .. siteconfig_cache[api].wgscript .. "?title=" .. page,
        }), data.parse.revid)
    end

    if not siteconfig_cache[api] then
        http.fetch({
            url = api .. "?action=query&meta=siteinfo&siprop=general&format=json",
        }, function(result)
            if not result.succeeded then
                core.log("error", "Failed to fetch MediaWiki site info: " .. result.code .. " - " .. result.data)
                return callback(nil)
            end

            local data, err = core.parse_json(result.data, nil, true)

            if err then
                core.log("error", "Failed to parse JSON in MediaWiki site info fetch: " .. err)
                return callback(nil)
            end

            if data.error then
                core.log("error", "Error in MediaWiki site info fetch: " .. data.error.code .. ": " .. data.error.info)
                return callback(nil)
            end

            local wgserver = data.query.general.server
            if string.sub(wgserver, 1, 2) == "//" then
                if string.sub(api, 1, 5) == "https" then
                    wgserver = "https:" .. wgserver
                else
                    wgserver = "http:" .. wgserver
                end
            end

            siteconfig_cache[api] = {
                wgserver = wgserver,
                wgscript = data.query.general.script,
            }
        end)
    end

    return http.fetch({
        url = api .. "?" .. table.concat({
            "action=parse",
            "format=json",
            "page=" .. page,
            "prop=text|revid",
            "formatversion=2",
            "disablelimitreport=true",
            "disableeditsection=true",
        }, "&")
    }, process)
end
