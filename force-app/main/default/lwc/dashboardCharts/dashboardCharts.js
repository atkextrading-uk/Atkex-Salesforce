import { LightningElement, wire, track, api } from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';
import CHARTJS from '@salesforce/resourceUrl/chartjs';
import { CurrentPageReference } from 'lightning/navigation';

import getHedges from '@salesforce/apex/DashboardChartsController.getHedges';
import getEquity from '@salesforce/apex/DashboardChartsController.getEquity';

export default class DashboardCharts extends LightningElement {
    chartLibLoaded = false;
    @api recordId;

    // Chart instances
    winLossChart;
    equityChart;
    splitChart;
    pairChart;
    drawdownChart;          // ✅ NEW
    _resizeObs;

    // ---- filters (default: this month) ----
    @track startDateStr;
    @track endDateStr;

    // ---- trade data (hedges) ----
    records = [];

    // ---- equity data from MetaTrader ----
    equityRaw = [];         // ✅ NEW raw points from getEquity
    equityTimestamps = [];  // ✅ NEW x-axis labels for equity/drawdown
    equityCurve = [];       // ✅ NEW equity curve we derive (number array)
    drawdownSeries = [];    // ✅ NEW drawdown % at each point
    maxDDSeries = [];       // ✅ NEW running max drawdown so far
    overallWorstSeries = [];

    // ---- derived from trades ----
    winCount = 0;
    lossCount = 0;
    equitySeries = [];
    plSeries = [];
    tradeLabels = [];
    pairLabels = [];
    pairCounts = [];
    avgPL = 0;

    @wire(CurrentPageReference)
    handlePageRef(pageRef) {
        if (!pageRef) return;
        this.recordId =
            pageRef?.attributes?.recordId ||
            pageRef?.state?.recordId ||
            pageRef?.state?.c__recordId ||
            pageRef?.state?.id ||
            this._recordIdFromUrl() ||
            this.recordId;
    }

    // Helper: pull recordId from /s/detail/xxxx style URLs if needed
    _recordIdFromUrl() {
        try {
            const path = window.location.pathname || '';
            const match = path.match(/\/s\/[^/]*\/([^/]{15,18})/);
            return match ? match[1] : null;
        } catch (e) {
            return null;
        }
    }

    // ---------- lifecycle ----------
    connectedCallback() {
        const today = new Date();
        const first = new Date(today.getFullYear(), today.getMonth(), 1);
        const last = new Date(today.getFullYear(), today.getMonth() + 1, 0);
        this.startDateStr = first.toISOString().slice(0, 10);
        this.endDateStr = last.toISOString().slice(0, 10);
    }

    renderedCallback() {
        if (this.chartLibLoaded) return;
        this.chartLibLoaded = true;
        this.init();
    }

    async init() {
        try {
            await this.loadChartJsWithFallback();

            // Register everything (harmless if UMD already did it)
            try {
                if (window.Chart?.registerables) {
                    window.Chart.register(...window.Chart.registerables);
                }
            } catch (e) {
                /* no-op */
            }

            // Wait for canvases to size (now includes drawdown canvas)
            await this.waitForAllCanvasesSized();

            // First paint
            requestAnimationFrame(() => this.renderAll());
        } catch (e) {
            // eslint-disable-next-line no-console
            console.error('Chart init failed:', e);
        }
    }

    loadChartJsWithFallback() {
        // If you uploaded chart.umd.min.js in a folder, you'd try that first.
        // Right now you're importing CHARTJS directly, so just load it.
        return loadScript(this, CHARTJS);
    }

    async waitForAllCanvasesSized() {
        const sels = [
            'canvas.chart-winloss',
            'canvas.chart-equity',
            'canvas.chart-split',
            'canvas.chart-pair',
            'canvas.chart-drawdown' // ✅ NEW
        ];

        await new Promise(resolve => {
            const tick = () => {
                const els = sels.map(s => this.template.querySelector(s));
                const allPresent = els.every(el => !!el);
                const allSized = els.every(
                    el => el && el.clientWidth > 0 && el.clientHeight > 0
                );
                if (!allPresent || !allSized) {
                    requestAnimationFrame(tick);
                } else {
                    resolve();
                }
            };
            tick();
        });
    }

