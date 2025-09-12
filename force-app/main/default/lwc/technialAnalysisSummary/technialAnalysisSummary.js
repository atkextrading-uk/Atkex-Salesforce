import { LightningElement, api, wire, track } from 'lwc';
import getAllTechnicalAnalysisTrades from '@salesforce/apex/TechnicalAnalysisTradesDataController.getAllTechnicalAnalysisTrades';

export default class TechnicalAnalysisSummary extends LightningElement {
    totalProfit;
    numberOpen;
    @track trades;
    @track data;

    TechnicalAnalysisSummary() {
        
    }

    @wire(getAllTechnicalAnalysisTrades, {})
    wireData(result) {
        this.trades = result;
        if (result.data) {
            this.data = JSON.parse(JSON.stringify(result.data));
            this.numberOpen = 0;
            let profit = 0;
            this.data.forEach(ele => {//loop all trades
                if (ele.Stage__c == 'O') {
                    this.numberOpen = this.numberOpen + 1;
                }
                if (ele.Profit__c !== undefined) {
                    profit = profit + ele.Profit__c;
                }
            });

            console.log('proft' + this.profit);
            var totalP = profit.toFixed(2);
            this.totalProfit = totalP;
        } else if (result.error) {
            console.log(result.error);
            this.data = undefined;
        }
    };

    // connectedCallback() {
    //     //allTrades = DivergenceTradesDataController.getAllDivergenceTrades();

    //     this.trades.forEach(trade => {
    //         this.totalProfit = this.totalProfit + trade.Profit__c;
    //     });
    //     console.log(this.totalProfit);
    // }

}