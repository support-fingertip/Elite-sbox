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
            type: 'subStockiestNew',
            title: 'Sub Stockiest - New Market Expansion',
            subtitle: 'New area expansion',
            icon: 'standard:channel_program_members'
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

        console.log('Selected Type:', type);

        this.selectedType = type;

    }


    // when clicking back button inside parent
    handleBack() {

        this.selectedType = null;

    }


    // when child form sends back event
    handleChildBack() {

        this.selectedType = null;

    }


    // GETTERS

    get showSelection() {
        return this.selectedType === null;
    }

    get showExistingPrimary() {
        return this.selectedType === 'existingPrimary';
    }

    get showExistingSecondary() {
        return this.selectedType === 'existingSecondary';
    }

    get showNewPrimary() {
        return this.selectedType === 'newPrimary';
    }

    get showSubStockiestNew() {
        return this.selectedType === 'subStockiestNew';
    }

    get showSubStockiestExisting() {
        return this.selectedType === 'subStockiestExisting';
    }

    get showOutletNew() {
        return this.selectedType === 'outletNew';
    }

    get showOutletExisting() {
        return this.selectedType === 'outletExisting';
    }

}