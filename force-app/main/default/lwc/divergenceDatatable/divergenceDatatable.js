import { LightningElement, track, wire } from 'lwc';
import getAllTrades from '@salesforce/apex/DivergenceTradesDataController.getAllDivergenceTradesOpen';
import { updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
 
const columns = [
    { label: 'Name', fieldName: 'Name', editable: true },
    { label: 'Stage', fieldName: 'Stage__c', editable: true },
    { label: 'Symbol', fieldName: 'Symbol__c', editable: true },
    { label: 'Profit', fieldName: 'Profit__c', editable: true },
    { label: 'Close Date', fieldName: 'Close_Date_Time__c', editable: true },
    { label: 'Open Price', fieldName: 'Open_Price__c', editable: true },
    { label: 'SL Price', fieldName: 'Stop_Loss_Price__c', editable: true },
    { label: 'TP Price', fieldName: 'Take_Profit_Price__c', editable: true },
    // {
    //     label: 'Account Name',
    //     fieldName: 'AccountId',
    //     type: 'lookupColumn',
    //     typeAttributes: {
    //         object: 'Contact',
    //         fieldName: 'AccountId',
    //         value: { fieldName: 'AccountId' },
    //         context: { fieldName: 'Id' },
    //         name: 'Account',
    //         fields: ['Account.Name'],
    //         target: '_self'
    //     },
    //     editable: false,
    // }
]
 
export default class DivergenceDatatable extends LightningElement {
    columns = columns;
    showSpinner = false;
    @track data = [];
    @track tradeData;
    @track draftValues = [];
    lastSavedData = [];
 
    //here I pass picklist option so that this wire method call after above method
    @wire(getAllTrades, {})
    wireData(result) {
        this.tradeData = result;
        if (result.data) {
            this.data = JSON.parse(JSON.stringify(result.data));
            console.log(this.data);
            // this.data.forEach(ele => {
            //     ele.accountLink = ele.AccountId != undefined ? '/' + ele.AccountId : '';
            //     ele.accountName = ele.AccountId != undefined ? ele.Account.Name : '';
            // })
 
            this.lastSavedData = JSON.parse(JSON.stringify(this.data));
 
        } else if (result.error) {
            console.log(result.error);
            this.data = undefined;
        }
    };
 
    updateDataValues(updateItem) {
        let copyData = JSON.parse(JSON.stringify(this.data));
 
        copyData.forEach(item => {
            if (item.Id === updateItem.Id) {
                for (let field in updateItem) {
                    item[field] = updateItem[field];
                }
            }
        });
 
        //write changes back to original data
        this.data = [...copyData];
    }
 
    updateDraftValues(updateItem) {
        let draftValueChanged = false;
        let copyDraftValues = [...this.draftValues];
        //store changed value to do operations
        //on save. This will enable inline editing &
        //show standard cancel & save button
        copyDraftValues.forEach(item => {
            if (item.Id === updateItem.Id) {
                for (let field in updateItem) {
                    item[field] = updateItem[field];
                }
                draftValueChanged = true;
            }
        });
 
        if (draftValueChanged) {
            this.draftValues = [...copyDraftValues];
        } else {
            this.draftValues = [...copyDraftValues, updateItem];
        }
    }
 
    //listener handler to get the context and data
    //updates datatable
    lookupChanged(event) {
        console.log(event.detail.data);
        event.stopPropagation();
        let dataRecieved = event.detail.data;
        let accountIdVal = dataRecieved.value != undefined ? dataRecieved.value : null;
        let updatedItem = { Id: dataRecieved.context, AccountId: accountIdVal  };
        console.log(updatedItem);
        this.updateDraftValues(updatedItem);
        this.updateDataValues(updatedItem);
    }
 
    //handler to handle cell changes & update values in draft values
    handleCellChange(event) {
        this.updateDraftValues(event.detail.draftValues[0]);
    }
 
    handleSave(event) {
        this.showSpinner = true;
        this.saveDraftValues = this.draftValues;
 
        const recordInputs = this.saveDraftValues.slice().map(draft => {
            const fields = Object.assign({}, draft);
            return { fields };
        });
 
        // Updateing the records using the UiRecordAPi
        const promises = recordInputs.map(recordInput => updateRecord(recordInput));
        Promise.all(promises).then(res => {
            this.showToast('Success', 'Records Updated Successfully!', 'success', 'dismissable');
            this.draftValues = [];
            return this.refresh();
        }).catch(error => {
            console.log(error);
            this.showToast('Error', 'An Error Occured!!', 'error', 'dismissable');
        }).finally(() => {
            this.draftValues = [];
            this.showSpinner = false;
        });
        this.refresh();
    }
 
    handleCancel(event) {
        //remove draftValues & revert data changes
        this.data = JSON.parse(JSON.stringify(this.lastSavedData));
        this.draftValues = [];
    }
 
    showToast(title, message, variant, mode) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: mode
        });
        this.dispatchEvent(evt);
    }
 
    // This function is used to refresh the table once data updated
    async refresh() {
        await refreshApex(this.tradeData);
    }
}