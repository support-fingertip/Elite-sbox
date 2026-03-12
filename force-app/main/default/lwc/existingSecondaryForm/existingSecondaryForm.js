import { LightningElement, track, wire, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import getAllowedProducts from '@salesforce/apex/VisitFormController.getAllowedProducts';
import saveSecondaryVisit from '@salesforce/apex/VisitFormController.saveSecondaryVisit';
import getPrimaryCustomers from '@salesforce/apex/VisitFormController.getPrimaryCustomers';
import getSecondaryCustomerAutoFill from '@salesforce/apex/VisitFormController.getSecondaryCustomerAutoFill';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import VISIT_FORM_OBJECT from '@salesforce/schema/Visit_Form__c';
import PRODUCT_GROUP_FIELD from '@salesforce/schema/Visit_Form__c.Product_Group__c';

import { getLocationService } from 'lightning/mobileCapabilities';

export default class ExistingSecondaryCustomer extends NavigationMixin(LightningElement) {
    lastPrefillKey = '';
    @api defaultPrimaryCustomerId;
    @api defaultSecondaryCustomerId;
    @api defaultCustomerName;

    @api returnScreen = 3.8;
    @api visitId;

    @track secondaryCustomer;
    @track productCategory;

    @track productGroups = [{ value: [] }];

    @track competitorName;
    @track competitorProduct;
    @track competitorRemarks;
    @track generalRemarks;

    competitorProductImageName;
    customerImageName;
    competitorProductImageFile;
    customerImageFile;
    secondaryCustomerImageUploaded = false;
    competitorImageUploaded = false;

    @track primaryOptions = [];
    @track secondaryOptions = [];
    @track categoryOptions = [];
    @track groupOptions = [];

    objectInfo;
    allGroupValues = [];
    controllerValues = {};
    mappedProducts = {};

    showProductGroup = false;
    isPageLoaded = false;
    currentLocationRequestId= '';
    latitude = '';
    longitude = '';
    @api logId;


    displayInfo = {
        primaryField: "Name",
        additionalFields: ["SAP_Customer_Code__c"]
    };
    matchingInfo = {
        primaryField: { fieldPath: "Name", mode: "contains" },
        additionalFields: [
            { fieldPath: "SAP_Customer_Code__c", mode: "contains" }
        ]
    };
    accountFilter = {
        criteria: [
            {
                fieldPath: "Customer_Type__c",
                operator: "eq",
                value: "Primary Customer"
            }
        ]
    };

    isMobilePublisher = window.navigator.userAgent.indexOf('CommunityHybridContainer') > 0;
    @track prefilledSecondaryCustomerId = '';
    @track prefilledSecondaryCustomerName = '';

    get selectedProductGroups() {
        return this.productGroups?.[0]?.value || [];
    }

    @wire(getObjectInfo, { objectApiName: VISIT_FORM_OBJECT })
    objectInfoHandler({ data, error }) {
        if (data) {
            this.objectInfo = data;
        } else if (error) {
            console.error('Object Info Error:', error);
        }
    }

    @track secondaryFilter = { recordIds: [] };

    @wire(getPicklistValues, {
        recordTypeId: '$objectInfo.defaultRecordTypeId',
        fieldApiName: PRODUCT_GROUP_FIELD
    })
    groupPicklistHandler({ data, error }) {
        if (data) {
            this.allGroupValues = data.values;
            this.controllerValues = data.controllerValues;
            console.log('ALL GROUP VALUES:', this.allGroupValues);
            console.log('CONTROLLER VALUES:', this.controllerValues);
        } else if (error) {
            console.error('Product Group Picklist Error:', error);
        }
    }

    connectedCallback() {
        if(!this.defaultSecondaryCustomerId)
        {
             this.secondaryCustomer = this.defaultSecondaryCustomerId;
        }
       

        
        console.log('this.defaultPrimaryCustomerId'+this.defaultPrimaryCustomerId);
        getAllowedProducts()
            .then(result => {
                console.log('PRODUCT MAP FROM APEX:', result);
                this.mappedProducts = result;
                this.categoryOptions = Object.keys(result || {}).map(category => ({
                    label: category,
                    value: category
                }));
            })
            .catch(error => {
                console.error('Product Dependency Load Error:', error);
            });

    }


    handlePrimaryCustomerSelect(event) {
        this.defaultPrimaryCustomerId = event.detail.recordId;
    }
    handleSecondarySelect(event) {
        this.secondaryCustomer = event.detail?.Id;
    }

    handleChange(event) {
        const field = event.target.dataset.field;
        const value = event.detail.value;

        if (field === 'productCategory') {
            this.productCategory = value;
            console.log('Selected Category:', value);

            this.productGroups = [{ value: [] }];
            this.groupOptions = [];
            if (!value) return;

            const controllerKey = this.controllerValues[value];
            const allowedGroups = this.mappedProducts[value] || [];
            console.log('Allowed Groups:', allowedGroups);

            if (controllerKey === undefined) {
                this.groupOptions = [];
            } else {
                this.groupOptions = this.allGroupValues
                    .filter(group =>
                        group.validFor.includes(controllerKey) &&
                        (allowedGroups.length === 0 || allowedGroups.includes(group.value))
                    )
                    .map(group => ({
                        label: group.label,
                        value: group.value
                    }));
            }
            this.showProductGroup = true;
        } else {
            this[field] = value;
        }
      
    }

    handleGroupChange(event) {
        this.productGroups[0].value = event.detail.value;
        this.productGroups = [...this.productGroups];
        console.log('Selected Groups:', this.productGroups);
    }

    handleCompetitorProductImage(event) {
        const file = event.target.files[0];
        if (file) {
            this.competitorProductImageFile = file;
            this.competitorProductImageName = file.name;
            this.competitorImageUploaded = true;
            console.log('Competitor Product Image Selected:', file.name);
        }
    }
    

    handleSecondaryCustomerImage(event) {
        const file = event.target.files[0];
        if (file) {
            this.customerImageFile = file;
            this.customerImageName = file.name;
            this.secondaryCustomerImageUploaded = true;
        }
    }



    handleGetLatLon() {
         
        if (!this.defaultPrimaryCustomerId) {
            this.showToast('Error', 'Please select Primary Customer', 'error');
            return;
        }
        if (!this.defaultSecondaryCustomerId && !this.secondaryCustomer) {
            this.showToast('Error', 'Please select Secondary Customer', 'error');
            return;
        }
        if (!this.productCategory) {
            this.showToast('Error', 'Please select Product Category', 'error');
            return;
        }
        if (!this.selectedProductGroups || this.selectedProductGroups.length == 0 ) {
            this.showToast('Error', 'Please select Product Groups', 'error');
            return;
        }
        if (!this.competitorName) {
            this.showToast('Error', 'Please enter competitor Name', 'error');
            return;
        }
        if (!this.competitorProduct) {
            this.showToast('Error', 'Please select competitor Product', 'error');
            return;
        }
        if (!this.competitorRemarks) {
            this.showToast('Error', 'Please select competitor remarks', 'error');
            return;
        }
        if (!this.generalRemarks) {
            this.showToast('Error', 'Please select general remarks', 'error');
            return;
        }
        if (!this.competitorImageUploaded) {
            this.showToast('Error', 'Please upload Competitor Product Image', 'error');
            return;
        }
        if (!this.secondaryCustomerImageUploaded) {
            this.showToast('Error', 'Please upload secondary customer image', 'error');
            return;
        }

        this.isPageLoaded = true;
        let isResolved = false;
        this.currentLocationRequestId = null;

        const requestId = Math.random().toString(36).substring(2);
        this.currentLocationRequestId = requestId;
    
        // Timeout fallback (applies to both mobile and browser)
        const timeoutTimer = setTimeout(() => {
            if (!isResolved) {
                this.isPageLoaded = false;
                this.currentLocationRequestId = null;
                this.showToast('Error', 'Please enable location permission', 'error');
                return;
            }
        }, 30000);
    
        if (this.isMobilePublisher) {
            // Mobile Publisher: use Nimbus Location Service
            getLocationService().getCurrentPosition({
                enableHighAccuracy: true
            }).then((result) => {
                // Only process if this is the latest request
                if (this.currentLocationRequestId !== requestId || isResolved) return;
                isResolved = true;
                clearTimeout(timeoutTimer);
                this.currentLocationRequestId = null;
    
                const newEvent = new CustomEvent('locationPharmacySearch:getLatLonResponse', { detail: {} });
                newEvent.detail.lat = result.coords.latitude;
                newEvent.detail.lon = result.coords.longitude;
                newEvent.detail.latlonsource = 'nimbus';
                newEvent.detail.status = 'success';
    
                console.log('newEvent: ' + JSON.stringify(newEvent));
                this.latitude = r.coords.latitude;
                this.longitude = r.coords.longitude;

                this.handleSubmit(); 
    
            }).catch((error) => {
                // Only process if this is the latest request
                if (this.currentLocationRequestId !== requestId || isResolved) return;
                isResolved = true;
                clearTimeout(timeoutTimer);
                this.currentLocationRequestId = null; // Clear the request ID
                console.error('Mobile location error:', error);
                this.isPageLoaded = false;
                this.showToast('Error', 'Unable to fetch location. Please ensure location is enabled.', 'error');
            });
    
        } else if (window.navigator && window.navigator.geolocation) {
            // Browser: use native geolocation
            window.navigator.geolocation.getCurrentPosition(
                (r) => {
                    // Only process if this is the latest request
                    if (this.currentLocationRequestId !== requestId || isResolved) return;
                    isResolved = true;
                    clearTimeout(timeoutTimer);
                    this.currentLocationRequestId = null; // Clear the request ID
    
                    const newEvent = new CustomEvent('locationPharmacySearch:getLatLonResponse', { detail: {} });
                    newEvent.detail.lat = r.coords.latitude;
                    newEvent.detail.lon = r.coords.longitude;
                    newEvent.detail.latlonsource = 'browser';
                    newEvent.detail.status = 'success';
    
                    this.latitude = r.coords.latitude;
                    this.longitude = r.coords.longitude;

                    this.handleSubmit(); 
                },
                (err) => {
                    // Only process if this is the latest request
                    if (this.currentLocationRequestId !== requestId || isResolved) return;
                    isResolved = true;
                    clearTimeout(timeoutTimer);
                    this.currentLocationRequestId = null;
                    console.error('Browser location error:', err);
                    this.isPageLoaded = false;
                    this.showToast('Error', 'Please enable location permission to start your day', 'error');
                },
                { enableHighAccuracy: true }
            );
    
        } else {
            isResolved = true;
            clearTimeout(timeoutTimer);
            this.currentLocationRequestId = null; // Clear the request ID
            console.log('Location not supported');
            this.isPageLoaded = false;
            this.showToast('Error', 'Location not supported on this device.', 'error');
        }
    }

    async handleSubmit() {

        let customerImageBase64 = null;
        let competitorImageBase64 = null;

        if (this.customerImageFile) {
            customerImageBase64 =
                await this.compressImage(this.customerImageFile);
        }

        if (this.competitorProductImageFile) {
            competitorImageBase64 =
                await this.compressImage(this.competitorProductImageFile);
        }

        const groupValue = this.productGroups.flatMap(pg => pg.value).join(';');

        saveSecondaryVisit({
            primaryCustomerId: this.defaultPrimaryCustomerId,
            secondaryCustomerId: this.defaultSecondaryCustomerId || this.secondaryCustomer,
            productCategory: this.productCategory,
            productGroup: groupValue,
            competitorName: this.competitorName,
            competitorProduct: this.competitorProduct,
            competitorRemarks: this.competitorRemarks,
            generalRemarks: this.generalRemarks,
            customerImageBase64: customerImageBase64,
            customerImageName: this.customerImageName,
            competitorImageBase64: competitorImageBase64,
            competitorImageName: this.competitorProductImageName,
            latitude: this.latitude,
            longitude: this.longitude,
            visitId: this.visitId,
            logId : this.logId
        })
            .then(recordId => {
                this.showToast('Success', 'Secondary Customer Visit saved successfully', 'success');
                this.isPageLoaded = false;
                let message = { 
                    message: 'save' ,
                    screen : this.returnScreen,
                    visitId: this.visitId,
                    visittype: 'existingSecondary'
                };
                this.genericDispatchEvent(message);
            })
            .catch(error => {
                console.error(error);
                this.showToast(
                    'Error',
                    error?.body?.message || 'Unknown error',
                    'error'
                );
            });
    }

    //=====================================================
    //Handle Cancel 
    //=====================================================
    handleBack()
    {
        let message = { 
            message: 'cancel' ,
            screen : this.returnScreen,
            visittype: 'existingSecondary'
        };
        this.genericDispatchEvent(message);
    }

    //=====================================================
    // Compress Image 
    //====================================================
    async compressImage(file, maxWidth = 800, quality = 0.7) {
        return new Promise((resolve, reject) => {
            const reader = new FileReader();

            reader.onload = event => {
                const img = new Image();
                img.src = event.target.result;

                img.onload = () => {
                    const canvas = document.createElement('canvas');
                    const scale = maxWidth / img.width;
                    const width = maxWidth;
                    const height = img.height * scale;

                    canvas.width = width;
                    canvas.height = height;

                    const ctx = canvas.getContext('2d');
                    ctx.drawImage(img, 0, 0, width, height);

                    const compressedBase64 = canvas.toDataURL('image/jpeg', quality)
                        .split(',')[1]; // remove prefix

                    resolve(compressedBase64);
                };

                img.onerror = error => reject(error);
            };

            reader.readAsDataURL(file);
        });
    }

    genericDispatchEvent(message) {
        // Creating a custom event with a payload (optional)
        const event = new CustomEvent('back', {
            detail: message
        });

        // Dispatching the event
        this.dispatchEvent(event);
    }


    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({ title, message, variant })
        );
    }
}