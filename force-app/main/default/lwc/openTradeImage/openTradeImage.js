import { LightningElement, api, wire } from 'lwc';
import getCurrentTradeURLS from '@salesforce/apex/CurrentTradeController.getCurrentTradeURLS';

export default class OpenTradeImage extends LightningElement {
    //https://www.tradingview.com/x/vOH7Mlf9/
    @api openUrl = '';
    @api closeUrl = '';

    @api recordId;

    // constructor() {
    //     // var trade = getCurrentTradeURLS(this.recordId);

    //     // var openUrl = trade.Open_Screenshot__c;
    //     // console.log(openUrl);
    //     // var closeUrl = trade.Close_Screenshot__c;
    //     // console.log(closeUrl);
    //     // super();
    // }

    @wire(getCurrentTradeURLS, { id : '$recordId'})
    wireData(result) {
        this.data = result;
        if (result.data) {
            this.data = JSON.parse(JSON.stringify(result.data));
            this.openUrl = this.data.Open_Screenshot__c;
            this.closeUrl = this.data.Close_Screenshot__c;
        } else if (result.error) {
            console.log(result.error);
            this.data = undefined;
        }
    };

    // getOpenSS() {
    //     console.log('yesy');
    //     var trade = getCurrentTradeURLS(this.recordId);
    //     this.openUrl = trade.Open_Screenshot__c;
    //     console.log(this.openUrl);
    //     return trade.Open_Screenshot__c;
    // }

    // getCloseSS() {
    //     var trade = getCurrentTradeURLS(this.recordId);
    //     this.closeUrl = trade.Close_Screenshot__c;
    //     console.log(this.closeUrl);
    //     return trade.Close_Screenshot__c;
    // }

}