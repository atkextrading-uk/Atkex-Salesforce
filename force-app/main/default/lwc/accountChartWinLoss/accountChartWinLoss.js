import { LightningElement } from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';
import CHARTJS from '@salesforce/resourceUrl/chartjs';

export default class AccountChartWinLoss extends LightningElement {
  chart;
  chartLoaded = false;

  // Sample data — tweak as you like
  labels = ['Win', 'Break-even', 'Loss'];
  values = [72, 8, 20];

  renderedCallback() {
    if (this.chartLoaded) return;
    this.chartLoaded = true;

    // If you uploaded a single file: CHARTJS
    // If you uploaded a zip containing chart.umd.min.js: CHARTJS + '/chart.umd.min.js'
    loadScript(this, CHARTJS)
      .then(() => this.renderChart())
      .catch(() => {
        // Optional: surface a toast
        console.error('Failed to load Chart.js');
      });
  }

  renderChart() {
    if (!window.Chart) return;

    const canvas = this.template.querySelector('canvas.chart');
    if (!canvas) return;

    if (this.chart) {
      this.chart.destroy();
    }

    this.chart = new window.Chart(canvas.getContext('2d'), {
      type: 'doughnut',
      data: {
        labels: this.labels,
        datasets: [
          {
            data: this.values,
            // Don't set colors if you're using LWS strict rules; Chart.js will pick defaults.
            // You can add custom colors here if desired.
            borderWidth: 1
          }
        ]
      },
      options: {
        responsive: true,
        cutout: '60%',
        plugins: {
          legend: { position: 'bottom' },
          tooltip: { mode: 'nearest', intersect: false }
        }
      }
    });
  }
}
