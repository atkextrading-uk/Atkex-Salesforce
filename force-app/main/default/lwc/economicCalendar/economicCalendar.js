import { LightningElement } from 'lwc';

export default class EconomicCalendar extends LightningElement {
    connectedCallback() {
        this.fetchData();
    }

    fetchData() {
        fetch('https://www.forexfactory.com/calendar')
            .then(response => {
                if (!response.ok) {
                    throw new Error('Network response was not ok');
                }
                return response.text();
            })
            .then(html => {
                console.log('HTML content:', html);
                // Process or display the HTML content as needed
            })
            .catch(error => {
                console.error('Error fetching data:', error);
                // Handle errors appropriately
            });
    }
        
    
}