--[[
    config/theme.lua
    ----------------
    Visual identity of the Bitirim interaction system.
    These values are forwarded to the NUI on resource start so the entire
    look & feel can be re-skinned without touching any CSS or JS.

    Colours are plain hex strings; opacity/blur are numbers the CSS consumes
    via CSS custom properties (see web/js/bridge.js -> applyTheme()).
]]

Bitirim = Bitirim or {}

Bitirim.Theme = {
    -- Brand identity. Bitirim's own palette (NOT a NoPixel/GTAO copy — inspired only).
    colors = {
        accent        = '#4FC3F7',   -- primary brand glow (cyan-blue)
        accentSoft    = '#81D4FA',
        background     = '#0E1116',   -- glass base tint
        surface        = '#161B22',
        text          = '#F5F7FA',
        textMuted      = '#9AA4B2',
        stranger       = '#B0BEC5',   -- neutral grey for unknown players
        known          = '#4FC3F7',   -- accent for recognised players
        success        = '#4CAF7D',
        danger         = '#E5534B',
        warning        = '#E3A008',
    },

    -- Glassmorphism tuning.
    glass = {
        blur          = 14,          -- px backdrop blur (menu background)
        indicatorBlur = 8,           -- px blur for the floating indicator card
        opacity       = 0.55,        -- glass fill opacity (0-1)
        borderOpacity = 0.18,        -- subtle border highlight
        shadow        = '0 10px 30px rgba(0,0,0,0.45)',
    },

    -- Glow settings for the interaction button & indicator.
    glow = {
        color         = '#4FC3F7',
        strength      = 18,          -- px glow spread
        pulseStrength  = 26,         -- px glow at peak of breathing animation
    },

    -- Typography. Fonts are optional; falls back to system UI if not provided.
    typography = {
        primaryFont   = 'Inter',
        fallback      = "'Segoe UI', system-ui, sans-serif",
        labelSize     = 15,          -- px name label
        idSize        = 12,          -- px server id sub-label
        weight        = 600,
    },

    -- Animation timing (ms). Consumed by CSS transition durations.
    animation = {
        fadeIn        = 220,
        fadeOut       = 180,
        menuOpen      = 260,
        menuClose     = 200,
        buttonPress   = 120,
        breathing     = 2600,        -- full breathing cycle for the G button
        scaleSpring    = 320,        -- indicator scale easing
    },

    -- Indicator scaling relative to distance (billboard sizing).
    scale = {
        min           = 0.55,        -- scale when at max indicatorDistance
        max           = 1.0,         -- scale when very close
        base          = 1.0,         -- global multiplier
    },
}
