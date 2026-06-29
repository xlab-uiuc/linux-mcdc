// ==UserScript==
// @name         Quick Machine Type Select
// @namespace    http://tampermonkey.net/
// @version      2025-11
// @description  Unselect machine types you don't care about on CloudLab resource availability page
// @author       You
// @match        https://www.cloudlab.us/resinfo.php
// @grant        none
// @run-at       document-end
// ==/UserScript==

(function() {
    'use strict';

    // Wait for charts to load
    function waitForCharts(callback, maxAttempts = 50) {
        let attempts = 0;

        function check() {
            attempts++;
            const charts = document.querySelectorAll('svg.resgraph');

            if (charts.length > 0 || attempts >= maxAttempts) {
                callback();
            } else {
                setTimeout(check, 200);
            }
        }

        check();
    }

    // Helper function to get available charts
    function getAvailableCharts() {
        const charts = [];
        const chartContainers = document.querySelectorAll('[id^="resgraph-"][id$="-servers"]');

        chartContainers.forEach(container => {
            const titleElement = container.closest('.row').querySelector('h5.panel-title');
            const title = titleElement ? titleElement.textContent.trim() : 'Unknown';
            const chartId = container.id;
            const chartName = chartId.replace('resgraph-', '').replace('-servers', '');
            charts.push({
                name: chartName,
                title: title
            });
        });
        return charts;
    }

    // Create a floating control panel
    function createControlPanel() {
        const panel = document.createElement('div');
        panel.id = 'cloudlab-resinfo-click';
        panel.style.cssText = `
            position: fixed;
            top: 20px;
            right: 20px;
            background: rgba(255, 255, 255, 0.95);
            border: 2px solid #007cba;
            border-radius: 8px;
            padding: 15px;
            z-index: 10000;
            font-family: Arial, sans-serif;
            font-size: 12px;
            box-shadow: 0 4px 12px rgba(0, 0, 0, 0.3);
            min-width: 280px;
        `;

        // Get available charts for dropdown
        const availableCharts = getAvailableCharts();
        const buildChartOptions = (defaultName) => availableCharts.map(chart =>
            `<option value="${chart.name}" ${chart.name === defaultName ? 'selected' : ''}>${chart.title}</option>`
        ).join('');

        panel.innerHTML = `
            <div style="margin-bottom: 8px;">
                <label style="display: block; margin-bottom: 4px;">Select Chart:</label>
                <select id="chart-select-1" style="width: 100%; padding: 4px; border: 1px solid #ccc; border-radius: 3px;">
                    ${buildChartOptions('Clemson')}
                </select>
            </div>
            <div style="margin-bottom: 8px;">
                <label style="display: block; margin-bottom: 4px;">Machine types to keep (comma-separated):</label>
                <input type="text" id="series-input-1" value="c6420,c6320"
                       style="width: 100%; padding: 4px; border: 1px solid #ccc; border-radius: 3px;">
            </div>
            <div style="margin-bottom: 8px;">
                <label style="display: block; margin-bottom: 4px;">Select Chart:</label>
                <select id="chart-select-2" style="width: 100%; padding: 4px; border: 1px solid #ccc; border-radius: 3px;">
                    ${buildChartOptions('Utah')}
                </select>
            </div>
            <div style="margin-bottom: 8px;">
                <label style="display: block; margin-bottom: 4px;">Machine types to keep (comma-separated):</label>
                <input type="text" id="series-input-2" value="c6620,d760"
                       style="width: 100%; padding: 4px; border: 1px solid #ccc; border-radius: 3px;">
            </div>
            <div style="margin-bottom: 10px;">
                <button id="toggle-btn" style="background: #007cba; color: white; border: none; padding: 6px 12px; border-radius: 3px; cursor: pointer; width: 100%;">Hide Other Machine Types</button>
            </div>
        `;

        document.body.appendChild(panel);

        // Process a single chart/series pair: hide everything except targetSeries.
        // Returns an error message string on failure, or null on success.
        function processPair(chartName, seriesInput) {
            if (!seriesInput) {
                return 'Please enter at least one series name';
            }

            const targetSeries = seriesInput.split(',').map(s => s.trim());

            let chartContainer = document.getElementById(`resgraph-${chartName}-servers`);

            if (!chartContainer) {
                const titles = document.querySelectorAll('h5.panel-title');
                for (const title of titles) {
                    if (title.textContent.trim().toLowerCase().includes(chartName.toLowerCase()) &&
                        title.textContent.trim().toLowerCase().includes('availability')) {
                        const section = title.closest('.row');
                        if (section) {
                            chartContainer = section.querySelector('[id^="resgraph-"][id$="-servers"]');
                            break;
                        }
                    }
                }
            }

            if (!chartContainer) {
                const msg = `Chart "${chartName}" not found. Available charts: ${availableCharts.map(c => c.name).join(', ')}`;
                console.error(msg);
                return msg;
            }

            const chart = chartContainer.querySelector('svg.resgraph');
            if (!chart) {
                const msg = `No chart found in ${chartName} section`;
                console.error(msg);
                return msg;
            }

            const legendSeries = chart.querySelectorAll('g.nv-series');

            legendSeries.forEach(series => {
                const textElement = series.querySelector('text.nv-legend-text');
                if (!textElement) return;

                const seriesName = textElement.textContent.trim();
                const shouldClick = !targetSeries.includes(seriesName);

                if (shouldClick) {
                    series.dispatchEvent(new Event('click', { bubbles: true }));
                }
            });

            return null;
        }

        document.getElementById('toggle-btn').addEventListener('click', function() {
            const pairs = [
                {
                    chartName: document.getElementById('chart-select-1').value,
                    seriesInput: document.getElementById('series-input-1').value.trim()
                },
                {
                    chartName: document.getElementById('chart-select-2').value,
                    seriesInput: document.getElementById('series-input-2').value.trim()
                }
            ];

            try {
                const errors = [];
                pairs.forEach((pair, idx) => {
                    const err = processPair(pair.chartName, pair.seriesInput);
                    if (err) {
                        errors.push(`Chart ${idx + 1}: ${err}`);
                    }
                });

                if (errors.length > 0) {
                    alert(errors.join('\n'));
                }
            } catch (error) {
                console.error('Error toggling series:', error);
                alert('Error: ' + error.message);
            }
        });

        // Make panel draggable
        let isDragging = false;
        let startX, startY, startLeft, startTop;

        panel.addEventListener('mousedown', function(e) {
            if (e.target.tagName === 'BUTTON' || e.target.tagName === 'INPUT' ||
                e.target.tagName === 'A' || e.target.tagName === 'LABEL') return;

            isDragging = true;
            startX = e.clientX;
            startY = e.clientY;
            startLeft = panel.offsetLeft;
            startTop = panel.offsetTop;
            panel.style.cursor = 'move';
        });

        document.addEventListener('mousemove', function(e) {
            if (!isDragging) return;

            const dx = e.clientX - startX;
            const dy = e.clientY - startY;

            panel.style.left = (startLeft + dx) + 'px';
            panel.style.top = (startTop + dy) + 'px';
            panel.style.right = 'auto';
        });

        document.addEventListener('mouseup', function() {
            isDragging = false;
            panel.style.cursor = 'default';
        });
    }

    // Initialize when charts are loaded
    waitForCharts(function() {
        createControlPanel();
    });

})();
