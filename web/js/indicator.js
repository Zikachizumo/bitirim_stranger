/* ---------------------------------------------------------------------------
   indicator.js — reconciles the per-frame indicator batch from Lua into DOM.

   Each player has TWO independent elements positioned separately:
     .bx-ind-label  name + ID, pinned above the head, follows the ped
     .bx-ind-key    circular G, at chest/waist, only for the interaction target

   No fade / scale / breathing animation — elements appear and track instantly.
--------------------------------------------------------------------------- */

(function () {
    'use strict';

    const layer = document.getElementById('indicator-layer');
    const els = new Map();   // id -> { label, name, id, key }

    function create(id) {
        const label = document.createElement('div');
        label.className = 'bx-ind-label';
        label.innerHTML = '<div class="bx-ind-name"></div><div class="bx-ind-id"></div>';
        layer.appendChild(label);

        const key = document.createElement('div');
        key.className = 'bx-ind-key';
        key.textContent = 'G';
        key.style.display = 'none';
        layer.appendChild(key);

        const rec = {
            label: label,
            name: label.querySelector('.bx-ind-name'),
            id: label.querySelector('.bx-ind-id'),
            key: key,
        };
        els.set(id, rec);
        return rec;
    }

    function removeEl(id) {
        const rec = els.get(id);
        if (!rec) return;
        if (rec.label.parentNode) rec.label.parentNode.removeChild(rec.label);
        if (rec.key.parentNode) rec.key.parentNode.removeChild(rec.key);
        els.delete(id);
    }

    function update(items) {
        const seen = new Set();

        for (let i = 0; i < items.length; i++) {
            const it = items[i];
            seen.add(it.id);

            const rec = els.get(it.id) || create(it.id);

            // Name / ID label — above the head.
            rec.label.style.left = (it.labelX * 100) + '%';
            rec.label.style.top = (it.labelY * 100) + '%';
            rec.label.classList.toggle('bx-known', !!it.known);
            if (rec.name.textContent !== it.name) rec.name.textContent = it.name;
            // The permanent number may not have replicated yet — omit the line
            // entirely rather than showing a placeholder or a session id.
            if (it.sid === undefined || it.sid === null) {
                rec.id.style.display = 'none';
            } else {
                rec.id.style.display = '';
                const idText = 'ID: ' + it.sid;
                if (rec.id.textContent !== idText) rec.id.textContent = idText;
            }

            // G key — chest/waist, target only.
            if (it.isTarget && it.keyOn) {
                rec.key.style.display = 'flex';
                rec.key.style.left = (it.keyX * 100) + '%';
                rec.key.style.top = (it.keyY * 100) + '%';
            } else {
                rec.key.style.display = 'none';
            }
        }

        els.forEach((rec, id) => {
            if (!seen.has(id)) removeEl(id);
        });
    }

    window.Bitirim.on('indicators', function (data) {
        update(data.items || []);
    });
})();
