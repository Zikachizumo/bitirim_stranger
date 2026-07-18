/* ---------------------------------------------------------------------------
   bridge.js — the single NUI message router + Lua callback helper.
   Every module registers a handler here; Lua sends { action, ... } via
   SendNUIMessage and we dispatch to the right module.
--------------------------------------------------------------------------- */

(function () {
    'use strict';

    const Bridge = {
        resourceName: 'bitirim_stranger',
        handlers: {},
        config: {},
    };

    // Resolve the parent resource name (FiveM injects GetParentResourceName).
    try {
        if (typeof GetParentResourceName === 'function') {
            Bridge.resourceName = GetParentResourceName();
        }
    } catch (e) { /* running outside FiveM (browser preview) */ }

    /** POST to a Lua RegisterNUICallback. Safe no-op outside FiveM. */
    Bridge.post = function (name, data) {
        return fetch(`https://${Bridge.resourceName}/${name}`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json; charset=UTF-8' },
            body: JSON.stringify(data || {}),
        }).catch(() => {});
    };

    /** Register a handler for a given action string. */
    Bridge.on = function (action, fn) {
        Bridge.handlers[action] = fn;
    };

    /** "#RRGGBB" + alpha -> "rgba(r, g, b, a)". Returns null on bad input. */
    function hexToRgba(hex, alpha) {
        if (typeof hex !== 'string') return null;
        let h = hex.trim().replace('#', '');
        if (h.length === 3) h = h[0] + h[0] + h[1] + h[1] + h[2] + h[2];
        if (h.length !== 6 || /[^0-9a-fA-F]/.test(h)) return null;
        const r = parseInt(h.slice(0, 2), 16);
        const g = parseInt(h.slice(2, 4), 16);
        const b = parseInt(h.slice(4, 6), 16);
        const a = Math.max(0, Math.min(1, Number(alpha)));
        return `rgba(${r}, ${g}, ${b}, ${isNaN(a) ? 0.75 : a})`;
    }

    /** Apply the theme + config pushed from Lua onto CSS custom properties. */
    Bridge.applyTheme = function (theme, config) {
        if (config) Bridge.config = config;
        if (!theme) return;
        const root = document.documentElement.style;
        const c = theme.colors || {};
        const g = theme.glass || {};
        const glow = theme.glow || {};
        const t = theme.typography || {};
        const a = theme.animation || {};

        const set = (k, v) => { if (v !== undefined && v !== null) root.setProperty(k, v); };

        set('--bx-accent', c.accent);
        set('--bx-accent-soft', c.accentSoft);
        set('--bx-bg', c.background);
        set('--bx-surface', c.surface);
        set('--bx-text', c.text);
        set('--bx-text-muted', c.textMuted);
        set('--bx-stranger', c.stranger);
        set('--bx-known', c.known);
        set('--bx-success', c.success);
        set('--bx-danger', c.danger);
        set('--bx-warning', c.warning);

        // FiveM's CEF supports neither color-mix() nor a usable backdrop-filter,
        // so the panel fill is resolved here into a plain rgba() string.
        const panelRgba = hexToRgba(
            g.panelColor || '#000000',
            g.panelOpacity !== undefined ? g.panelOpacity : 0.75
        );
        if (panelRgba) set('--bx-panel-bg', panelRgba);
        if (g.borderOpacity !== undefined) set('--bx-border-opacity', g.borderOpacity);
        set('--bx-shadow', g.shadow);

        set('--bx-glow-color', glow.color);
        if (glow.strength !== undefined) set('--bx-glow', glow.strength + 'px');
        if (glow.pulseStrength !== undefined) set('--bx-glow-pulse', glow.pulseStrength + 'px');

        if (t.primaryFont) set('--bx-font', `'${t.primaryFont}', ${t.fallback || 'sans-serif'}`);
        if (t.labelSize !== undefined) set('--bx-label-size', t.labelSize + 'px');
        if (t.idSize !== undefined) set('--bx-id-size', t.idSize + 'px');
        if (t.weight !== undefined) set('--bx-weight', t.weight);

        if (a.fadeIn !== undefined) set('--bx-fade-in', a.fadeIn + 'ms');
        if (a.fadeOut !== undefined) set('--bx-fade-out', a.fadeOut + 'ms');
        if (a.menuOpen !== undefined) set('--bx-menu-open', a.menuOpen + 'ms');
        if (a.menuClose !== undefined) set('--bx-menu-close', a.menuClose + 'ms');
        if (a.buttonPress !== undefined) set('--bx-press', a.buttonPress + 'ms');
        if (a.breathing !== undefined) set('--bx-breathing', a.breathing + 'ms');
        if (a.scaleSpring !== undefined) set('--bx-scale-spring', a.scaleSpring + 'ms');
    };

    // Central message pump.
    window.addEventListener('message', function (event) {
        const data = event.data;
        if (!data || !data.action) return;
        const fn = Bridge.handlers[data.action];
        if (fn) {
            try { fn(data); } catch (err) { console.error('[bitirim] handler error', data.action, err); }
        }
    });

    // Tell Lua we are mounted and ready to receive the theme/menu.
    window.addEventListener('DOMContentLoaded', function () {
        Bridge.post('bitirim:uiReady', {});
    });

    window.Bitirim = Bridge;
})();
