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
        icon      (string)  svg filename in web/assets/ (without path)
        color     (string?) optional accent override
        action    (string?) event name dispatched to client/modules on select
        submenu   (table?)  nested entries (opens a new radial ring)
        enabled   (bool?)   default true; false = greyed out / future feature

    `action` values are handled in client/modules/radial.lua -> Dispatch().
    Keeping actions as strings (not functions) keeps this file pure data and
    safe to hot-reload / share.
]]

Bitirim = Bitirim or {}

Bitirim.Menu = {
    -- Center hub label shown in the middle of the radial.
    centerLabel = 'Player Interaction',

    -- Top-level ring.
    entries = {
        {
            id = 'documents',
            label = 'Documents',
            icon = 'documents.svg',
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
                    action = 'openLicenseMenu', -- placeholder submenu (see below)
                    enabled = true,
                    submenu = {
                        -- Architecture supports these; wired as placeholders now.
                        { id = 'license_driver',   label = 'Driver License',   icon = 'license.svg', action = 'showLicense', enabled = false },
                        { id = 'license_weapon',   label = 'Weapon License',   icon = 'license.svg', action = 'showLicense', enabled = false },
                        { id = 'license_fishing',  label = 'Fishing License',  icon = 'license.svg', action = 'showLicense', enabled = false },
                        { id = 'license_pilot',    label = 'Pilot License',    icon = 'license.svg', action = 'showLicense', enabled = false },
                        { id = 'license_boat',     label = 'Boat License',     icon = 'license.svg', action = 'showLicense', enabled = false },
                        { id = 'license_medical',  label = 'Medical License',  icon = 'license.svg', action = 'showLicense', enabled = false },
                        { id = 'license_business', label = 'Business License', icon = 'license.svg', action = 'showLicense', enabled = false },
                    },
                },
            },
        },

        -----------------------------------------------------------------------
        -- FUTURE CATEGORIES
        -- Present in the config so the ring layout & spacing are designed for
        -- the full vision. Disabled entries render dimmed and non-interactive.
        -----------------------------------------------------------------------
        { id = 'inventory',  label = 'Inventory',  icon = 'inventory.svg',  action = 'openInventory',  enabled = false },
        { id = 'business',   label = 'Business',   icon = 'business.svg',   action = 'openBusiness',   enabled = false },
        { id = 'police',     label = 'Police',     icon = 'police.svg',     action = 'openPolice',     enabled = false },
        { id = 'medical',    label = 'Medical',    icon = 'medical.svg',    action = 'openMedical',    enabled = false },
        { id = 'gang',       label = 'Gang',       icon = 'gang.svg',       action = 'openGang',       enabled = false },
        { id = 'vehicle',    label = 'Vehicle',    icon = 'vehicle.svg',    action = 'openVehicle',    enabled = false },
        { id = 'animations', label = 'Animations', icon = 'animations.svg', action = 'openAnimations', enabled = false },
        { id = 'phone',      label = 'Phone',      icon = 'phone.svg',      action = 'openPhone',      enabled = false },
    },
}