  @wire(getHedges, {
    startDate: '$startDateStr',
    endDate: '$endDateStr',
    recordId: '$recordId'
  })
  wiredHedges({ data, error }) {
      if (data) {
          // Normalize shape: Apex returns {startDate, endDate, records:[...]}
          const rows = Array.isArray(data) ? data : data.records || [];
          this.records = rows;

          // build derived trade series (P/L, equity from trades, win/loss, etc)
          this.computeSeriesFromTrades();

          // 🔁 also pull live equity/drawdown from MetaTrader
          this.fetchEquity()

          // redraw charts
          requestAnimationFrame(() => this.renderAll());
      } else if (error) {
          console.error('getHedges Apex error', error);

          // fall back to empty trade data so charts don't explode
          this.records = [];
          this.computeSeriesFromTrades();

          // 🔁 still try to get MetaTrader equity even if hedges query failed
          this.fetchEquity();

          requestAnimationFrame(() => this.renderAll());
      }
  }

    fetchEquity() {
      if (!this.startDateStr || !this.endDateStr || !this.recordId) {
          return;
      }

      getEquity({
          startDate: this.startDateStr,
          endDate: this.endDateStr,
          recordId: this.recordId
      })
      .then(data => {
          if (data && data.success) {
              this.equityRaw = Array.isArray(data.raw) ? data.raw : [];
          } else {
              this.equityRaw = [];
              // optional: console.warn(data?.message);
          }

          this.computeSeriesFromEquity();
          requestAnimationFrame(() => this.renderAll());
      })
      .catch(error => {
          console.error('getEquity error:', error);
          this.equityRaw = [];
          this.computeSeriesFromEquity();
          requestAnimationFrame(() => this.renderAll());
      });
   }

    // ---------- derive series from trade records ----------
    computeSeriesFromTrades() {
        const pairs = new Map();
        const pl = [];
        const labels = [];
        let wins = 0,
            losses = 0;

        (this.records || []).forEach((r, i) => {
            const profit = Number(r.profit ?? r.Profit__c ?? 0);
            const pair =
                r.pair ??
                r.Pair__c ??
                'Unknown';
            const rawOut =
                r.outcome ??
                r.Outcome__c ??
                (profit >= 0 ? 'Win' : 'Loss');
            const outcome = String(rawOut).toLowerCase();

            if (outcome === 'win') wins++;
            else losses++;

            pl.push(profit);
            labels.push(`T${i + 1}`);

            pairs.set(pair, (pairs.get(pair) || 0) + 1);
        });

        // equity curve from trades (cumulative P/L)
        const equityFromTrades = [];
        let running = 0;
        pl.forEach(v => {
            running += v;
            equityFromTrades.push(running);
        });

        const avg =
            pl.length
                ? pl.reduce((a, b) => a + b, 0) / pl.length
                : 0;

        this.winCount = wins;
        this.lossCount = losses;
        this.plSeries = pl;
        this.tradeLabels = labels;
        this.equitySeries = equityFromTrades;
        this.avgPL = avg;
        this.pairLabels = Array.from(pairs.keys());
        this.pairCounts = Array.from(pairs.values());
    }

