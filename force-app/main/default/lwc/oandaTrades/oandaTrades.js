import { LightningElement, track } from 'lwc';
import fetchPage from '@salesforce/apex/OandaTradeController.fetchPage';
import getFieldOptions from '@salesforce/apex/OandaTradeController.getFieldOptions';

const ROW_ACTIONS = [{ label: 'View Screenshots', name: 'viewShots' }];

const TYPE_MAP = {
    text: 'text',
    string: 'text',
    number: 'number',
    currency: 'currency',
    percent: 'percent',
    datetime: 'date',
    url: 'url',
    lookup: 'text'
};

function formatDateInput(d) {
    const yr = d.getFullYear();
    const mo = String(d.getMonth() + 1).padStart(2, '0');
    const da = String(d.getDate()).padStart(2, '0');
    return `${yr}-${mo}-${da}`;
}

export default class OandaTrades extends LightningElement {
    // visible page
    @track rows = [];
    @track columns = [];

    // full dataset (for client-side paging/sorting)
    allRows = [];

    // pagination state
    pageSizeOptions = [
        { label: '25', value: '25' },
        { label: '50', value: '50' },
        { label: '100', value: '100' }
    ];
    pageSize = '25';
    pageNumber = 1;
    totalPages = 0;
    totalRecords = 0;
    showSpinner = true;

    // sorting (client-side)
    sortField = 'Close_Date_Time__c';
    sortDirection = 'desc';

    // field picker
    @track fieldOptions = [];
    @track selectedFields = [
        'Name__c','Side__c','Currency__r.Name',
        'Open_Date_Time__c','Close_Date_Time__c',
        'Profit_Loss__c','Profit_Percentage__c',
        'Open_URL__c','Close_URL__c'
    ];
    showFieldPicker = false;

    // screenshot modal
    showShots = false;
    currentOpenUrl = null;
    currentCloseUrl = null;

    // date filters
    startDate;
    endDate;

    connectedCallback() {
        const today = new Date();
        const lastYear = new Date(today);
        lastYear.setFullYear(today.getFullYear() - 1);

        this.startDate = formatDateInput(lastYear);
        this.endDate = formatDateInput(today);

        this.loadFieldOptions();
        this.loadAll();
    }

    // ---- Data load (fetch all, no ordering/offset in Apex) ----
    async loadFieldOptions() {
        try {
            const opts = await getFieldOptions();
            if (opts && Array.isArray(opts)) {
                this.fieldOptions = opts
                    .filter(o => !!o && !!o.apiName)
                    .map(o => ({ label: o.label || o.apiName, value: o.apiName, type: o.type || 'text' }));
            }
        } catch (e) {
            // eslint-disable-next-line no-console
            console.error('getFieldOptions error', e);
        }
    }

    async loadAll() {
        this.showSpinner = true;

        const req = {
            // page data ignored by Apex now; we paginate in the LWC
            pageNumber: 1,
            pageSize: 999999, // ignored
            fieldApiNames: this.selectedFields,
            // sort ignored in Apex (we sort client-side)
            sortField: null,
            sortDir: null,
            startDate: this.startDate || null,
            endDate: this.endDate || null
        };

        try {
            const res = await fetchPage({ req });
            if (res && !res.error) {
                this.allRows = Array.isArray(res.records) ? res.records : [];
                this.totalRecords = this.allRows.length;
                this.totalPages = Math.max(1, Math.ceil(this.totalRecords / (parseInt(this.pageSize, 10) || 25)));
                this.pageNumber = Math.min(this.pageNumber, this.totalPages);

                this.buildColumns();
                this.applyClientSort();   // respect current sort
                this.applyClientPage();   // slice to current page
            } else {
                this.allRows = [];
                this.rows = [];
                this.totalPages = 0;
                this.totalRecords = 0;
                // eslint-disable-next-line no-console
                console.error(res ? res.error : 'Unknown error');
            }
        } catch (e) {
            this.allRows = [];
            this.rows = [];
            this.totalPages = 0;
            this.totalRecords = 0;
            // eslint-disable-next-line no-console
            console.error('fetchPage error', e);
        } finally {
            this.showSpinner = false;
        }
    }

    // ---- Client-side pagination/sorting ----
    applyClientPage() {
        const size = parseInt(this.pageSize, 10) || 25;
        const start = (this.pageNumber - 1) * size;
        const end = start + size;
        this.rows = this.allRows.slice(start, end);
    }

