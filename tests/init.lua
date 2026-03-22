vim.opt.rtp:append(vim.fn.stdpath("data") .. "/lazy/plenary.nvim")

HOME_DIR = vim.fn.expand("$HOME")
local lua_version = _VERSION:match("%d+%.%d+")
package.path = package.path .. ";" .. HOME_DIR .. "/.luarocks/share/lua/" .. lua_version .. "/?/init.lua;"
package.path = package.path .. ";" .. HOME_DIR .. "/.luarocks/share/lua/" .. lua_version .. "/?.lua;"
package.cpath = package.cpath .. ";" .. HOME_DIR .. "/.luarocks/lib/lua/" .. lua_version .. "/?.so;"
