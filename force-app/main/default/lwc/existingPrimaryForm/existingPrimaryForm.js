import { LightningElement, track, wire, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import getAllowedProducts from '@salesforce/apex/VisitFormController.getAllowedProducts';
import savePrimaryVisit from '@salesforce/apex/VisitFormController.savePrimaryVisit';
import { getLocationService } from 'lightning/mobileCapabilities';

// =============================
// NEW IMPORTS FOR DEPENDENCY
// =============================
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import VISIT_FORM_OBJECT from '@salesforce/schema/Visit_Form__c';
import PRODUCT_GROUP_FIELD from '@salesforce/schema/Visit_Form__c.Product_Group__c';

export default class ExistingPrimaryForm extends NavigationMixin(LightningElement) {

    _defaultPrimaryCustomerId;
    lastPrimaryPrefillId = '';

    @api
    get defaultPrimaryCustomerId() {
        return this._defaultPrimaryCustomerId;
    }
    set defaultPrimaryCustomerId(value) {
        this._defaultPrimaryCustomerId = value;
        this.applyDefaultPrimaryCustomer();
    }
    @api logId;

    @api returnScreen = 3.8;
    @api visitId;

    // =====================================================
    // FORM VARIABLES
    // =====================================================
    @track primaryCustomer;
    @track productCategory;
    @track competitorName;
    @track competitorProduct;
    @track competitorRemarks;
    @track generalRemarks;

    @track primaryCustomerImageName = '';
    @track competitorProductImageName = '';

    competitorProductImageFile;
    primaryCustomerImageFile;
    primaryCustomerImageUploaded = false;
    competitorImageUploaded = false;
    showProductGroup = false;
    isPageLoaded = false;
    currentLocationRequestId= '';
    latitude = '';
    longitude = '';


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

    connectedCallback() {
        this.applyDefaultPrimaryCustomer();
    }

    applyDefaultPrimaryCustomer() {
        if (!this.defaultPrimaryCustomerId) {
            return;
        }
        if (this.lastPrimaryPrefillId === this.defaultPrimaryCustomerId) {
            return;
        }
        this.lastPrimaryPrefillId = this.defaultPrimaryCustomerId;
        this.primaryCustomer = this.defaultPrimaryCustomerId;
    }
    // =====================================================
    // DROPDOWN OPTIONS
    // =====================================================
    @track categoryOptions = [];
    @track groupOptions = [];

    // =====================================================
    // PRODUCT GROUP LIST
    // =====================================================
    @track productGroups = [{ value: [] }];

    // =====================================================
    // STORE APEX PRODUCT MAP (EXISTING LOGIC KEPT)
    // =====================================================
    mappedProducts = {};

    // =====================================================
    // DEPENDENCY SUPPORT VARIABLES
    // =====================================================
    objectInfo;
    allGroupValues = [];
    controllerValues = {};

    // =====================================================
    // GETTER FOR CHECKBOX GROUP VALUE
    // =====================================================
    get selectedProductGroups() {
        return this.productGroups?.[0]?.value || [];
    }


    // =====================================================
    // LOAD CATEGORY FROM APEX (FILTERED BY USER CATEGORY)
    // =====================================================
    @wire(getAllowedProducts)
    wiredProducts({ data, error }) {
        if (data) {
            console.log('PRODUCT MAP FROM APEX:', data);
            this.mappedProducts = data;
            this.categoryOptions = Object.keys(data || {}).map(category => ({
                label: category,
                value: category
            }));
            console.log('CATEGORY OPTIONS:', this.categoryOptions);
        } else if (error) {
            console.error('Product Mapping Error:', error);
        }
    }

    // =====================================================
    // GET OBJECT INFO
    // =====================================================
    @wire(getObjectInfo, { objectApiName: VISIT_FORM_OBJECT })
    objectInfoHandler({ data, error }) {
        if (data) {
            this.objectInfo = data;
        } else if (error) {
            console.error('Object Info Error:', error);
        }
    }

    // =====================================================
    // GET PRODUCT GROUP PICKLIST VALUES
    // =====================================================
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
            console.error('Picklist Error:', error);
        }
    }

    // =====================================================
    // HANDLE FIELD CHANGE
    // =====================================================
    handleChange(event) {
        const field = event.target.dataset.field;
        const value = event.detail.value;
        this[field] = value;

        // HANDLE PRODUCT CATEGORY CHANGE
        if (field === 'productCategory') {
            console.log('Selected Category:', value);

            if (!this.mappedProducts) {
                console.error('Product mapping not loaded yet');
                this.groupOptions = [];
                this.productGroups = [{ value: [] }];
                return;
            }

            const controllerKey = this.controllerValues[value];
            const allowedGroups = this.mappedProducts[value] || [];
            console.log('Allowed Groups from Apex:', allowedGroups);

            if (controllerKey === undefined) {
                this.groupOptions = [];
            } else {
                this.groupOptions = this.allGroupValues
                    .filter(groupEntry =>
                        groupEntry.validFor.includes(controllerKey) &&
                        (allowedGroups.length === 0 ||
                         allowedGroups.includes(groupEntry.value))
                    )
                    .map(groupEntry => ({
                        label: groupEntry.label,
                        value: groupEntry.value
                    }));
            }

            console.log('Final Filtered Groups:', this.groupOptions);
            this.productGroups = [{ value: [] }];
            this.showProductGroup = true;
        }
      
    }

    // =====================================================
    // HANDLE GROUP CHANGE
    // =====================================================
    handleGroupChange(event) {
        this.productGroups[0].value = event.detail.value;
        this.productGroups = [...this.productGroups];
        console.log('Selected Groups:', this.productGroups);
    }

    // =====================================================
    // HANDLE COMPETITOR PRODUCT IMAGE
    // =====================================================
    handleCompetitorProductImage(event) {
        const file = event.target.files[0];
        if (file) {
            this.competitorProductImageFile = file;
            this.competitorProductImageName = file.name;
            this.competitorImageUploaded = true;
            console.log('Competitor Product Image Selected:', file.name);
        }
    }

    // =====================================================
    // HANDLE PRIMARY CUSTOMER IMAGE
    // =====================================================
    handlePrimaryCustomerImage(event) {
        const file = event.target.files[0];
        if (file) {
            this.primaryCustomerImageFile = file;
            this.primaryCustomerImageName = file.name;
            this.primaryCustomerImageUploaded = true;
            console.log('Primary Customer Image Selected:', file.name);
        }
    }

    // =====================================================
    // SAVE VISIT FORM
    // =====================================================
    handleGetLatLon() {
         
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
        if (!this.primaryCustomerImageUploaded) {
            this.showToast('Error', 'Please upload primary customer image', 'error');
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
       
        this.isPageLoaded = true;

        try {
            let primaryImageBase64 = null;
            let competitorImageBase64 = null;

            if (this.primaryCustomerImageFile) {
                primaryImageBase64 =
                    await this.compressImage(this.primaryCustomerImageFile);
            }

            if (this.competitorProductImageFile) {
                competitorImageBase64 =
                    await this.compressImage(this.competitorProductImageFile);
            }

            const groupValue = this.productGroups
                .flatMap(pg => pg.value)
                .join(';');

            const recordId = await savePrimaryVisit({
                primaryCustomerId: this.primaryCustomer,
                productCategory: this.productCategory,
                productGroup: groupValue,
                competitorName: this.competitorName,
                competitorProduct: this.competitorProduct,
                competitorRemarks: this.competitorRemarks,
                generalRemarks: this.generalRemarks,
                primaryImageBase64: primaryImageBase64,
                primaryImageName: this.primaryCustomerImageName,
                competitorImageBase64: competitorImageBase64,
                competitorImageName: this.competitorProductImageName,
                latitude: this.latitude,
                longitude: this.longitude,
                visitId: this.visitId,
                logId : this.logId
            });

            this.showToast('Success', 'Primary Visit saved successfully', 'success');
            this.isPageLoaded = false;
            let message = { 
                message: 'save' ,
                screen : this.returnScreen,
                visitId: this.visitId,
                visittype: 'existingPrimary'
            };
            this.genericDispatchEvent(message);
            

        } catch (error) {
            console.error(error);
            this.showToast('Error', error.body?.message || 'Error saving', 'error');
        }
    }

    //=====================================================
    //Handle Cancel 
    //=====================================================
    handleBack()
    {
        let message = { 
            message: 'cancel' ,
            screen : this.returnScreen,
            visittype: 'existingPrimary'
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



    // =====================================================
    // SHOW TOAST
    // =====================================================
    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({ title, message, variant })
        );
    }

    
    genericDispatchEvent(message) {
        // Creating a custom event with a payload (optional)
        const event = new CustomEvent('back', {
            detail: message
        });

        // Dispatching the event
        this.dispatchEvent(event);
    }


    // =====================================================
    // HANDLE CUSTOMER SELECT
    // =====================================================
    handleCustomerSelect(event) {
        this.primaryCustomer = event.detail.recordId;
        console.log('Selected Customer:', this.primaryCustomer);
    }
}