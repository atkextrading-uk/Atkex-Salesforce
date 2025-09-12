import { LightningElement } from 'lwc';

import { loadScript } from 'lightning/platformResourceLoader';
import lightweightcharts from '@salesforce/resourceUrl/lightweightcharts';
// import {createChart} from '@salesforce/resourceUrl/lightweightcharts/lightweight-charts-master/src/api/create-charts.ts';

import { createChart } from '@salesforce/resourceUrl/lightweightcharts';

// ...

// somewhere in your code

export default class ChartDisplayTradingView extends LightningElement {

    chartInitialized = false;

    renderedCallback() {
        console.log('renderedCallback')

        if (this.chartInitialized) {
            return;
        }
        this.chartInitialized = true;

        /*loadScript(this, lightweightcharts + '/dist/lightweight-charts.standalone.production.js')
            .then(() => {
                console.log('LightweightCharts library loaded');

                this.initializeChart();
            })
            .catch(error => {
                console.error('Error loading lightweight-charts', error);
            });*/
    }

    initializeChart() {
        console.log('init chart')
        const chartContainer = this.template.querySelector('[data-name="chartContainer"]')
        if (chartContainer) {
            console.log('chartContainer')
            const chart = window.LightweightCharts.createChart(chartContainer);

            /*const lineSeries = chart.addLineSeries();
            lineSeries.setData([
                { time: '2019-04-11', value: 80.01 },
                { time: '2019-04-12', value: 96.63 },
                { time: '2019-04-13', value: 76.64 },
                { time: '2019-04-14', value: 81.89 },
                { time: '2019-04-15', value: 74.43 },
            ]);*/
        }
    }
}