    // ---------- derive equity + drawdown series from MetaTrader data ----------
    computeSeriesFromEquity() {
        // 1. Sort by time to keep days in order
        const sorted = [...(this.equityRaw || [])].sort((a, b) => {
            const ta = a.brokerTime || '';
            const tb = b.brokerTime || '';
            return ta.localeCompare(tb);
        });

        const timestamps = [];
        const dailyDDSeries = [];       // "Current Day Drawdown %"
        const dailyWorstSeries = [];    // "Worst Drawdown Today %"
        const equityCurve = [];

        let currentDay = null;
        let dayStartBalance = null;
        let worstToday = 0; // most negative we've hit so far today

        // We'll also track global worst drawdown we've *ever* seen
        let globalWorstDD = 0; // will get more negative over time

        sorted.forEach(pt => {
            const ts = pt.brokerTime || '';

            const currentBalance = Number(pt.lastBalance ?? pt.maxBalance ?? 0);
            const currentEquity  = Number(pt.lastEquity  ?? pt.maxEquity  ?? 0);

            // yyyy-MM-dd to know if day changed
            const dayStr = ts.substring(0, 10);

            if (dayStr !== currentDay) {
                currentDay = dayStr;
                dayStartBalance = currentBalance;
                worstToday = 0;
            }

            // drawdown vs start-of-day
            let ddNow = 0;
            if (dayStartBalance > 0) {
                ddNow = ((currentEquity - dayStartBalance) / dayStartBalance) * 100.0;
            }

            // update today's worst
            if (ddNow < worstToday) {
                worstToday = ddNow;
            }

            // update global worst (most negative we've *ever* seen across ALL days)
            if (ddNow < globalWorstDD) {
                globalWorstDD = ddNow;
            }

            timestamps.push(ts);
            dailyDDSeries.push(ddNow);
            dailyWorstSeries.push(worstToday);
            equityCurve.push(currentEquity);
        });

        // Build the "overall worst" flat line
        const overallWorstSeries = new Array(timestamps.length).fill(globalWorstDD);

        // expose everything for the chart renderer
        this.equityTimestamps   = timestamps;
        this.drawdownSeries     = dailyDDSeries;        // live % today
        this.maxDDSeries        = dailyWorstSeries;     // worst so far *today*
        this.overallWorstSeries = overallWorstSeries;   // worst ever in period
        this.equityCurve        = equityCurve;
    }

    // ---------- render all ----------
    renderAll() {
        try {
            this.renderWinLoss(this.winCount, this.lossCount);
        } catch (e) {
            console.error('Win/Loss error:', e);
        }
        try {
            this.renderEquity(this.tradeLabels, this.equitySeries);
        } catch (e) {
            console.error('Equity error:', e);
        }
        try {
            this.renderSplit(
                this.tradeLabels,
                this.plSeries,
                this.avgPL
            );
        } catch (e) {
            console.error('Split error:', e);
        }
        try {
            this.renderPairs(
                this.pairLabels,
                this.pairCounts
            );
        } catch (e) {
            console.error('Pairs error:', e);
        }
        try {
            this.renderDrawdown(               // ✅ NEW
                this.equityTimestamps,
                this.drawdownSeries,
                this.maxDDSeries,
                this.overallWorstSeries
            );
        } catch (e) {
            console.error('Drawdown error:', e);
        }
    }

    // ---------- chart renderers ----------
    renderWinLoss(wins, losses) {
        const canvas = this.template.querySelector('canvas.chart-winloss');
        if (!window.Chart || !canvas) return;
        this.winLossChart?.destroy();

        const data = {
            labels: ['Win', 'Loss'],
            datasets: [
                {
                    data: [wins, losses],
                    backgroundColor: ['#000000ff', '#a70000ff'],
                    borderWidth: 1
                }
            ]
        };
        const options = {
            responsive: true,
            maintainAspectRatio: false,
            cutout: '65%',
            plugins: {
                legend: { position: 'bottom' },
                tooltip: { mode: 'nearest', intersect: false }
            }
        };

        const labelAndCenterPlugin = {
            id: 'labelAndCenter',
            afterDraw: chart => {
                const {
                    ctx,
                    chartArea: { left, right, top, bottom }
                } = chart;
                const meta = chart.getDatasetMeta(0);
                const ds = chart.data.datasets[0];

                // slice labels
                ctx.save();
                ctx.font = 'bold 13px Arial';
                ctx.fillStyle = '#fff';
                ctx.textAlign = 'center';
                ctx.textBaseline = 'middle';
                meta.data.forEach((el, i) => {
                    const v = ds.data[i];
                    const pos = el.tooltipPosition();
                    ctx.fillText(v, pos.x, pos.y);
                });
                ctx.restore();

                // center %
                const total = (ds.data[0] + ds.data[1]) || 1;
                const winPct = Math.round((ds.data[0] / total) * 100);
                const cx = (left + right) / 2;
                const cy = (top + bottom) / 2;

                ctx.save();
                ctx.textAlign = 'center';
                ctx.textBaseline = 'middle';
                ctx.fillStyle = '#374151';
                ctx.font = 'bold 22px Arial';
                ctx.fillText(`${winPct}%`, cx, cy - 6);
                ctx.font = '12px Arial';
                ctx.fillText('Win Rate', cx, cy + 14);
                ctx.restore();
            }
        };

        this.winLossChart = new window.Chart(
            canvas.getContext('2d'),
            {
                type: 'doughnut',
                data,
                options,
                plugins: [labelAndCenterPlugin]
            }
        );
    }

