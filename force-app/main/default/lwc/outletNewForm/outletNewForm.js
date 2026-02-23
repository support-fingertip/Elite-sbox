import { LightningElement, track, wire } from 'lwc';

import { ShowToastEvent }
from 'lightning/platformShowToastEvent';


/* OBJECT + PICKLIST DEPENDENCY */
import { getObjectInfo, getPicklistValues }
from 'lightning/uiObjectInfoApi';

import VISIT_OBJECT
from '@salesforce/schema/Visit_Form__c';

import STATE_FIELD
from '@salesforce/schema/Visit_Form__c.State__c';

import DISTRICT_FIELD
from '@salesforce/schema/Visit_Form__c.District__c';

import PRODUCT_GROUP_FIELD
from '@salesforce/schema/Visit_Form__c.Product_Group__c';


/* APEX METHODS */
import getVisitFieldValues
from '@salesforce/apex/VisitFormController.getVisitFieldValues';

import getAllowedProducts
from '@salesforce/apex/VisitFormController.getAllowedProducts';

import saveOutletNewMarket
from '@salesforce/apex/VisitFormController.saveOutletNewMarket';



export default class OutletNewMarket extends LightningElement {



/* =====================================================
   AUTO POPULATED FIELDS FROM BACKEND
===================================================== */

@track customerType;

@track visitType;

@track primaryBusinessType;



/* =====================================================
   FORM FIELDS
===================================================== */

@track outletName = '';

@track secondaryBusinessType = '';

@track productCategory = '';

@track address = '';

@track state = '';

@track district = '';

@track pinCode = '';

@track contactNumber = '';

@track competitorName = '';

@track competitorProduct = '';

@track competitorRemarks = '';

@track generalRemarks = '';



/* =====================================================
   PRODUCT GROUP SUPPORT (CHECKBOX MULTIPICKLIST)
===================================================== */

@track productGroups =
[
    {
        id: Date.now(),
        value: []
    }
];

@track groupOptions = [];

@track categoryOptions = [];

@track allowedProductsMap = {};

productGroupControllerValues;

productGroupValues;



/* =====================================================
   IMAGE SUPPORT
===================================================== */

productImageName;

outletImageName;

outletImageUploaded = false;



/* =====================================================
   BUSINESS TYPE OPTIONS
===================================================== */

businessTypeOptions =
[
    { label: 'Retail', value: 'Retail' },
    { label: 'Wholesale', value: 'Wholesale' }
];



/* =====================================================
   STATE DISTRICT DEPENDENCY VARIABLES
===================================================== */

@track stateOptions = [];

districtControllerValues;

districtValues;



/* =====================================================
   INITIAL LOAD
===================================================== */

connectedCallback()
{

    /* GET CUSTOMER TYPE & VISIT TYPE FROM BACKEND */

    getVisitFieldValues({

        uiSelection:
            'Outlet – New Market Expansion',

        primaryCustomerId:
            null

    })
    .then(result =>
    {

        this.customerType =
            result.CustomerType;

        this.visitType =
            result.VisitType;

        this.primaryBusinessType =
            result.BusinessType;

    })
    .catch(error =>
    {

        this.showToast(
            'Error',
            error?.body?.message,
            'error'
        );

    });



    /* GET EMPLOYEE ALLOWED PRODUCTS */

    getAllowedProducts()

    .then(result =>
    {

        this.allowedProductsMap =
            result;


        this.categoryOptions =
            Object.keys(result)
            .map(category =>
            ({
                label: category,
                value: category
            }));

    })

    .catch(error =>
    {

        this.showToast(
            'Error',
            error?.body?.message,
            'error'
        );

    });

}



/* =====================================================
   OBJECT INFO
===================================================== */

@wire(getObjectInfo,
{
    objectApiName: VISIT_OBJECT
})
objectInfo;



/* =====================================================
   STATE PICKLIST
===================================================== */

@wire(getPicklistValues,
{
    recordTypeId:
        '$objectInfo.data.defaultRecordTypeId',

    fieldApiName:
        STATE_FIELD
})
wiredStatePicklist({ data })
{

    if(data)
    {
        this.stateOptions =
            data.values;
    }

}



/* =====================================================
   DISTRICT PICKLIST
===================================================== */

@wire(getPicklistValues,
{
    recordTypeId:
        '$objectInfo.data.defaultRecordTypeId',

    fieldApiName:
        DISTRICT_FIELD
})
wiredDistrictPicklist({ data })
{

    if(data)
    {

        this.districtControllerValues =
            data.controllerValues;

        this.districtValues =
            data.values;

    }

}



/* =====================================================
   PRODUCT GROUP PICKLIST (DEPENDENCY)
===================================================== */

@wire(getPicklistValues,
{
    recordTypeId:
        '$objectInfo.data.defaultRecordTypeId',

    fieldApiName:
        PRODUCT_GROUP_FIELD
})
wiredProductGroupPicklist({ data })
{

    if(data)
    {

        this.productGroupControllerValues =
            data.controllerValues;

        this.productGroupValues =
            data.values;

    }

}



/* =====================================================
   DISTRICT FILTER
===================================================== */

get districtOptions()
{

    if(!this.state ||
       !this.districtValues)
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

handleChange(event)
{

    const field =
        event.target.dataset.field;

    this[field] =
        event.detail.value;



    /* CATEGORY → PRODUCT GROUP DEPENDENCY */

    if(field === 'productCategory')
    {

        if(!this.productGroupControllerValues ||
           !this.productGroupValues)
            return;


        const controllerKey =
            this.productGroupControllerValues[
                this.productCategory
            ];


        const allowedGroups =
            this.allowedProductsMap[
                this.productCategory
            ] || [];


        this.groupOptions =
            this.productGroupValues

            .filter(group =>

                group.validFor.includes(controllerKey)

                &&

                allowedGroups.includes(group.value)

            )

            .map(group =>
            ({
                label: group.label,
                value: group.value
            }));


        /* RESET PRODUCT GROUP */

        this.productGroups =
        [
            {
                id: Date.now(),
                value: []
            }
        ];

    }

}



/* =====================================================
   STATE CHANGE
===================================================== */

handleStateChange(event)
{

    this.state =
        event.detail.value;

    this.district = '';

}



/* =====================================================
   DISTRICT CHANGE
===================================================== */

handleDistrictChange(event)
{

    this.district =
        event.detail.value;

}



/* =====================================================
   PRODUCT GROUP CHANGE
===================================================== */

handleProductGroupChange(event)
{

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

handleAddProductGroup()
{

    this.productGroups =
    [
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

handleProductImage(event)
{

    const file =
        event.target.files[0];

    if(file)
    {
        this.productImageName =
            file.name;
    }

}



handleOutletImage(event)
{

    const file =
        event.target.files[0];

    if(file)
    {

        this.outletImageName =
            file.name;

        this.outletImageUploaded =
            true;

    }

}



/* =====================================================
   BACK BUTTON
===================================================== */

handleBack()
{

    this.dispatchEvent(
        new CustomEvent('back')
    );

}



/* =====================================================
   SAVE
===================================================== */

handleSubmit()
{

    let valid = true;



    /* Validate standard fields */

    this.template.querySelectorAll(
        'lightning-input, lightning-combobox, lightning-textarea'
    )
    .forEach(field =>
    {

        if(field.required && !field.value)
        {

            field.reportValidity();

            valid = false;

        }

    });



    /* Validate product group */

    const selectedGroups =
        this.productGroups.flatMap(group => group.value);

    if(selectedGroups.length === 0)
    {

        this.showToast(
            'Error',
            'Please select at least one Product Group',
            'error'
        );

        valid = false;

    }



    /* Validate image */

    if(!this.outletImageUploaded)
    {

        this.showToast(
            'Error',
            'Outlet Image required',
            'error'
        );

        valid = false;

    }



    if(!valid)
        return;



    const productGroupString =
        selectedGroups.join(';');



    saveOutletNewMarket({

        outletName:
            this.outletName,

        productCategory:
            this.productCategory,

        productGroup:
            productGroupString,

        competitorName:
            this.competitorName,

        competitorProduct:
            this.competitorProduct,

        competitorRemarks:
            this.competitorRemarks,

        generalRemarks:
            this.generalRemarks

    })

    .then(recordId =>
    {

        this.showToast(
            'Success',
            'Visit Created Successfully',
            'success'
        );

    })

    .catch(error =>
    {

        this.showToast(
            'Error',
            error?.body?.message,
            'error'
        );

    });

}



/* =====================================================
   TOAST
===================================================== */

showToast(title, message, variant)
{

    this.dispatchEvent(
        new ShowToastEvent(
        {
            title,
            message,
            variant
        })
    );

}

}