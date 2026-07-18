--[[
    client/modules/debug.lua
    ------------------------
    Developer test commands. Loaded only when Bitirim.Config.debug is true.
    These let you preview every UI surface WITHOUT needing a second player.

        /bx_radial     open the radial menu (targets yourself as a dummy)
        /bx_prompt     show a sample incoming passport request prompt
        /bx_passport   show a sample passport document
        /bx_ui         close any open UI / release focus

    Real end-to-end identity discovery still needs two players (or use the
    server command /bx_reveal <serverId> — see server/modules/debug.lua).
]]

if not Bitirim.Config.debug then return end

local Utils = Bitirim.Utils

RegisterCommand('bx_radial', function()
    -- Target self as a harmless dummy so the menu opens for visual testing.
    Bitirim.Radial.open(GetPlayerServerId(PlayerId()))
end, false)

RegisterCommand('bx_prompt', function()
    SendNUIMessage({
        action = 'passportPrompt',
        requestId = 0,                 -- fake id; server ignores accept/decline
        senderName = 'Test Yasin',
        senderServerId = 99,
        timeout = Bitirim.Config.passport.requestTimeout,
    })
end, false)

RegisterCommand('bx_passport', function()
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'passportShow',
        passport = {
            title = Bitirim.Passport.title,
            subtitle = Bitirim.Passport.subtitle,
            showPhoto = true,
            fields = {
                { label = 'Name',        value = 'Test Yasin' },
                { label = 'Citizen ID',  value = 'TEST0001' },
                { label = 'Birth Date',  value = '1995-04-12' },
                { label = 'Gender',      value = 'Male' },
                { label = 'Nationality', value = 'Turkish' },
            },
            signature = 'Test Yasin',
        },
    })
end, false)

RegisterCommand('bx_ui', function()
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'radialClose' })
    SendNUIMessage({ action = 'passportHide' })
    SendNUIMessage({ action = 'passportPromptClose' })
end, false)

Utils.warn('debug', 'DEBUG commands active: /bx_radial /bx_prompt /bx_passport /bx_ui')