    renderEquity(labels, equity) {
        const canvas = this.template.querySelector('canvas.chart-equity');
        if (!window.Chart || !canvas) return;
        this.equityChart?.destroy();

        this.equityChart = new window.Chart(
            canvas.getContext('2d'),
            {
                type: 'line',
                data: {
                    labels,
                    datasets: [
                        {
                            label: 'Accumulated Profit',
                            data: equity,
                            tension: 0.25,
                            pointRadius: 2,
                            borderWidth: 2,
                            borderColor: '#000000ff',
                            backgroundColor: '#a70000ff'
                        }
                    ]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: {
                        legend: { display: true },
                        tooltip: { mode: 'index', intersect: false }
                    },
                    scales: {
                        x: { title: { display: true, text: 'Trade' } },
                        y: { title: { display: true, text: 'Profit' } }
                    }
                }
            }
        );
    }

    renderSplit(labels, plSeries, avg) {
        const canvas = this.template.querySelector('canvas.chart-split');
        if (!window.Chart || !canvas) return;
        this.splitChart?.destroy();

        const avgSeries = new Array(plSeries.length).fill(avg);

        this.splitChart = new window.Chart(
            canvas.getContext('2d'),
            {
                type: 'line',
                data: {
                    labels,
                    datasets: [
                        {
                            label: 'Profit/Loss per Trade',
                            data: plSeries,
                            tension: 0,
                            pointRadius: 3,
                            borderWidth: 2,
                            borderColor: '#000000ff',
                            backgroundColor: '#000000ff'
                        },
                        {
                            label: `Average (${Math.round(avg)})`,
                            data: avgSeries,
                            borderWidth: 2,
                            pointRadius: 0,
                            borderDash: [6, 6],
                            borderColor: '#a70000ff',
                            backgroundColor: '#a70000ff'
                        }
                    ]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: {
                        legend: { display: true },
                        tooltip: { mode: 'index', intersect: false }
                    },
                    scales: {
                        x: { title: { display: true, text: 'Trade' } },
                        y: { title: { display: true, text: 'P/L' } }
                    }
                }
            }
        );
    }

    renderPairs(labels, counts) {
        const canvas = this.template.querySelector('canvas.chart-pair');
        if (!window.Chart || !canvas) return;
        this.pairChart?.destroy();

        this.pairChart = new window.Chart(
            canvas.getContext('2d'),
            {
                type: 'bar',
                data: {
                    labels,
                    datasets: [
                        {
                            label: '# Trades',
                            data: counts,
                            borderWidth: 1,
                            borderColor: '#000000ff',
                            backgroundColor: '#a70000ff'
                        }
                    ]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: {
                        legend: { display: true },
                        tooltip: { mode: 'index', intersect: false }
                    },
                    scales: {
                        x: {
                            title: { display: true, text: 'Pair' }
                        },
                        y: {
                            title: { display: true, text: 'Trades' },
                            beginAtZero: true,
                            ticks: { precision: 0 }
                        }
                    }
                }
            }
        );
    }

