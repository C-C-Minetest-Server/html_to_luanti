-- html_to_luanti/init.lua
-- Parse HTML into Luanti hypertext
-- Copyright (C) 2025  1F616EMO
-- SPDX-License-Identifier: LGPL-2.1-or-later

local MP = core.get_modpath("html_to_luanti")

-- Load htmlparser
local htmlparser
do
    local old_require = require
    function _G.require(name)
        if name.sub(name, 1, 11) == "htmlparser." then
            return dofile(MP .. "/htmlparser/src/htmlparser/" .. name.sub(name, 12) .. ".lua")
        else
            return old_require(name)
        end
    end

    htmlparser_opts = { -- luacheck: ignore
        silent = true,  -- Or it will attempt to get stderr which violates mod secutiry
    }
    htmlparser = dofile(MP .. "/htmlparser/src/htmlparser.lua")

    htmlparser_opts = nil -- luacheck: ignore
    _G.require = old_require
end

html_to_luanti = {
    htmlparser = htmlparser,
}

dofile(MP .. "/src/core.lua")
dofile(MP .. "/src/helpers.lua")
