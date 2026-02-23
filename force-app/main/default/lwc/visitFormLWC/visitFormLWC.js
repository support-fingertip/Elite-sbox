import { LightningElement, track } from 'lwc';

export default class VisitFormLWC extends LightningElement {

    @track selectedType = null;

    newCustomerList = [

        {
            type: 'newPrimary',
            title: 'New Primary Customer',
            subtitle: 'Create visit form for new primary customer',
            icon: 'standard:account'
        },

        {
            type: 'subStockiestExisting',
            title: 'Sub Stockiest - Existing Market Expansion',
            subtitle: 'Existing market expansion',
            icon: 'standard:channel_program_levels'
        },

        {
            type: 'outletNew',
            title: 'Outlet - New Market Expansion',
            subtitle: 'New area expansion',
            icon: 'standard:store'
        },

        {
            type: 'outletExisting',
            title: 'Outlet - Existing Market Expansion',
            subtitle: 'Existing market expansion',
            icon: 'standard:store'
        }

    ];


    // when clicking list item
    handleSelect(event) {
        const type = event.currentTarget.dataset.type;
        this.selectedType = type;
        let message = { 
            message: 'visitFormScreen' ,
            visittype :type,
            screen : 3.8
        };
        this.genericDispatchEvent(message);
    }


    // when clicking back button inside parent
    handleBack() {
        this.selectedType = null;
    }


    // when child form sends back event
    handleChildBack() {
        this.selectedType = null;
    }

    genericDispatchEvent(message) {
        // Creating a custom event with a payload (optional)
        const event = new CustomEvent('visitform', {
            detail: message
        });

        // Dispatching the event
        this.dispatchEvent(event);
    }

 

}