    // ✅ NEW: drawdown renderer
    renderDrawdown(labels, ddSeries, maxDDSeries, overallWorstSeries) {
      const canvas = this.template.querySelector('canvas.chart-drawdown');
      if (!window.Chart || !canvas) return;
      this.drawdownChart?.destroy();

      this.drawdownChart = new window.Chart(
          canvas.getContext('2d'),
          {
              type: 'line',
              data: {
                  labels,
                  datasets: [
                      {
                          // intraday drawdown vs start-of-day balance right now
                          label: 'Current Day Drawdown %',
                          data: ddSeries,
                          tension: 0.25,
                          pointRadius: 0,
                          borderWidth: 2,
                          borderColor: '#a70000ff',
                          backgroundColor: '#a70000ff'
                      },
                      {
                          // worst you've hit so far in *that* day
                          label: 'Worst Drawdown Today %',
                          data: maxDDSeries,
                          tension: 0.25,
                          pointRadius: 0,
                          borderWidth: 2,
                          borderDash: [4, 4],
                          borderColor: '#000000ff',
                          backgroundColor: '#000000ff'
                      },
                      {
                          // NEW: worst drawdown seen in ENTIRE dataset so far
                          // stays flat at e.g. -4.63%
                          label: 'All-Time Worst Drawdown %',
                          data: overallWorstSeries,
                          tension: 0,
                          pointRadius: 0,
                          borderWidth: 1.5,
                          borderColor: '#444444',
                          backgroundColor: '#444444'
                      }
                  ]
              },
              options: {
                  responsive: true,
                  maintainAspectRatio: false,
                  plugins: {
                      legend: { display: true },
                      tooltip: {
                          mode: 'index',
                          intersect: false,
                          callbacks: {
                              label: ctx => {
                                  const v = ctx.parsed.y;
                                  return `${ctx.dataset.label}: ${v.toFixed(2)}%`;
                              }
                          }
                      }
                  },
                  scales: {
                      x: {
                          title: { display: true, text: 'Time' },
                          ticks: {
                              maxRotation: 0,
                              autoSkip: true,
                              autoSkipPadding: 20
                          }
                      },
                      y: {
                          title: { display: true, text: 'Drawdown (%)' },
                          suggestedMax: 5, // small bit of headroom above 0/positive
                          // we keep negatives visible, no suggestedMin so it can extend below
                      }
                  }
              }
          }
      );
  }



    disconnectedCallback() {
        this.winLossChart?.destroy();
        this.equityChart?.destroy();
        this.splitChart?.destroy();
        this.pairChart?.destroy();
        this.drawdownChart?.destroy(); // ✅ NEW
        this._resizeObs?.disconnect();
    }

    // Handle date changes (auto-triggers @wire because params change)
    handleStartChange(event) {
        const val = event.detail?.value ?? event.target.value;
        this.startDateStr = val;

        // keep range valid (start <= end)
        if (this.endDateStr && this.startDateStr > this.endDateStr) {
            this.endDateStr = this.startDateStr;
        }
    }

    handleEndChange(event) {
        const val = event.detail?.value ?? event.target.value;
        this.endDateStr = val;

        // keep range valid (start <= end)
        if (this.startDateStr && this.startDateStr > this.endDateStr) {
            this.startDateStr = this.endDateStr;
        }
    }
}

// ---- Locker/LWS ResizeObserver shim (keep as you had) ----
(function ensureResizeObserver() {
    const RO = window.ResizeObserver;
    let works = false;
    try {
        works =
            typeof RO === 'function' &&
            (new RO(() => {}), true);
    } catch (e) {
        works = false;
    }
    if (!works) {
        class FakeResizeObserver {
            constructor(cb) {
                this.cb = cb;
                this.targets = new Set();
                this._h = () => {
                    this.targets.forEach(el => {
                        try {
                            const r = el.getBoundingClientRect();
                            this.cb([{ target: el, contentRect: r }]);
                        } catch (_) {}
                    });
                };
            }
            observe(el) {
                this.targets.add(el);
                this._h();
                window.addEventListener('resize', this._h);
            }
            unobserve(el) {
                this.targets.delete(el);
            }
            disconnect() {
                this.targets.clear();
                window.removeEventListener('resize', this._h);
            }
        }
        window.ResizeObserver = FakeResizeObserver;
    }
})();
