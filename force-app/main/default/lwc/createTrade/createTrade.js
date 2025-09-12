import { LightningElement, api } from 'lwc';
import NAME_FIELD from '@salesforce/schema/Trade__c.Name';
import Trade__c from '@salesforce/schema/Trade__c';

export default class CreateTrade extends LightningElement {

    fields = [NAME_FIELD];

    // Flexipage provides recordId and objectApiName
    @api recordId;
    @api objectApiName;
}