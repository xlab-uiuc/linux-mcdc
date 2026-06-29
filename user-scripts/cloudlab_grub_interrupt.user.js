// ==UserScript==
// @name         CloudLab GRUB Auto-Interrupt
// @namespace    https://www.cloudlab.us
// @version      2026-06
// @description  Automatically sends arrow keys when GRUB menu is detected on CloudLab serial console to stop the countdown timer
// @author       Claude Opus 4.6
// @match        https://*.cloudlab.us/webssh*
// @match        https://www.cloudlab.us/status.php*
// @run-at       document-start
// @grant        none
// ==/UserScript==

(function() {
    'use strict';

    const LOG_PREFIX = '[GRUB]';
    function log(...args) { console.log(LOG_PREFIX, ...args); }

    const STORAGE_KEY = 'grub_auto_interrupt_enabled';

    // =========================================================================
    // PARENT PAGE: Status page UI (https://www.cloudlab.us/status.php*)
    // =========================================================================
    if (location.hostname === 'www.cloudlab.us' && location.pathname.startsWith('/status.php')) {
        runParentUI();
        return;
    }

    // =========================================================================
    // IFRAME: WebSocket terminal detection (*.cloudlab.us/webssh*)
    // =========================================================================
    runIframeDetector();

    // -------------------------------------------------------------------------
    function runParentUI() {
        // Wait for DOM ready
        if (document.readyState === 'loading') {
            document.addEventListener('DOMContentLoaded', initParentUI);
        } else {
            initParentUI();
        }

        function initParentUI() {
            const enabled = localStorage.getItem(STORAGE_KEY) !== 'false';

            // Create the control box
            const box = document.createElement('div');
            box.id = 'grub-interrupt-box';
            box.innerHTML = `
                <style>
                    #grub-interrupt-box {
                        position: fixed;
                        bottom: 12px;
                        right: 12px;
                        z-index: 99999;
                        background: #1e1e1e;
                        border: 1px solid #444;
                        border-radius: 8px;
                        padding: 10px 14px;
                        font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
                        font-size: 13px;
                        color: #ddd;
                        box-shadow: 0 2px 12px rgba(0,0,0,0.4);
                        display: flex;
                        align-items: center;
                        gap: 10px;
                        user-select: none;
                    }
                    #grub-interrupt-box .grub-dot {
                        width: 10px;
                        height: 10px;
                        border-radius: 50%;
                        background: #555;
                        transition: background 0.3s;
                    }
                    #grub-interrupt-box .grub-dot.watching { background: #f0ad4e; }
                    #grub-interrupt-box .grub-dot.caught { background: #5cb85c; animation: grub-pulse 0.6s 3; }
                    @keyframes grub-pulse {
                        0%, 100% { box-shadow: 0 0 0 0 rgba(92,184,92,0.6); }
                        50% { box-shadow: 0 0 0 6px rgba(92,184,92,0); }
                    }
                    #grub-interrupt-box label {
                        display: flex;
                        align-items: center;
                        gap: 6px;
                        cursor: pointer;
                        margin: 0;
                    }
                    #grub-interrupt-box .grub-status {
                        font-size: 11px;
                        color: #999;
                    }
                </style>
                <div class="grub-dot" id="grub-dot"></div>
                <label>
                    <input type="checkbox" id="grub-toggle" ${enabled ? 'checked' : ''}>
                    GRUB Catch
                </label>
                <span class="grub-status" id="grub-status">idle</span>
            `;
            document.body.appendChild(box);

            const toggle = document.getElementById('grub-toggle');
            const dot = document.getElementById('grub-dot');
            const statusEl = document.getElementById('grub-status');

            toggle.addEventListener('change', () => {
                const on = toggle.checked;
                localStorage.setItem(STORAGE_KEY, on);
                broadcastToIframes({type: 'grub-control', enabled: on});
                if (!on) {
                    dot.className = 'grub-dot';
                    statusEl.textContent = 'disabled';
                } else {
                    statusEl.textContent = 'enabled';
                }
            });

            // Listen for messages from console iframes
            window.addEventListener('message', (e) => {
                if (!e.data || e.data.type !== 'grub-status') return;
                if (e.data.status === 'watching') {
                    dot.className = 'grub-dot watching';
                    statusEl.textContent = 'watching...';
                } else if (e.data.status === 'caught') {
                    dot.className = 'grub-dot caught';
                    statusEl.textContent = 'GRUB caught!';
                }
            });

            function broadcastToIframes(msg) {
                const iframes = document.querySelectorAll('iframe');
                iframes.forEach(f => {
                    try { f.contentWindow.postMessage(msg, '*'); } catch(e) {}
                });
            }

            // Notify iframes of initial state
            setTimeout(() => broadcastToIframes({type: 'grub-control', enabled}), 1000);
        }
    }

    // -------------------------------------------------------------------------
    function runIframeDetector() {
        const GRUB_PATTERN = 'GNU GRUB';
        const CHECK_INTERVAL_MS = 500;
        const MAX_DETECTION_TIME_MS = 5 * 60 * 1000;
        const ARROW_KEY_CYCLES = 3;
        const ARROW_DELAY_MS = 100;

        let capturedWs = null;
        let grubHandled = false;
        let enabled = localStorage.getItem(STORAGE_KEY) !== 'false';
        let wsDataAccumulator = '';

        // Listen for enable/disable from parent
        window.addEventListener('message', (e) => {
            if (e.data && e.data.type === 'grub-control') {
                enabled = e.data.enabled;
                log('Detection', enabled ? 'enabled' : 'disabled', 'by parent');
            }
        });

        function notifyParent(status) {
            try { window.parent.postMessage({type: 'grub-status', status}, '*'); } catch(e) {}
        }

        // --- Hook WebSocket ---
        const OrigWebSocket = window.WebSocket;
        window.WebSocket = new Proxy(OrigWebSocket, {
            construct(target, args) {
                const instance = new target(...args);
                capturedWs = instance;
                log('WebSocket connected');
                instance.addEventListener('open', () => notifyParent('watching'));
                // Sniff incoming data for GRUB
                instance.addEventListener('message', (event) => {
                    if (grubHandled || !enabled) return;
                    const handle = (text) => {
                        wsDataAccumulator += text;
                        if (wsDataAccumulator.length > 4096) {
                            wsDataAccumulator = wsDataAccumulator.slice(-4096);
                        }
                        if (wsDataAccumulator.includes(GRUB_PATTERN)) {
                            onGrubDetected();
                        }
                    };
                    if (event.data instanceof Blob) {
                        event.data.text().then(handle);
                    } else if (typeof event.data === 'string') {
                        handle(event.data);
                    }
                });
                return instance;
            }
        });

        // --- Hook Terminal.prototype.open for buffer-based detection ---
        let capturedTerm = null;
        let checkInterval = null;
        const waitForTerminal = setInterval(() => {
            if (window.Terminal && window.Terminal.prototype) {
                clearInterval(waitForTerminal);
                const origOpen = window.Terminal.prototype.open;
                window.Terminal.prototype.open = function(element) {
                    capturedTerm = this;
                    origOpen.call(this, element);
                    startBufferPolling();
                };
            }
        }, 50);

        function getBufferText() {
            if (!capturedTerm || !capturedTerm.buffer) return '';
            try {
                let buffer = capturedTerm.buffer.active || capturedTerm.buffer;
                if (typeof buffer.getLine !== 'function') {
                    buffer = (capturedTerm._core && capturedTerm._core.buffer) ||
                             (capturedTerm._core && capturedTerm._core._bufferService &&
                              capturedTerm._core._bufferService.buffer);
                }
                if (!buffer) return '';
                if (typeof buffer.getLine === 'function') {
                    const lines = [];
                    const len = buffer.length || buffer.lines?.length || 0;
                    for (let i = 0; i < len; i++) {
                        const line = buffer.getLine(i);
                        if (line) lines.push(line.translateToString());
                    }
                    return lines.join('\n');
                }
                if (buffer.lines) {
                    const lines = [];
                    for (let i = 0; i < buffer.lines.length; i++) {
                        const line = buffer.lines.get ? buffer.lines.get(i) : buffer.lines[i];
                        if (line && typeof line.translateToString === 'function') {
                            lines.push(line.translateToString());
                        }
                    }
                    return lines.join('\n');
                }
                return '';
            } catch (e) { return ''; }
        }

        function startBufferPolling() {
            checkInterval = setInterval(() => {
                if (grubHandled || !enabled) return;
                const text = getBufferText();
                if (text.includes(GRUB_PATTERN)) {
                    onGrubDetected();
                }
            }, CHECK_INTERVAL_MS);

            setTimeout(() => {
                if (checkInterval) clearInterval(checkInterval);
            }, MAX_DETECTION_TIME_MS);
        }

        function onGrubDetected() {
            if (grubHandled) return;
            grubHandled = true;
            if (checkInterval) clearInterval(checkInterval);
            log('GRUB detected — sending arrow keys');
            notifyParent('caught');
            sendArrowKeys();
        }

        function sendRawData(data) {
            if (capturedWs && capturedWs.readyState === WebSocket.OPEN) {
                capturedWs.send(JSON.stringify({'data': data}));
                return;
            }
            if (window.wssh && window.wssh.send) {
                window.wssh.send(JSON.stringify({'data': data}));
            }
        }

        function sendArrowKeys() {
            let delay = 0;
            for (let i = 0; i < ARROW_KEY_CYCLES; i++) {
                setTimeout(() => sendRawData('\x1b[B'), delay);
                delay += ARROW_DELAY_MS;
                setTimeout(() => sendRawData('\x1b[A'), delay);
                delay += ARROW_DELAY_MS;
            }
        }
    }
})();
