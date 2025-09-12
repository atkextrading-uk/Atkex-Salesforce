import { LightningElement, api, track } from 'lwc';
import getOandaUrls from '@salesforce/apex/OandaTradeService.getOandaTradeImageUrls';

export default class OandaTradeImageDisplay extends LightningElement {

    @api recordId;

    openUrl;
    closeUrl;
    secondScreenshot;
    
    connectedCallback() {
        console.log('test')
        getOandaUrls({recordId: this.recordId})
            .then(result => {
                console.log('RESULT' + JSON.stringify(result));
                this.openUrl = result.Open_URL__c
                this.closeUrl = result.Close_URL__c
                this.secondScreenshot = result.Second_Screenshot__c
                console.log(result);
            })
            .catch(error => {
                console.log(error);
            });
    }
}