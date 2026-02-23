import { LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

/* NEW IMPORTS FOR DEPENDENT PICKLIST */
import { getObjectInfo, getPicklistValues }
from 'lightning/uiObjectInfoApi';

import VISIT_OBJECT
from '@salesforce/schema/Visit_Form__c';

import STATE_FIELD
from '@salesforce/schema/Visit_Form__c.State__c';

import DISTRICT_FIELD
from '@salesforce/schema/Visit_Form__c.District__c';


export default class OutletExistingMarket extends LightningElement {


    /* =====================================================
       FORM FIELDS
    ===================================================== */

    @track customerType;
    @track visitType;
    @track outletName;
    @track secondaryBusinessType;
    @track primaryCustomer;
    @track productCategory;
    @track primaryBusinessType;
    @track competitorName;
    @track competitorProduct;
    @track competitorRemarks;
    @track generalRemarks;
    @track address;

    @track state = 'Maharashtra';
    @track district;

    @track pinCode;
    @track contactNumber;


    /* =====================================================
       IMAGE FILES
    ===================================================== */

    productImageName;
    outletImageName;
    outletImageUploaded = false;


    /* =====================================================
       PRODUCT GROUP
    ===================================================== */

    @track productGroups = [
        { id: 1, value: '' }
    ];


    /* =====================================================
       OPTIONS (UNCHANGED)
    ===================================================== */

    customerTypeOptions = [
        { label: 'Outlet', value: 'Outlet' }
    ];

    visitTypeOptions = [
        { label: 'Existing Market', value: 'Existing Market' }
    ];

    primaryCustomerOptions = [
        { label: 'Customer 1', value: 'Customer1' },
        { label: 'Customer 2', value: 'Customer2' }
    ];

    categoryOptions = [
        { label: 'Bakery', value: 'Bakery' },
        { label: 'Staple', value: 'Staple' }
    ];

    groupOptions = [
        { label: 'Cookies', value: 'Cookies' },
        { label: 'Cake', value: 'Cake' }
    ];

    businessTypeOptions = [
        { label: 'Retail', value: 'Retail' },
        { label: 'Wholesale', value: 'Wholesale' }
    ];


    /* =====================================================
       STATE & DISTRICT DEPENDENCY VARIABLES
    ===================================================== */

    @track stateOptions = [];

    districtControllerValues;

    districtValues;


    /* =====================================================
       OBJECT INFO
    ===================================================== */

    @wire(getObjectInfo, {
        objectApiName: VISIT_OBJECT
    })
    objectInfo;



    /* =====================================================
       STATE PICKLIST (DYNAMIC)
    ===================================================== */

    @wire(getPicklistValues, {
        recordTypeId: '$objectInfo.data.defaultRecordTypeId',
        fieldApiName: STATE_FIELD
    })
    wiredStatePicklist({ data, error }) {

        if(data) {

            this.stateOptions = data.values;

            console.log('State Options:', this.stateOptions);

        }
        else if(error) {

            console.error('State Picklist Error:', error);

        }

    }



    /* =====================================================
       DISTRICT PICKLIST (DEPENDENT)
    ===================================================== */

    @wire(getPicklistValues, {
        recordTypeId: '$objectInfo.data.defaultRecordTypeId',
        fieldApiName: DISTRICT_FIELD
    })
    wiredDistrictPicklist({ data, error }) {

        if(data) {

            this.districtControllerValues =
                data.controllerValues;

            this.districtValues =
                data.values;

            console.log('District Controller Values:',
                this.districtControllerValues);

            console.log('District Values:',
                this.districtValues);

        }
        else if(error) {

            console.error('District Picklist Error:', error);

        }

    }



    /* =====================================================
       DISTRICT OPTIONS (DEPENDENCY FILTER)
    ===================================================== */

    get districtOptions() {

        if(!this.state || !this.districtValues)
            return [];

        const controllerKey =
            this.districtControllerValues[this.state];

        return this.districtValues.filter(
            district =>
                district.validFor.includes(controllerKey)
        );

    }



    /* =====================================================
       FIELD CHANGE
    ===================================================== */

    handleChange(event) {

        const field = event.target.dataset.field;

        this[field] = event.detail.value;

    }



    /* =====================================================
       STATE CHANGE
    ===================================================== */

    handleStateChange(event) {

        this.state = event.detail.value;

        this.district = null;

    }



    /* =====================================================
       DISTRICT CHANGE
    ===================================================== */

    handleDistrictChange(event) {

        this.district = event.detail.value;

    }



    /* =====================================================
       PRODUCT GROUP CHANGE
    ===================================================== */

    handleGroupChange(event) {

        const index = event.target.dataset.index;

        this.productGroups[index].value =
            event.detail.value;

        this.productGroups = [...this.productGroups];

    }



    /* =====================================================
       ADD PRODUCT GROUP
    ===================================================== */

    handleAddProductGroup() {

        this.productGroups = [

            ...this.productGroups,

            {
                id: Date.now(),
                value: ''
            }

        ];

    }



    /* =====================================================
       PRODUCT IMAGE
    ===================================================== */

    handleProductImage(event) {

        const file = event.target.files[0];

        if (file) {

            this.productImageName = file.name;

        }

    }



    /* =====================================================
       OUTLET IMAGE
    ===================================================== */

    handleOutletImage(event) {

        const file = event.target.files[0];

        if (file) {

            this.outletImageName = file.name;

            this.outletImageUploaded = true;

        }

    }



    /* =====================================================
       BACK
    ===================================================== */

    handleBack() {

        this.dispatchEvent(
            new CustomEvent('back')
        );

    }



    /* =====================================================
       SUBMIT
    ===================================================== */

    handleSubmit() {

        let valid = true;

        this.template.querySelectorAll(
            'lightning-input, lightning-combobox, lightning-textarea'
        )
        .forEach(field => {

            if (field.required && !field.checkValidity()) {

                field.reportValidity();

                valid = false;

            }

        });


        if (!this.outletImageUploaded) {

            this.showToast(
                'Error',
                'Outlet Image is required',
                'error'
            );

            valid = false;

        }


        if (valid) {

            this.showToast(
                'Success',
                'Outlet Existing Market Form Submitted',
                'success'
            );

        }

    }



    /* =====================================================
       TOAST
    ===================================================== */

    showToast(title, message, variant) {

        this.dispatchEvent(

            new ShowToastEvent({

                title,
                message,
                variant

            })

        );

    }

}