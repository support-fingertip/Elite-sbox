import { LightningElement, track, wire } from 'lwc';

import getPrimaryCustomers from '@salesforce/apex/VisitFormController.getPrimaryCustomers';
import saveVisitForm from '@salesforce/apex/VisitFormController.saveVisitForm';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class ExistingPrimaryForm extends LightningElement {

    @track primaryCustomer;
    @track productCategory;
    @track competitorName;
    @track competitorProduct;
    @track competitorRemarks;
    @track generalRemarks;

    @track customerOptions = [];

    @track productGroups = [
        { id: 1, number: 1, value: '' }
    ];


    // Product Category Options
    categoryOptions = [
        { label: 'Bakery', value: 'Bakery' },
        { label: 'Staple', value: 'Staple' },
        { label: 'Beverages', value: 'Beverages' }
    ];


    // Product Group Options
    groupOptions = [
        { label: 'Cookies', value: 'Cookies' },
        { label: 'Traded Products', value: 'Traded Products' },
        { label: 'Cake', value: 'Cake' },
        { label: 'Millet', value: 'Millet' },
        { label: 'Milled Wheat Products', value: 'Milled Wheat Products' },
        { label: 'Bread', value: 'Bread' },
        { label: 'Bun', value: 'Bun' },
        { label: 'Mix', value: 'Mix' }
    ];


    // Load Primary Customers from Apex
    @wire(getPrimaryCustomers)
    wiredCustomers({ error, data }) {

        if (data) {

            const unique = new Map();

            data.forEach(account => {

                unique.set(account.Id, {
                    label: account.Name,
                    value: account.Id
                });

            });

            this.customerOptions = Array.from(unique.values());

        }
        else if (error) {

            console.error('Error loading customers:', error);

        }

    }


    // Handlers

    handlePrimaryChange(event) {

        this.primaryCustomer = event.detail.value;

    }


    handleCategoryChange(event) {

        this.productCategory = event.detail.value;

    }


    handleGroupChange(event) {

        const index = event.target.dataset.index;

        this.productGroups[index].value = event.detail.value;

        this.productGroups = [...this.productGroups];

    }


    handleAddGroup() {

        const newIndex = this.productGroups.length + 1;

        this.productGroups = [
            ...this.productGroups,
            { id: newIndex, number: newIndex, value: '' }
        ];

    }


    handleCompetitorName(event) {

        this.competitorName = event.detail.value;

    }


    handleCompetitorProduct(event) {

        this.competitorProduct = event.detail.value;

    }


    handleCompetitorRemarks(event) {

        this.competitorRemarks = event.detail.value;

    }


    handleGeneralRemarks(event) {

        this.generalRemarks = event.detail.value;

    }


    handleBack() {

        this.dispatchEvent(new CustomEvent('back'));

    }


    handleSubmit() {

        if (!this.primaryCustomer) {

            this.showToast(
                'Error',
                'Please select Primary Customer',
                'error'
            );

            return;

        }


        saveVisitForm({

            primaryCustomerId: this.primaryCustomer,

            productCategory: this.productCategory,

            productGroup: this.productGroups[0].value,

            competitorName: this.competitorName,

            competitorProduct: this.competitorProduct,

            competitorRemarks: this.competitorRemarks,

            generalRemarks: this.generalRemarks

        })
        .then(result => {

            this.showToast(
                'Success',
                'Visit Form Created Successfully',
                'success'
            );

            console.log('Created Visit Id:', result);

        })
        .catch(error => {

            this.showToast(
                'Error',
                error.body.message,
                'error'
            );

            console.error(error);

        });

    }


    showToast(title, message, variant) {

        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant
            })
        );

    }

}