import { LightningElement, track, api, wire } from 'lwc';
import createAccount from '@salesforce/apex/TradingAccountController.createAccount';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import NAME_FIELD from '@salesforce/schema/Trading_Account__c.Name';

export default class ProvisioningProfileForm extends LightningElement {
  @track isSubmitting = false;
  @api recordId; // Trading_Account__c Id (optional pass-through)

  // ===== Form state (Trading Account fields) =====
  server = '';                 // e.g. "FivePercentOnline-Real"
  platform = 'mt5';            // "mt4" | "mt5"
  type = 'cloud-g2';           // MetaApi cloud type
  baseCurrency = 'USD';        // "USD" | "EUR" | ...
  provisioningProfileId = '';  // the profile you created previously
  login = '';                  // trading login (string)
  password = '';               // trading password (string)
  copyFactoryRoles = [];       // e.g. ["PROVIDER"] or []

  // auto-populated from record
  sfAccountName = '';

  // ----- auto-load Name via LDS -----
  @wire(getRecord, { recordId: '$recordId', fields: [NAME_FIELD] })
  wiredTa({ data, error }) {
    if (data) {
      this.sfAccountName = getFieldValue(data, NAME_FIELD) || '';
    } else if (error) {
      // Non-fatal: just log & keep blank
      // eslint-disable-next-line no-console
      console.error('getRecord(Name) error', JSON.stringify(error));
      this.sfAccountName = '';
    }
  }

  // ===== Picklists =====
  get platformOptions() {
    return [
      { label: 'MT4', value: 'mt4' },
      { label: 'MT5', value: 'mt5' }
    ];
  }
  get typeOptions() {
    return [
      { label: 'cloud-g2', value: 'cloud-g2'//,
        //label: 'cloud-g1', value: 'cloud-g1' 
       }
      // add other cloud types if you use them
    ];
  }
  get currencyOptions() {
    return [
      { label: 'USD', value: 'USD' },
      { label: 'EUR', value: 'EUR' },
      { label: 'GBP', value: 'GBP' }
    ];
  }
  get copyFactoryRoleOptions() {
    return [
      { label: 'PROVIDER', value: 'PROVIDER' },
      { label: 'SUBSCRIBER', value: 'SUBSCRIBER' }
    ];
  }

  // ===== Handlers =====
  handleInput(event) {
    const id = event.target.dataset.id;
    let val = event.target.value;

    // Dual listbox returns array; others return string
    if (id === 'copyFactoryRoles') {
      this.copyFactoryRoles = Array.isArray(val) ? val : (val ? [val] : []);
      return;
    }
    this[id] = val;
  }

  async handleSubmit() {
    this.isSubmitting = true;

    // ---- Client-side null checks (defensive) ----
    if (!this.server || !this.platform || !this.type || !this.baseCurrency ||
        !this.provisioningProfileId || !this.login || !this.password) {
      this.isSubmitting = false;
      this.dispatchEvent(new ShowToastEvent({
        title: 'Missing required fields',
        message: 'Please complete Server, Platform, Type, Base Currency, Provisioning Profile, Login and Password.',
        variant: 'error'
      }));
      return;
    }

    try {
      const payload = {
        server: this.server,
        platform: this.platform,
        type: this.type,
        baseCurrency: this.baseCurrency,
        provisioningProfileId: this.provisioningProfileId,
        login: String(this.login),
        password: this.password,
        copyFactoryRoles: this.copyFactoryRoles || [],
        sfTradingAccountId: this.recordId, // optional
        sfAccountName: this.sfAccountName || null 
      };

      // Helpful local debug
      // console.log('Submitting account payload:', JSON.stringify(payload));

      const result = await createAccount({ reqJson: JSON.stringify(payload) });

      // Try to surface the new id if present
      let id;
      try { id = JSON.parse(result?.body || '{}')?.id; } catch (e) { /* noop */ }

      if (result?.status !== 200 && result?.status !== 201) {
        this.dispatchEvent(new ShowToastEvent({
          title: 'Trading account not created',
          message: `Status: ${result?.status} (${result?.statusText || 'N/A'})`,
          variant: 'error'
        }));
      } else {
        this.dispatchEvent(new ShowToastEvent({
          title: 'Trading account created',
          message: id ? `ID: ${id}` : (result?.statusText || 'Success'),
          variant: 'success'
        }));
      }

      this.handleCancel();
    } catch (e) {
      this.dispatchEvent(new ShowToastEvent({
        title: 'Error',
        message: e?.body?.message || e?.message || 'Unknown error',
        variant: 'error'
      }));
    } finally {
      this.isSubmitting = false;
    }
  }

  handleCancel() {
    this.dispatchEvent(new CustomEvent('close'));
  }
}
