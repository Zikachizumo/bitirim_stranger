/* ---------------------------------------------------------------------------
   radial.js — renders the circular menu from the config Lua pushes, handles
   submenu navigation, hover/click, and ESC. Icons are inlined (no asset 404s).
--------------------------------------------------------------------------- */

(function () {
    'use strict';

    const root = document.getElementById('radial-root');
    const itemsEl = document.getElementById('radial-items');
    const centerLabel = document.getElementById('radial-center-label');

    let menu = null;          // top-level config { centerLabel, entries }
    let stack = [];           // navigation stack of entry arrays
    let baseCenter = 'Player Interaction';
    let isOpen = false;

    // Minimal inline icon set (stroke = currentColor).
    const P = (d) => `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">${d}</svg>`;
    const ICONS = {
        'documents.svg': P('<path d="M7 3h7l4 4v14H7z"/><path d="M14 3v4h4"/><path d="M10 12h6M10 16h6"/>'),
        'passport.svg':  P('<rect x="5" y="3" width="14" height="18" rx="2"/><circle cx="12" cy="10" r="2.5"/><path d="M8 16h8"/>'),
        'license.svg':   P('<rect x="3" y="6" width="18" height="12" rx="2"/><circle cx="8" cy="12" r="2"/><path d="M13 10h5M13 14h5"/>'),
        'inventory.svg': P('<rect x="4" y="7" width="16" height="13" rx="2"/><path d="M4 7l2-3h12l2 3M9 11h6"/>'),
        'business.svg':  P('<path d="M3 21h18M5 21V8l7-4 7 4v13"/><path d="M10 21v-5h4v5"/>'),
        'police.svg':    P('<path d="M12 3l7 3v5c0 5-3.5 8-7 9-3.5-1-7-4-7-9V6z"/><path d="M12 8v4M10 10h4"/>'),
        'medical.svg':   P('<path d="M12 3l7 3v5c0 5-3.5 8-7 9-3.5-1-7-4-7-9V6z"/><path d="M12 9v5M9.5 11.5h5"/>'),
        'gang.svg':      P('<circle cx="9" cy="8" r="3"/><path d="M3 20c0-3 3-5 6-5s6 2 6 5"/><path d="M16 11a3 3 0 100-6"/>'),
        'vehicle.svg':   P('<path d="M4 13l2-5h12l2 5v5H4z"/><circle cx="8" cy="18" r="1.5"/><circle cx="16" cy="18" r="1.5"/>'),
        'house.svg':     P('<path d="M4 11l8-6 8 6v9H4z"/><path d="M10 20v-5h4v5"/>'),
        'interactive.svg': P('<path d="M9 11V5.5a1.5 1.5 0 013 0V11"/><path d="M12 11V4.5a1.5 1.5 0 013 0V11"/><path d="M15 11V6.5a1.5 1.5 0 013 0V13c0 4-2.5 7-6 7s-6-3-6-7v-2a1.5 1.5 0 013 0"/>'),
        'illegal.svg':   P('<path d="M4 9c4-2 12-2 16 0v3c0 3.5-3.5 6-8 6s-8-2.5-8-6z"/><circle cx="9" cy="12" r="1.2"/><circle cx="15" cy="12" r="1.2"/>'),
        'animations.svg':P('<circle cx="12" cy="5" r="2"/><path d="M12 7v6M8 20l4-7 4 7M6 11l6 2 6-2"/>'),
        'phone.svg':     P('<rect x="7" y="3" width="10" height="18" rx="2"/><path d="M11 18h2"/>'),
        'default':       P('<circle cx="12" cy="12" r="8"/>'),
    };

    function iconFor(name) { return ICONS[name] || ICONS.default; }

    function currentEntries() { return stack[stack.length - 1] || []; }

    function render() {
        const entries = currentEntries();
        itemsEl.innerHTML = '';
        const n = entries.length;
        const radius = n <= 6 ? 150 : 165;

        entries.forEach((entry, i) => {
            // Entry #1 always sits at the TOP (12 o'clock); the ring then runs
            // counter-clockwise: top -> left -> bottom -> right -> back up.
            const angle = -Math.PI / 2 - (Math.PI * 2 * i) / n;
            const x = Math.cos(angle) * radius;
            const y = Math.sin(angle) * radius;

            const el = document.createElement('div');
            el.className = 'bx-radial-item';
            if (entry.enabled === false) el.classList.add('bx-disabled');
            el.style.setProperty('--x', x.toFixed(1) + 'px');
            el.style.setProperty('--y', y.toFixed(1) + 'px');
            el.style.transitionDelay = (i * 22) + 'ms';
            el.innerHTML =
                `<div class="bx-radial-icon">${iconFor(entry.icon)}</div>` +
                `<div class="bx-radial-label">${entry.label || ''}</div>`;

            el.addEventListener('click', () => select(entry));
            itemsEl.appendChild(el);
        });
    }

    function select(entry) {
        if (!entry || entry.enabled === false) return;

        if (entry.submenu && entry.submenu.length) {
            stack.push(entry.submenu);
            centerLabel.textContent = entry.label;
            // Re-trigger entrance animation for the new ring.
            root.classList.remove('bx-open');
            requestAnimationFrame(() => {
                render();
                requestAnimationFrame(() => root.classList.add('bx-open'));
            });
            return;
        }

        if (entry.action) {
            window.Bitirim.post('bitirim:radialSelect', { action: entry.action, id: entry.id });
            // Lua will close the menu.
        }
    }

    function goBackOrClose() {
        if (stack.length > 1) {
            stack.pop();
            centerLabel.textContent = stack.length === 1 ? baseCenter : centerLabel.textContent;
            root.classList.remove('bx-open');
            requestAnimationFrame(() => {
                render();
                requestAnimationFrame(() => root.classList.add('bx-open'));
            });
        } else {
            window.Bitirim.post('bitirim:radialClose', {});
        }
    }

    /** Hard close, whatever submenu depth we are at. */
    function requestClose() {
        window.Bitirim.post('bitirim:radialClose', {});
    }

    /** Keep DOM keyboard focus on the page so Escape always reaches us. */
    function ensureFocus() {
        try { root.focus({ preventScroll: true }); } catch (e) { try { root.focus(); } catch (e2) {} }
    }

    function open(data) {
        if (!menu) return;
        baseCenter = data.centerLabel || menu.centerLabel || 'Player Interaction';
        centerLabel.textContent = baseCenter;
        stack = [menu.entries];
        isOpen = true;
        root.classList.remove('bx-hidden', 'bx-closing');
        root.setAttribute('tabindex', '-1');
        render();
        requestAnimationFrame(() => {
            root.classList.add('bx-open');
            ensureFocus();
        });
    }

    function close() {
        if (!isOpen) return;
        isOpen = false;
        root.classList.add('bx-closing');
        root.classList.remove('bx-open');
        setTimeout(() => {
            root.classList.add('bx-hidden');
            root.classList.remove('bx-closing');
            itemsEl.innerHTML = '';
        }, 220);
    }

    document.addEventListener('keydown', function (e) {
        if (!isOpen) return;
        if (e.key === 'Escape') {
            e.preventDefault();
            goBackOrClose();
        }
    });

    // Clicking anywhere outside the ring closes the menu. Without this the
    // only exits were Escape and picking an item, so a lost keyboard focus
    // left no way out at all.
    document.getElementById('radial-blur').addEventListener('mousedown', function () {
        if (isOpen) requestClose();
    });

    // Alt-tabbing away used to strand the menu open (the page stops receiving
    // key events). Close on blur, and re-take focus if we come back still open.
    window.addEventListener('blur', function () {
        if (isOpen) requestClose();
    });
    window.addEventListener('focus', function () {
        if (isOpen) ensureFocus();
    });
    document.addEventListener('visibilitychange', function () {
        if (!isOpen) return;
        if (document.hidden) { requestClose(); } else { ensureFocus(); }
    });

    // Wire messages.
    window.Bitirim.on('init', function (data) {
        window.Bitirim.applyTheme(data.theme, data.config);
        menu = data.menu || null;
    });
    window.Bitirim.on('radialOpen', open);
    window.Bitirim.on('radialClose', close);
})();