    applyClientSort() {
        const field = this.sortField;
        if (!field) return;

        const dir = (this.sortDirection || 'asc').toLowerCase() === 'asc' ? 1 : -1;

        const val = (row) => {
            const v = row ? row[field] : null;
            return v === undefined ? null : v;
        };

        this.allRows = [...this.allRows].sort((a, b) => {
            const av = val(a);
            const bv = val(b);

            // nulls last
            if (av == null && bv == null) return 0;
            if (av == null) return 1;
            if (bv == null) return -1;

            // date-ish?
            if (a && b && (field.endsWith('__c') || field.includes('.'))) {
                // try Date parse when values look like datetimes
                const ad = Date.parse(av);
                const bd = Date.parse(bv);
                if (!Number.isNaN(ad) && !Number.isNaN(bd)) {
                    return (ad - bd) * dir;
                }
            }

            // numeric?
            const an = typeof av === 'number' ? av : Number(av);
            const bn = typeof bv === 'number' ? bv : Number(bv);
            const aNum = !Number.isNaN(an);
            const bNum = !Number.isNaN(bn);
            if (aNum && bNum) return (an - bn) * dir;

            // string compare fallback
            const as = String(av).toLowerCase();
            const bs = String(bv).toLowerCase();
            if (as < bs) return -1 * dir;
            if (as > bs) return 1 * dir;
            return 0;
        });
    }

    // ---- Columns ----
    buildColumns() {
        if (!this.selectedFields || this.selectedFields.length === 0) {
            this.columns = [];
            return;
        }

        const meta = {};
        for (const opt of this.fieldOptions) {
            if (opt && opt.value) {
                meta[opt.value] = { label: opt.label || opt.value, type: opt.type || 'text' };
            }
        }

        const cols = [];
        for (const api of this.selectedFields) {
            if (!api) continue;
            const info = meta[api] || { label: api, type: 'text' };
            const dtType = TYPE_MAP[info.type] || 'text';
            const c = { fieldName: api, label: info.label, type: dtType, sortable: true };

            if (dtType === 'url') {
                c.typeAttributes = { label: { fieldName: api }, target: '_blank' };
            }
            if (dtType === 'date') {
                c.typeAttributes = { year: 'numeric', month: '2-digit', day: '2-digit', hour: '2-digit', minute: '2-digit', second: '2-digit' };
            }
            cols.push(c);
        }

        cols.push({
            type: 'action',
            typeAttributes: { rowActions: ROW_ACTIONS, menuAlignment: 'auto' }
        });

        this.columns = cols;
    }

    // ---- UI handlers ----
    handlePageSizeChange(e) {
        this.pageSize = e.detail.value || '25';
        this.pageNumber = 1;
        this.totalPages = Math.max(1, Math.ceil(this.totalRecords / (parseInt(this.pageSize, 10) || 25)));
        this.applyClientPage();
    }

    nextPage() {
        if (this.pageNumber < this.totalPages) {
            this.pageNumber += 1;
            this.applyClientPage();
        }
    }

    prevPage() {
        if (this.pageNumber > 1) {
            this.pageNumber -= 1;
            this.applyClientPage();
        }
    }

    get isFirstPage() { return this.pageNumber <= 1; }
    get isLastPage() { return this.totalPages === 0 || this.pageNumber >= this.totalPages; }

    handleSort(event) {
        const { fieldName, sortDirection } = event.detail || {};
        if (fieldName) this.sortField = fieldName;
        if (sortDirection) this.sortDirection = sortDirection;
        this.applyClientSort();
        this.pageNumber = 1;
        this.applyClientPage();
    }

    openFieldPicker() { this.showFieldPicker = true; }
    closeFieldPicker() { this.showFieldPicker = false; }
    handleFieldsChange(e) { this.selectedFields = e.detail.value || []; }
    applyFieldPicker() {
        this.showFieldPicker = false;
        this.pageNumber = 1;
        this.buildColumns();
        this.applyClientSort();
        this.applyClientPage();
        // optional: refetch to ensure selected fields exist in dataset (kept simple here)
    }

    handleDateChange(e) {
        const { name, value } = e.target || {};
        if (name === 'startDate') this.startDate = value || null;
        if (name === 'endDate') this.endDate = value || null;
    }
    applyFilters() {
        this.pageNumber = 1;
        this.loadAll();
    }

    handleRowAction(event) {
        const action = event.detail.action ? event.detail.action.name : null;
        const row = event.detail.row || {};
        if (action === 'viewShots') {
            this.currentOpenUrl = row.Open_URL__c || null;
            this.currentCloseUrl = row.Close_URL__c || null;
            this.showShots = true;
        }
    }

    closeShots() {
        this.showShots = false;
        this.currentOpenUrl = null;
        this.currentCloseUrl = null;
    }
}
