fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'bitirim_stranger'
author 'Bitirim Framework'
description 'Premium player interaction, identity discovery & passport system for Qbox'
version '0.1.0'

--[[
    Bitirim Stranger
    ----------------
    A standalone, modular player-interaction resource for the Qbox framework.

    Dependencies (never modified by this resource):
        - qbx_core
        - ox_lib
        - oxmysql

    Architecture:
        config/  -> shared, config-driven definitions (loaded first)
        shared/  -> utilities available to both client & server
        server/  -> identity persistence, passport request lifecycle
        client/  -> proximity, indicator rendering, interaction, radial, passport
        web/     -> NUI (glassmorphism UI)
]]

dependencies {
    'qbx_core',
    'ox_lib',
    'oxmysql',
}

-- ox_lib must be initialised before any of our code runs.
shared_scripts {
    '@ox_lib/init.lua',
    'config/config.lua',
    'config/theme.lua',
    'config/menu.lua',
    'config/passport.lua',
    'shared/utils.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/modules/players.lua',
    'server/modules/playerid.lua',
    'server/modules/identity.lua',
    'server/modules/passport.lua',
    'server/modules/debug.lua',   -- loaded but self-disables unless Config.debug
    'server/main.lua',
}

client_scripts {
    'client/modules/identity.lua',
    'client/modules/proximity.lua',
    'client/modules/indicator.lua',
    'client/modules/interaction.lua',
    'client/modules/radial.lua',
    'client/modules/passport.lua',
    'client/modules/debug.lua',   -- loaded but self-disables unless Config.debug
    'client/main.lua',
}

ui_page 'web/index.html'

files {
    'web/index.html',
    'web/css/*.css',
    'web/js/*.js',
    -- NOTE: UI icons are inlined in web/js/radial.js and web/js/passport.js,
    -- so no external asset/font files are shipped. If you later add real
    -- images/fonts, drop them in web/assets or web/fonts and re-add a glob here.
}
