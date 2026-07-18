/* ---------------------------------------------------------------------------
   indicator.js — reconciles the per-frame indicator batch from Lua into DOM.
   Creates elements on first sight (fade in), updates position/scale/label
   every frame, and fades out elements that leave the batch.
--------------------------------------------------------------------------- */

(function () {
    'use strict';

    const layer = document.getElementById('indicator-layer');
    const els = new Map();          // id -> { root, name, id, removing }
    const REMOVE_MS = 220;          // must be >= --bx-fade-out

    function create(id) {
        const root = document.createElement('div');
        root.className = 'bx-indicator';
        root.innerHTML = `
            <div class="bx-ind-card">
                <div class="bx-ind-name"></div>
                <div class="bx-ind-id"></div>
            </div>
            <div class="bx-ind-dot"></div>
            <div class="bx-ind-key">G</div>`;
        layer.appendChild(root);
        const rec = {
            root: root,
            name: root.querySelector('.bx-ind-name'),
            id: root.querySelector('.bx-ind-id'),
            removing: false,
        };
        // Force reflow then fade in.
        requestAnimationFrame(() => root.classList.add('bx-in'));
        els.set(id, rec);
        return rec;
    }

    function remove(id) {
        const rec = els.get(id);
        if (!rec || rec.removing) return;
        rec.removing = true;
        rec.root.classList.remove('bx-in');
        rec.root.classList.add('bx-out');
        setTimeout(() => {
            if (rec.root.parentNode) rec.root.parentNode.removeChild(rec.root);
            els.delete(id);
        }, REMOVE_MS);
    }

    function update(items) {
        const seen = new Set();

        for (let i = 0; i < items.length; i++) {
            const it = items[i];
            seen.add(it.id);

            let rec = els.get(it.id);
            if (!rec || rec.removing) {
                // If it was fading out, drop it and recreate cleanly.
                if (rec && rec.removing) {
                    if (rec.root.parentNode) rec.root.parentNode.removeChild(rec.root);
                    els.delete(it.id);
                }
                rec = create(it.id);
            }

            const root = rec.root;
            root.style.left = (it.x * 100) + '%';
            root.style.top = (it.y * 100) + '%';
            root.style.setProperty('--bx-s', it.scale || 1);

            root.classList.toggle('bx-known', !!it.known);
            root.classList.toggle('bx-target', !!it.isTarget);

            if (rec.name.textContent !== it.name) rec.name.textContent = it.name;
            const idText = 'ID: ' + it.sid;
            if (rec.id.textContent !== idText) rec.id.textContent = idText;
        }

        // Fade out anything no longer present.
        els.forEach((rec, id) => {
            if (!seen.has(id)) remove(id);
        });
    }

    window.Bitirim.on('indicators', function (data) {
        update(data.items || []);
    });
})();
