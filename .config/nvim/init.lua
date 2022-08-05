-- neovim lua config
require('impatient') -- cuts about 50% startuptime from well behaved stuff
require("user/core")
require("user/core_maps")
require("user/plugins")
require("user/plugins_conf")
require("user/plugins_maps") -- 45ms: plugins_conf, plugin_maps
require("user/lsp") -- 11ms
require("user/treesitter") -- ~0ms
require("user/completion") -- 850ms, totally broken
require("user/telescope") -- 30ms
require("user/style") -- 10ms

