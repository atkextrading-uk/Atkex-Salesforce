import { LightningElement, track } from 'lwc';
import getCal from '@salesforce/apex/economicCalendarController.getCal';
import getCal2 from '@salesforce/apex/economicCalendarController.getCal2';

const columns = [
    { label: 'Date', fieldName: 'date' },
    { label: 'Time', fieldName: 'time', type: 'string' },
    { label: 'Currency', fieldName: 'currency', type: 'string' },
    { label: 'Event', fieldName: 'event', type: 'string' },
    { label: 'Actual', fieldName: 'actual', type: 'string' },
    { label: 'Forecast', fieldName: 'forecast', type: 'string' },
    { label: 'Previous', fieldName: 'previous', type: 'string' },
];

export default class EconomicCalendarWidget extends LightningElement {

    currentCalendar = 'forex';
    result = {};
    imageUrl;
    data;

    tableData = [];
    columns = columns;

    @track comboBoxCalendarValue;
    comboBoxCalendarOptions = [
        { label: 'Forex', value: 'forex' },
        { label: 'Crypto', value: 'crypto' }
    ];

    comboBoxCalendarHandleChange(event) {
        this.comboBoxCalendarValue = event.target.value;
        console.log(this.comboBoxCalendarValue);

        
    }

    connectedCallback() {
        //this.getResponse();
    }

    getResponse2() {

    }

    getResponse() {
        getCal({}).then((response) => {
            console.log('response called');
                var d = response;
                const parser = new DOMParser();
                const htmlDocument = parser.parseFromString(d, 'text/html');
                const calendarDivTable = htmlDocument.querySelector('.calendar__table');
                console.log(calendarDivTable);
                this.data = calendarDivTable;
                var calendarDivRows = calendarDivTable.getElementsByClassName('calendar__row calendar_row calendar__row--grey');
                
                var index = 0;

                Array.from(calendarDivRows).forEach((ele) => {
                    console.log(ele);
                    var row = this.getRow(ele);

                    this.tableData = [...this.tableData, row];
                    index++;
                });
            });
    }

    getRow(forexTableRow) {
        var row = {
            date: 'd',
            time: forexTableRow.getElementsByClassName('calendar__cell calendar__time time')[0].innerHTML,
            currency: forexTableRow.getElementsByClassName('calendar__cell calendar__currency currency ')[0].innerHTML,
            event: forexTableRow.getElementsByClassName('calendar__cell calendar__event event')[0]
                .getElementsByClassName('calendar__event-title')[0].innerHTML,
            actual: this.getActual(forexTableRow.getElementsByClassName('calendar__cell calendar__actual actual')[0]),
            forecast: forexTableRow.getElementsByClassName('calendar__cell calendar__forecast forecast')[0].innerHTML,
            previous: this.getPrevious(forexTableRow.getElementsByClassName('calendar__cell calendar__previous previous')[0])
        };
        return row;
    }

    getActual(actual) {
        if (actual.getElementsByClassName('worse')[0] != null) {
            return actual.getElementsByClassName('worse')[0].innerHTML;
        } else if (actual.getElementsByClassName('better')[0] != null) {
            return actual.getElementsByClassName('better')[0].innerHTML;
        } else if (actual.innerHTML != null) {
            return actual.innerHTML;
        } else {
            return 'NA';
        }
    }

    getPrevious(previous) {
        console.log(previous);
        if (previous.getElementsByClassName('revised worse')[0] != null) {
            return previous.getElementsByClassName('revised worse')[0].innerHTML;
        } else if (previous.getElementsByClassName('revised better')[0] != null) {
            return previous.getElementsByClassName('revised better')[0].innerHTML;
        } else if (previous.innerHTML != null) {
            return previous.innerHTML;
        } else {
            return 'NA';
        }
    }

    
}