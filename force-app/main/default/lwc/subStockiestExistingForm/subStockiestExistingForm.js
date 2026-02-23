import { LightningElement, track, wire } from 'lwc';

import { ShowToastEvent }
from 'lightning/platformShowToastEvent';

import { NavigationMixin }
from 'lightning/navigation';

import { getObjectInfo, getPicklistValues }
from 'lightning/uiObjectInfoApi';

import VISIT_OBJECT
from '@salesforce/schema/Visit_Form__c';

import STATE_FIELD
from '@salesforce/schema/Visit_Form__c.State__c';

import DISTRICT_FIELD
from '@salesforce/schema/Visit_Form__c.District__c';

// NEW IMPORT FOR PRODUCT GROUP DEPENDENCY
import PRODUCT_GROUP_FIELD
from '@salesforce/schema/Visit_Form__c.Product_Group__c';

import getAllowedProducts
from '@salesforce/apex/VisitFormController.getAllowedProducts';

import saveSubStockistExistingMarketVisit
from '@salesforce/apex/VisitFormController.saveSubStockistExistingMarketVisit';

import getPrimaryCustomers
from '@salesforce/apex/VisitFormController.getPrimaryCustomers';



export default class SubStockiestExisting
extends NavigationMixin(LightningElement) {



/* =====================================================
   AUTO POPULATED FIELDS
===================================================== */

@track customerType = 'New Sub Stockiest';

@track visitType = 'Existing Market Expansion';


customerTypeOptions = [
    { label: 'New Sub Stockiest', value: 'New Sub Stockiest' }
];

visitTypeOptions = [
    { label: 'Existing Market Expansion', value: 'Existing Market Expansion' }
];



/* =====================================================
   PRIMARY CUSTOMER SEARCHABLE LOOKUP
===================================================== */

@track primaryCustomerSearch = '';

@track primaryCustomer = '';

@track primaryCustomerName = '';

@track primaryCustomerList = [];

@track filteredPrimaryCustomers = [];

@track showPrimaryCustomerDropdown = false;



/* =====================================================
   FORM FIELDS
===================================================== */

@track subStockistName = '';

@track secondaryBusinessType = '';

@track address = '';

@track state = '';

@track district = '';

@track pinCode = '';

@track contactNumber = '';

@track productCategory = '';

@track competitorName = '';

@track competitorProduct = '';

@track competitorRemarks = '';

@track generalRemarks = '';

outletImageUploaded = false;



/* =====================================================
   PRODUCT GROUP MULTIPICKLIST
===================================================== */

@track productGroups = [
    {
        id: Date.now(),
        value: []
    }
];

@track allowedProductsMap = {};

@track groupOptions = [];



// NEW VARIABLES FOR DEPENDENCY SUPPORT

productGroupControllerValues;

productGroupValues;



/* =====================================================
   BUSINESS TYPE OPTIONS
===================================================== */

businessTypeOptions = [
    { label: 'Retail', value: 'Retail' },
    { label: 'Wholesale', value: 'Wholesale' }
];



/* =====================================================
   STATE & DISTRICT PICKLIST
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
   STATE PICKLIST
===================================================== */

@wire(getPicklistValues, {
    recordTypeId: '$objectInfo.data.defaultRecordTypeId',
    fieldApiName: STATE_FIELD
})
wiredStatePicklist({ data }) {

    if(data) {
        this.stateOptions = data.values;
    }

}



/* =====================================================
   DISTRICT PICKLIST
===================================================== */

@wire(getPicklistValues, {
    recordTypeId: '$objectInfo.data.defaultRecordTypeId',
    fieldApiName: DISTRICT_FIELD
})
wiredDistrictPicklist({ data }) {

    if(data) {

        this.districtControllerValues = data.controllerValues;

        this.districtValues = data.values;

    }

}



/* =====================================================
   PRODUCT GROUP PICKLIST (DEPENDENCY SUPPORT)
===================================================== */

@wire(getPicklistValues, {
    recordTypeId: '$objectInfo.data.defaultRecordTypeId',
    fieldApiName: PRODUCT_GROUP_FIELD
})
wiredProductGroupPicklist({ data, error }) {

    if(data) {

        this.productGroupControllerValues =
            data.controllerValues;

        this.productGroupValues =
            data.values;

        console.log('Product Group Controller:',
            this.productGroupControllerValues);

        console.log('Product Group Values:',
            this.productGroupValues);

    }
    else if(error) {

        console.error('Product Group Picklist Error:',
            error);

    }

}



/* =====================================================
   DISTRICT FILTER
===================================================== */

get districtOptions() {

    if(!this.state || !this.districtValues)
        return [];

    const controllerKey =
        this.districtControllerValues[this.state];

    return this.districtValues.filter(
        district => district.validFor.includes(controllerKey)
    );

}



/* =====================================================
   CATEGORY OPTIONS
===================================================== */

get categoryOptions() {

    return Object.keys(this.allowedProductsMap).map(category => ({
        label: category,
        value: category
    }));

}



/* =====================================================
   INITIAL LOAD
===================================================== */

connectedCallback() {

    getAllowedProducts()
    .then(result => {

        this.allowedProductsMap = result;

        console.log('Allowed Products Map:',
            this.allowedProductsMap);

    })
    .catch(error => {

        this.showToast('Error',
            error?.body?.message,
            'error');

    });



    getPrimaryCustomers()
.then(result => {

    this.primaryCustomerList =
        result.map(acc => ({
            Id: acc.Id,
            Name: acc.Name
        }));

    this.filteredPrimaryCustomers =
        [...this.primaryCustomerList];

    console.log('Primary Customers:',
        this.primaryCustomerList);

})
    .catch(error => {

        this.showToast('Error',
            error?.body?.message,
            'error');

    });

}



/* =====================================================
   PRIMARY CUSTOMER SEARCH
===================================================== */

handlePrimaryCustomerSearch(event)
{
    const value = event.target.value;

    this.primaryCustomerSearch = value;

    if(!value || value.trim().length < 2)
    {
        this.showPrimaryCustomerDropdown = false;
        return;
    }

    const searchKey = value.toLowerCase();

    this.filteredPrimaryCustomers =
        this.primaryCustomerList.filter(customer =>
            customer.Name &&
            customer.Name.toLowerCase().includes(searchKey)
        );

    this.showPrimaryCustomerDropdown =
        this.filteredPrimaryCustomers.length > 0;
}




/* =====================================================
   SELECT PRIMARY CUSTOMER
===================================================== */

selectPrimaryCustomer(event) {

    const customerId =
        event.currentTarget.dataset.id;

    const customerName =
        event.currentTarget.dataset.name;

    this.primaryCustomer = customerId;

    this.primaryCustomerName = customerName;

    this.primaryCustomerSearch = customerName;

    this.showPrimaryCustomerDropdown = false;

}



/* =====================================================
   FIELD CHANGE
===================================================== */

handleChange(event) {

    const field = event.target.dataset.field;

    this[field] = event.detail.value;



    // PRODUCT CATEGORY DEPENDENCY + EMPLOYEE FILTERING

    if(field === 'productCategory') {

        console.log('Selected Category:',
            this.productCategory);

        if(!this.productGroupControllerValues ||
           !this.productGroupValues) {

            console.error('Dependency metadata not loaded');

            return;
        }

        const controllerKey =
            this.productGroupControllerValues[this.productCategory];

        const allowedGroups =
            this.allowedProductsMap[this.productCategory] || [];

        console.log('Controller Key:', controllerKey);

        console.log('Allowed Groups:', allowedGroups);


        if(controllerKey === undefined) {

            this.groupOptions = [];

            return;

        }


        this.groupOptions =
            this.productGroupValues
            .filter(group =>

                group.validFor.includes(controllerKey)

                &&

                (
                    allowedGroups.length === 0

                    ||

                    allowedGroups.includes(group.value)
                )

            )
            .map(group => ({

                label: group.label,

                value: group.value

            }));


        console.log('Final Group Options:',
            this.groupOptions);


        this.productGroups = [{
            id: Date.now(),
            value: []
        }];

    }

}



/* =====================================================
   STATE CHANGE
===================================================== */

handleStateChange(event) {

    this.state = event.detail.value;

    this.district = '';

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

handleProductGroupChange(event) {

    const index =
        event.target.dataset.index;

    this.productGroups[index].value =
        event.detail.value;

    this.productGroups =
        [...this.productGroups];

}



/* =====================================================
   ADD PRODUCT GROUP
===================================================== */

handleAddProductGroup() {

    this.productGroups = [

        ...this.productGroups,

        {
            id: Date.now(),
            value: []
        }

    ];

}



/* =====================================================
   FILE UPLOAD
===================================================== */

handleOutletUpload() {

    this.outletImageUploaded = true;

}



/* =====================================================
   BACK BUTTON
===================================================== */

handleBack() {

    this.dispatchEvent(
        new CustomEvent('back')
    );

}



/* =====================================================
   SAVE
===================================================== */

handleSubmit() {

    let valid = true;


    this.template.querySelectorAll(
        'lightning-input, lightning-combobox, lightning-textarea'
    )
    .forEach(field => {

        if(field.required && !field.value) {

            field.reportValidity();

            valid = false;

        }

    });


    if(!this.primaryCustomer) {

        this.showToast(
            'Error',
            'Please select Primary Customer',
            'error');

        valid = false;

    }


    if(!this.outletImageUploaded) {

        this.showToast(
            'Error',
            'Sub Stockiest Image required',
            'error');

        valid = false;

    }


    const allSelectedGroups =
        this.productGroups.flatMap(group => group.value);


    if(allSelectedGroups.length === 0) {

        this.showToast(
            'Error',
            'Please select Product Group',
            'error');

        valid = false;

    }


    if(!valid) return;


    const productGroupString =
        allSelectedGroups.join(';');


    saveSubStockistExistingMarketVisit({

        subStockistName: this.subStockistName,

        businessType: this.secondaryBusinessType,

        address: this.address,

        state: this.state,

        district: this.district,

        pinCode: this.pinCode,

        contactNumber: this.contactNumber,

        productCategory: this.productCategory,

        productGroup: productGroupString,

        competitorName: this.competitorName,

        competitorProduct: this.competitorProduct,

        competitorRemarks: this.competitorRemarks,

        generalRemarks: this.generalRemarks

    })


    .then(recordId => {

        this.showToast(
            'Success',
            'Visit Created Successfully',
            'success');

        this[NavigationMixin.Navigate]({

            type: 'standard__recordPage',

            attributes: {

                recordId: recordId,

                objectApiName: 'Visit_Form__c',

                actionName: 'view'

            }

        });

    })


    .catch(error => {

        this.showToast(
            'Error',
            error?.body?.message,
            'error');

    });

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