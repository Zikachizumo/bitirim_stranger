--[[
    config/config.lua
    -----------------
    Core, gameplay-level configuration.
    Everything here is data — no logic lives in config files.

    A single global namespace `Bitirim` is shared across all files.
    Each config file attaches its own sub-table.
]]

Bitirim = Bitirim or {}

Bitirim.Config = {
    -- Master debug switch. When true, prints diagnostic logs (see shared/utils.lua).
    debug = false,

    -- Resource-wide locale key used for notifications (ox_lib locale support ready).
    locale = 'en',

    ---------------------------------------------------------------------------
    -- INTERACTION
    ---------------------------------------------------------------------------
    interaction = {
        -- Key that opens the radial menu. See:
        -- https://docs.fivem.net/docs/game-references/controls/
        key = 'G',                 -- human-readable, mapped via RegisterKeyMapping
        keyMapDescription = 'Bitirim — Interact with nearby player',

        -- Distance (metres) within which the indicator/label becomes visible.
        indicatorDistance = 8.0,

        -- Distance (metres) within which a player can be *targeted* for interaction.
        targetDistance = 3.0,

        -- Require line-of-sight before allowing interaction (prevents through-wall).
        requireLineOfSight = true,

        -- Only allow interaction when both players are on foot (not in a vehicle).
        onFootOnly = true,

        -- Failsafe: force-close the radial menu if it somehow stays open this
        -- long (e.g. the player alt-tabbed and the NUI stopped receiving keys).
        -- Set to 0 to disable the timeout.
        radialTimeout = 30,        -- seconds
    },

    ---------------------------------------------------------------------------
    -- PROXIMITY / PERFORMANCE
    -- The proximity scanner uses an adaptive tick: fast when someone is near,
    -- idle-slow when nobody is around. This keeps CPU usage minimal.
    ---------------------------------------------------------------------------
    performance = {
        -- Hard cap on how many nearby players we track & render simultaneously.
        maxTrackedPlayers = 12,

        -- Adaptive scan intervals (ms).
        scanIntervalNear = 0,      -- someone within indicatorDistance -> every frame
        scanIntervalMid  = 200,    -- players around but out of range
        scanIntervalIdle = 1000,   -- nobody nearby -> relax

        -- Screen-projection update interval (ms). 0 = every frame (so the
        -- label tracks the character smoothly). This is position tracking,
        -- not a visual animation.
        renderInterval = 0,

        -- The name/ID label sits slightly ABOVE the head and follows the ped.
        labelBone = 31086,          -- SKEL_Head
        labelHeightOffset = 0.35,   -- metres above the head bone

        -- The circular G button stays at chest / waist height.
        keyBone = 24818,            -- SKEL_Spine3 (upper chest / waist area)
        keyHeightOffset = 0.0,      -- fine-tune vertical offset in metres
    },

    ---------------------------------------------------------------------------
    -- PASSPORT REQUEST FLOW
    ---------------------------------------------------------------------------
    passport = {
        -- Seconds the receiver has to accept/decline before auto-cancel.
        requestTimeout = 10,

        -- Accept / Decline key prompts (informational; handled via NUI + keys).
        acceptKey = 'Y',
        declineKey = 'N',

        -- Cooldown (ms) before the same sender can request the same target again
        -- after a decline/timeout. Prevents harassment spam.
        resendCooldown = 5000,
    },

    ---------------------------------------------------------------------------
    -- IDENTITY / KNOWN-PEOPLE
    ---------------------------------------------------------------------------
    identity = {
        -- Default label shown for an unknown character.
        strangerLabel = 'Stranger',

        -- When true, identity relationships persist in the database forever.
        -- When false, they live only for the current session (testing).
        persist = true,

        -- Command that lets a player forget someone (future / optional).
        -- Set to false to disable the command entirely.
        forgetCommand = 'forget',      -- /forget  (opens a menu of known people)
        allowForget = true,
    },
}
