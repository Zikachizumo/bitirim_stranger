/* ---------------------------------------------------------------------------
   passport.js — the request prompt (with live countdown ring) and the
   passport document modal.
--------------------------------------------------------------------------- */

(function () {
    'use strict';

    const promptEl = document.getElementById('passport-prompt');
    const modalEl = document.getElementById('passport-modal');

    const R = 20;
    const CIRC = 2 * Math.PI * R;

    let rafId = null;
    let promptActive = false;
    let acceptKey = 'Y';
    let declineKey = 'N';

    // Inline person placeholder for the photo slot (no external asset needed).
    const PHOTO_SVG =
        '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">' +
        '<circle cx="12" cy="9" r="4"/><path d="M4 21c0-4 4-6 8-6s8 2 8 6"/></svg>';

    /* ----- REQUEST PROMPT ----- */
    function showPrompt(data) {
        cancelCountdown();
        promptActive = true;
        const total = (data.timeout || 10);
        acceptKey = (window.Bitirim.config.acceptKey || 'Y');
        declineKey = (window.Bitirim.config.declineKey || 'N');
        const accKey = acceptKey;
        const decKey = declineKey;

        promptEl.innerHTML = `
            <div class="bx-prompt-card bx-glass">
                <div class="bx-prompt-head">
                    <div class="bx-prompt-ring">
                        <svg width="46" height="46" viewBox="0 0 46 46">
                            <circle class="bx-ring-bg" cx="23" cy="23" r="${R}"></circle>
                            <circle class="bx-ring-fg" cx="23" cy="23" r="${R}"
                                stroke-dasharray="${CIRC.toFixed(2)}" stroke-dashoffset="0"></circle>
                        </svg>
                        <div class="bx-prompt-count">${total}</div>
                    </div>
                    <div>
                        <div class="bx-prompt-title">Passport Request</div>
                        <div class="bx-prompt-sub"><b>${escapeHtml(data.senderName || 'Someone')}</b> wants to show you their passport</div>
                    </div>
                </div>
                <div class="bx-prompt-actions">
                    <div class="bx-prompt-btn bx-accept" data-accept="1">Accept <span class="bx-kbd">${accKey}</span></div>
                    <div class="bx-prompt-btn bx-decline" data-accept="0">Decline <span class="bx-kbd">${decKey}</span></div>
                </div>
            </div>`;

        promptEl.classList.remove('bx-hidden');
        requestAnimationFrame(() => promptEl.classList.add('bx-show'));

        const fg = promptEl.querySelector('.bx-ring-fg');
        const count = promptEl.querySelector('.bx-prompt-count');
        promptEl.querySelectorAll('.bx-prompt-btn').forEach((btn) => {
            btn.addEventListener('click', () => {
                window.Bitirim.post('bitirim:passportRespond', { accepted: btn.dataset.accept === '1' });
                hidePrompt();
            });
        });

        const start = performance.now();
        const durationMs = total * 1000;
        function tick(now) {
            const elapsed = now - start;
            const remaining = Math.max(0, durationMs - elapsed);
            const frac = remaining / durationMs;
            fg.style.strokeDashoffset = (CIRC * (1 - frac)).toFixed(2);
            count.textContent = Math.ceil(remaining / 1000);
            if (remaining > 0) {
                rafId = requestAnimationFrame(tick);
            }
        }
        rafId = requestAnimationFrame(tick);
    }

    function hidePrompt() {
        cancelCountdown();
        promptActive = false;
        promptEl.classList.remove('bx-show');
        setTimeout(() => {
            promptEl.classList.add('bx-hidden');
            promptEl.innerHTML = '';
        }, 220);
    }

    function cancelCountdown() {
        if (rafId) { cancelAnimationFrame(rafId); rafId = null; }
    }

    /* ----- PASSPORT DOCUMENT ----- */
    function showPassport(data) {
        const p = data.passport || {};
        const fields = (p.fields || []).map((f) =>
            `<div class="bx-pp-field">
                <div class="bx-pp-label">${escapeHtml(f.label)}</div>
                <div class="bx-pp-value">${escapeHtml(f.value)}</div>
            </div>`).join('');

        const photo = p.showPhoto
            ? `<div class="bx-pp-photo">${PHOTO_SVG}</div>` : '';

        const signature = p.signature
            ? `<div>
                   <div class="bx-pp-sign-label">Signature</div>
                   <div class="bx-pp-signature">${escapeHtml(p.signature)}</div>
               </div>` : '<div></div>';

        modalEl.innerHTML = `
            <div class="bx-passport">
                <div class="bx-pp-header">
                    <div class="bx-pp-title">${escapeHtml(p.title || 'PASSPORT')}</div>
                    <div class="bx-pp-subtitle">${escapeHtml(p.subtitle || '')}</div>
                </div>
                <div class="bx-pp-body">
                    ${photo}
                    <div class="bx-pp-fields">${fields}</div>
                </div>
                <div class="bx-pp-footer">
                    ${signature}
                    <div class="bx-pp-close" id="bx-pp-close">Close</div>
                </div>
            </div>`;

        modalEl.classList.remove('bx-hidden');
        requestAnimationFrame(() => modalEl.classList.add('bx-show'));

        document.getElementById('bx-pp-close').addEventListener('click', () => {
            window.Bitirim.post('bitirim:passportClose', {});
        });
    }

    function hidePassport() {
        modalEl.classList.remove('bx-show');
        setTimeout(() => {
            modalEl.classList.add('bx-hidden');
            modalEl.innerHTML = '';
        }, 220);
    }

    // ESC closes the passport modal (has NUI focus).
    document.addEventListener('keydown', function (e) {
        if (e.key === 'Escape' && modalEl.classList.contains('bx-show')) {
            e.preventDefault();
            window.Bitirim.post('bitirim:passportClose', {});
            return;
        }
        // Y / N answer the request prompt (NUI has keep-input focus while shown).
        if (promptActive) {
            const k = (e.key || '').toLowerCase();
            if (k === acceptKey.toLowerCase()) {
                e.preventDefault();
                window.Bitirim.post('bitirim:passportRespond', { accepted: true });
                hidePrompt();
            } else if (k === declineKey.toLowerCase()) {
                e.preventDefault();
                window.Bitirim.post('bitirim:passportRespond', { accepted: false });
                hidePrompt();
            }
        }
    });

    function escapeHtml(s) {
        return String(s == null ? '' : s)
            .replace(/&/g, '&amp;').replace(/</g, '&lt;')
            .replace(/>/g, '&gt;').replace(/"/g, '&quot;');
    }

    window.Bitirim.on('passportPrompt', showPrompt);
    window.Bitirim.on('passportPromptClose', hidePrompt);
    window.Bitirim.on('passportShow', showPassport);
    window.Bitirim.on('passportHide', hidePassport);
})();
