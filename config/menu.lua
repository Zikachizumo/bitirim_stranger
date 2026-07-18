--[[
    config/menu.lua
    ---------------
    Radial menu structure — fully modular.

    Each entry is a self-contained module descriptor. Adding a new category or
    action is as simple as adding a table here; the NUI renders whatever it is
    given and the client dispatches by `action`.

    Entry schema:
        id        (string)  unique key
        label     (string)  display text
        icon      (string)  svg key resolved by the inline icon set in
                            web/js/radial.js (add new keys there)
        color     (string?) optional accent override
        action    (string?) event name dispatched to client/modules on select
        submenu   (table?)  nested entries (opens a new radial ring)
        enabled   (bool?)   default true; false = greyed out / future feature

    Ordering: entries are laid out starting at the LEFT of the ring and running
    counter-clockwise (left -> down -> bottom -> right -> up), so entry #1 sits
    at the 9 o'clock position. See render() in web/js/radial.js.

    `action` values are handled in client/modules/radial.lua -> dispatch().
    Keeping actions as strings (not functions) keeps this file pure data and
    safe to hot-reload / share.
]]

Bitirim = Bitirim or {}

Bitirim.Menu = {
    -- Center hub label shown in the middle of the radial.
    centerLabel = 'Player Interaction',

    -- Top-level ring, in display order (1 = left, then counter-clockwise).
    entries = {
        -- 1 --------------------------------------------------------------
        {
            id = 'properties',
            label = 'Properties',
            icon = 'business.svg',
            enabled = true,
            submenu = {
                -- Owned-vehicle actions (sell, hand over keys) land here.
                { id = 'prop_vehicles', label = 'Vehicles', icon = 'vehicle.svg',  action = 'openPropertyVehicles', enabled = false },
                { id = 'prop_business', label = 'Business', icon = 'business.svg', action = 'openPropertyBusiness', enabled = false },
                { id = 'prop_houses',   label = 'Houses',   icon = 'house.svg',    action = 'openPropertyHouses',   enabled = false },
            },
        },

        -- 2 --------------------------------------------------------------
        {
            id = 'documents',
            label = 'Documents',
            icon = 'documents.svg',
            enabled = true,
            submenu = {
                {
                    id = 'passport',
                    label = 'Passport',
                    icon = 'passport.svg',
                    action = 'showPassport',   -- -> passport request flow
                    enabled = true,
                },
                {
                    id = 'license',
                    label = 'License',
                    icon = 'license.svg',
                    action = 'openLicenseMenu',
                    enabled = true,
                    submenu = {
                        -- Architecture supports these; wired as placeholders now.
                        { id = 'license_driver',   label = 'Driver License',   icon = 'license.svg', action = 'showLicense', enabled = false },
                        { id = 'license_pilot',    label = 'Pilot License',    icon = 'license.svg', action = 'showLicense', enabled = false },
                        { id = 'license_boat',     label = 'Boat License',     icon = 'license.svg', action = 'showLicense', enabled = false },
                        { id = 'license_weapon',   label = 'Weapon License',   icon = 'license.svg', action = 'showLicense', enabled = false },
                        { id = 'health_insurance', label = 'Health Insurance', icon = 'medical.svg', action = 'showLicense', enabled = false },
                    },
                },
            },
        },

        -- 3 --------------------------------------------------------------
        { id = 'interactive',         label = 'Interactive',         icon = 'interactive.svg', action = 'openInteractive',        enabled = false },
        -- 4 --------------------------------------------------------------
        { id = 'illegal_interactive', label = 'Illegal Interactive', icon = 'illegal.svg',     action = 'openIllegalInteractive', enabled = false },
        -- 5 --------------------------------------------------------------
        { id = 'gang',                label = 'Gang',                icon = 'gang.svg',        action = 'openGang',               enabled = false },
        -- 6 --------------------------------------------------------------
        { id = 'police',              label = 'Police',              icon = 'police.svg',      action = 'openPolice',             enabled = false },
        -- 7 --------------------------------------------------------------
        { id = 'medical',             label = 'Medical',             icon = 'medical.svg',     action = 'openMedical',            enabled = false },
    },
}
