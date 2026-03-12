import { LightningElement, track, wire,api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import getAllowedProducts from '@salesforce/apex/VisitFormController.getAllowedProducts';
import saveOutletExistingMarket from '@salesforce/apex/VisitFormController.saveOutletExistingMarket';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import VISIT_FORM_OBJECT from '@salesforce/schema/Visit_Form__c';
import PRODUCT_GROUP_FIELD from '@salesforce/schema/Visit_Form__c.Product_Group__c';
import Secondary_Customer_Business_Type from '@salesforce/schema/Visit_Form__c.Secondary_Customer_Business_Type__c';
import District_FIELD from '@salesforce/schema/Visit_Form__c.District__c';
import State_FIELD from '@salesforce/schema/Visit_Form__c.State__c';
import { getLocationService } from 'lightning/mobileCapabilities';

export default class ExistingSecondaryCustomer extends NavigationMixin(LightningElement) {


    customerType = 'New Outlet';
    visitType = 'Existing Market Expansion';
    @api logId;
    customerTypeOptions = [{ label: 'New Outlet', value: 'New Outlet' }];
    visitTypeOptions = [{ label: 'Existing Market Expansion', value: 'Existing Market Expansion' }];

    primaryCustomer = '';

    outletName = '';
    address ='';
    state = '';
    district ='';
    contactNumber = '';

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
    customerImageUploaded = false;
    competitorImageUploaded = false;

  
    @track secondaryOptions = [];
    @track categoryOptions = [];
    @track filteredGroupOptions = [];

    objectInfo;
    allGroupValues = [];
    controllerValues = {};
    mappedProducts = {};

    showProductGroup = false;
    isPageLoaded = false;
    currentLocationRequestId= '';
    latitude = '';
    longitude = '';
    @track customerBusinessType = '';

    @track businessTypeOptions = [];
    @track stateOptions = [];
    @track districtOptions = [];
    @track filteredDistrictOptions = [];

    stateControllerValues = {};
    allDistrictValues = [];

    
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
            },
            {
                fieldPath: "Customer_Status__c",
                operator: "eq",
                value: "Active"
            }
        ]
    };


    get selectedProductGroups() {
        return this.productGroups?.[0]?.value || [];
    }

    @wire(getObjectInfo, { objectApiName: VISIT_FORM_OBJECT })
    objectInfoHandler({ data, error }) {
        if (data) this.objectInfo = data;
        else if (error) console.error(error);
    }

    businessPicklistHandler({ data, error }) {
        if (data) {
            this.businessTypeOptions = data.values.map(item => ({
                label: item.label,
                value: item.value
            }));
        } else if (error) {
            console.error(error);
        }
    }

    @wire(getPicklistValues, {
        recordTypeId: '$objectInfo.defaultRecordTypeId',
        fieldApiName: State_FIELD
    })
    statePicklistHandler({ data, error }) {
        if (data) {
            this.stateOptions = data.values.map(item => ({
                label: item.label,
                value: item.value
            }));
            this.stateControllerValues = data.controllerValues;
        } else if (error) {
            console.error(error);
        }
    }

    @wire(getPicklistValues, {
        recordTypeId: '$objectInfo.defaultRecordTypeId',
        fieldApiName: District_FIELD
    })
    districtPicklistHandler({ data, error }) {
        if (data) {
            this.allDistrictValues = data.values;
            this.districtControllerValues = data.controllerValues;
        } else if (error) {
            console.error(error);
        }
    }
    isMobilePublisher = window.navigator.userAgent.indexOf('CommunityHybridContainer') > 0;

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.defaultRecordTypeId', fieldApiName: PRODUCT_GROUP_FIELD })
    groupPicklistHandler({ data, error }) {
        if (data) {
            this.allGroupValues = data.values;
            this.controllerValues = data.controllerValues;
            console.log('Picklist Loaded:', this.allGroupValues);
        } else if (error) console.error(error);
    }
    
    @wire(getPicklistValues, {
        recordTypeId: '$objectInfo.defaultRecordTypeId',
        fieldApiName: Secondary_Customer_Business_Type
    })
    businessPicklistHandler({ data, error }) {
        if (data) {
            this.businessTypeOptions = data.values.map(item => ({
                label: item.label,
                value: item.value
            }));
        } else if (error) {
            console.error(error);
        }
    }


    connectedCallback() {
        getAllowedProducts()
        .then(result => {
            this.mappedProducts = result || {};
            this.categoryOptions = Object.keys(this.mappedProducts).map(category => ({ label: category, value: category }));
            console.log('Category Options:', this.categoryOptions);
        })
        .catch(error => console.error(error));
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

    
    handleCustomerImage(event) {
        const file = event.target.files[0];
        if (file) {
            this.customerImageFile = file;
            this.customerImageName = file.name;
            this.customerImageUploaded = true;
        }
    }



    handleChange(event) {
        const field = event.target.dataset.field;
        const value = event.detail.value;

        if (field === 'productCategory') {
            this.productCategory = value;
            this.productGroups = [{ value: [] }];
            this.filteredGroupOptions = [];
            if (!value) return;

            const controllerKey = this.controllerValues[value];
            const allowedGroups = this.mappedProducts[value] || [];

            this.filteredGroupOptions = this.allGroupValues
                .filter(group =>
                    group.validFor.includes(controllerKey) &&
                    (allowedGroups.length === 0 || allowedGroups.includes(group.value))
                )
                .map(group => ({ label: group.label, value: group.value }));
            this.showProductGroup = true;
        } 
        else if (field === 'state') {
            this.state = value;
            this.district = '';
            this.filteredDistrictOptions = [];

            const controllerKey = this.districtControllerValues[value];

            this.filteredDistrictOptions = this.allDistrictValues
                .filter(option => option.validFor.includes(controllerKey))
                .map(option => ({
                    label: option.label,
                    value: option.value
                }));
        }
        else {
            this[field] = value;
        }
     
    }


    handleGroupChange(event) {
        this.productGroups[0].value = event.detail.value;
        this.productGroups = [...this.productGroups];
    }
    handleCustomerSelect(event) {
        this.primaryCustomer = event.detail.recordId;
        console.log('Selected Customer:', this.primaryCustomer);
    }

    

    handleGetLatLon() {
         
        if (!this.outletName) {
            this.showToast('Error', 'Please enter Outlet Name', 'error');
            return;
        }
        if (!this.primaryCustomer) {
            this.showToast('Error', 'Please select Primary Customer', 'error');
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
        if (!this.generalRemarks) {
            this.showToast('Error', 'Please enter general remarks', 'error');
            return;
        }
        if (!this.address) {
            this.showToast('Error', 'Please enter address', 'error');
            return;
        }
        if (!this.state) {
            this.showToast('Error', 'Please select State', 'error');
            return;
        }
        if (!this.district) {
            this.showToast('Error', 'Please select district', 'error');
            return;
        }
        if (!this.pinCode) {
            this.showToast('Error', 'Please enter pinCode', 'error');
            return;
        }
        // Pin Code must be exactly 6 digits
        if (!/^\d{6}$/.test(this.pinCode)) {
            this.showToast('Error', 'Pin Code must be exactly 6 digits', 'error');
            return;
        }

        if (!this.contactNumber) {
            this.showToast('Error', 'Please enter Contact Number', 'error');
            return;
        }

        // Contact Number must be exactly 10 digits
        if (!/^\d{10}$/.test(this.contactNumber)) {
            this.showToast('Error', 'Contact Number must be exactly 10 digits', 'error');
            return;
        }
        if (!this.customerImageUploaded) {
            this.showToast('Error', 'Please upload Outlet image', 'error');
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


        const groupValue = this.productGroups[0].value.join(';');
        saveOutletExistingMarket({
            outletName: this.outletName,
            primaryCustomer: this.primaryCustomer,
            customerBusinessType: this.customerBusinessType,
            address: this.address,
            state: this.state,
            district: this.district,
            pinCode: this.pinCode,
            contactNumber: this.contactNumber,
            productCategory: this.productCategory,
            productGroup : groupValue,
            competitorName : this.competitorName,
            competitorProduct : this.competitorProduct,
            competitorRemarks : this.competitorRemarks,
            generalRemarks :  this.generalRemarks,
            customerImageBase64: customerImageBase64,
            customerImageName: this.customerImageName,
            competitorImageBase64: competitorImageBase64,
            competitorImageName: this.competitorProductImageName,
            latitude: this.latitude,
            longitude: this.longitude,
            logId : this.logId
        })
            .then(recordId => {
                this.showToast('Success', 'New Outlet Visit saved successfully', 'success');
                this.isPageLoaded = false;
                let message = { 
                    message: 'save' ,
                    screen : 3.8
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
            screen : 3.8
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
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

}