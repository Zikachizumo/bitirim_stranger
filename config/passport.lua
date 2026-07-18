--[[
    config/passport.lua
    -------------------
    Passport & license presentation config.

    `fields` defines what the passport UI renders and, importantly, WHERE the
    value comes from in the Qbox charinfo/metadata. The server builds the
    payload (server/modules/players.lua) strictly from these mappings so the
    UI and the data contract stay in sync.

    source formats understood by players.lua:
        'charinfo.<key>'   -> PlayerData.charinfo[key]
        'meta.<key>'       -> PlayerData.metadata[key]
        'citizenid'        -> PlayerData.citizenid
        'static:<value>'   -> constant value from this config
]]

Bitirim = Bitirim or {}

Bitirim.Passport = {
    -- Document header.
    title = 'REPUBLIC PASSPORT',
    subtitle = 'Bitirim State',

    -- Whether to show a character photo slot (image support is future work).
    showPhoto = true,
    photoPlaceholder = 'assets/passport_photo.svg',

    -- Ordered list of fields rendered on the passport. Reorder / add freely.
    fields = {
        { key = 'name',        label = 'Name',        source = 'charinfo.__fullname' },
        -- Player (server) ID instead of the citizenid.
        { key = 'playerid',    label = 'Player ID',   source = 'playerid' },
        -- PLAYER AGE placeholder. Hook this to your level system when it lands
        -- by pointing `source` at the right metadata key (e.g. 'meta.level').
        { key = 'playerage',   label = 'PLAYER AGE',  source = 'meta.level' },
        { key = 'gender',      label = 'Gender',      source = 'charinfo.gender', transform = 'gender' },
        { key = 'nationality', label = 'Nationality', source = 'charinfo.nationality' },
    },

    -- Signature line. When 'charinfo.__fullname' the signature renders the name
    -- in a script font; set a static string to override.
    signature = {
        enabled = true,
        source = 'charinfo.__fullname',
    },

    -- Human-readable transforms applied server-side before sending to NUI.
    transforms = {
        gender = { [0] = 'Male', [1] = 'Female', ['m'] = 'Male', ['f'] = 'Female', default = 'Unknown' },
    },

    ---------------------------------------------------------------------------
    -- LICENSES (architecture placeholder — data-driven for future rollout)
    ---------------------------------------------------------------------------
    licenses = {
        driver   = { label = 'Driver License',   metaKey = 'licences.driver' },
        weapon   = { label = 'Weapon License',   metaKey = 'licences.weapon' },
        fishing  = { label = 'Fishing License',  metaKey = 'licences.fishing' },
        pilot    = { label = 'Pilot License',    metaKey = 'licences.pilot' },
        boat     = { label = 'Boat License',     metaKey = 'licences.boat' },
        medical  = { label = 'Medical License',  metaKey = 'licences.medical' },
        business = { label = 'Business License', metaKey = 'licences.business' },
    },
}
