import { LightningElement,api,track,wire } from 'lwc';
import getApexData from '@salesforce/apex/beatPlannerlwc.getCollectionsData';
import PLANNER_ICON from '@salesforce/resourceUrl/planner';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import FORM_FACTOR from '@salesforce/client/formFactor';
import saveCollection from '@salesforce/apex/beatPlannerlwc.saveCollections'; 
import Id from '@salesforce/user/Id';
import GOOGLE_ICONS from '@salesforce/resourceUrl/googleIcons';

export default class Collections extends LightningElement {

    ice = PLANNER_ICON + "/planner/screen-4-ice.png";
    userId = Id;
    @api recordId;
    @api index;
    @api acccountId; 
    @api logId;
    @api visitData;
    @api objType;
    @track productValue = 0;
    @track productData = [];
    @track getSelectedProduct = [];
    productCatDropdown = [];
    orderSummery = [];
    originalSelectedProduct = [];
    proCatVal = 'All';
    salesCat = 'All';
    orderData = [];
    getStoreIndex = [];
    formattedSalesData = [];
    isProductAdded = false;
    isDropdownOrderOpen = true; 
    totalTaxAmt = 0; grandTotal = 0; totalQnt = 0;
    isAllOrder = true;  isCategorySelected = false; isSpecialOffer = false;
    searchPro = '';
    customOrderButton;
    OrderDate; 
    subTotalAmt = 0;
    grandTotalAmt = 0; 
    Discount = 0;
   
    isDesktop = false;
    isPhone = false;
    @track collection = {
        Total_Received_Amount__c:'',
        Mode_of_Payment__c:'',
        UTR_Number__c:'',
        Remarks__c:'',
        Customer__c:this.acccountId,
        Visit__c:this.recordId,
        UniqueFileId__c:'',
        Visit_For__c:''
    }
    @track  collectionItems = [
        {
            sObjectType: 'Collection_Item__c',
            Collection__c:null,
            index:1,
            Id: null,
            Amount_Received__c	:null,
            Mode_of_Payment__c:'',
            UTR_Number__c: null,
            Remarks__c :'',
            Invoice_Number__c:'',
            Invoice_Date__c:'',
            Outstanding_Amount__c:'',
            isrequired:false,
            isUTRNumberRequired:false,
            isAdwanceAmount:false,
            customClass :this.isDesktop ?'slds-size_1-of-5 inputcustompadding' : 'slds-size_1-of-2 inputcustompadding'
        },
    ];
    @track  summarycollectionItems = [];
    modeOfPaymentOptions = [];
    collectioncustomClass = 'slds-size_1-of-3 inputcustompadding';
    collectionRemarkscustomClass = 'slds-size_1-of-3 inputcustompadding';
    customClass = 'slds-size_1-of-5 inputcustompadding';
    buttoncustomClass = 'slds-size_1-of-5 inputcustompadding';
    adwanceAmountClass = 'slds-size_1-of-4 inputcustompadding'
    showAllProducts = true;
    isSummaryProduct = false;
    isPageLoaded = false; 
    totalAmount = 0;
    uniqueId = '';
    invoiceData = [];
    @api isPrimaryCustomer;
    isAmountRequired = false;
    googleIcons = {
        invoices: GOOGLE_ICONS + "/googleIcons/invoices.png",
    };
    fieldRequired = false;

    connectedCallback(){
        this.isLoading=true;
        this.isAmountRequired = !this.isPrimaryCustomer;
        this.isDesktop = FORM_FACTOR === 'Large'? true : false;
        this.isPhone = FORM_FACTOR === 'Small'? true : false;
        if (FORM_FACTOR === 'Medium') this.isDesktop = true;
        this.customClass = this.isDesktop ?'slds-size_1-of-5 inputcustompadding' : 'slds-size_1-of-2 inputcustompadding';
        this.buttoncustomClass = this.isDesktop ? 'slds-size_1-of-5 inputcustompadding' : 'slds-size_1-of-1 inputcustompadding';
        this.collectioncustomClass = this.isDesktop ? 'slds-size_1-of-3 inputcustompadding' : 'slds-size_1-of-2 inputcustompadding';
        this.collectionRemarkscustomClass = this.isDesktop ? 'slds-size_1-of-3 inputcustompadding' : 'slds-size_1-of-1 inputcustompadding';
        this.adwanceAmountClass =  this.isDesktop ?'slds-size_1-of-5 inputcustompadding' : 'slds-size_1-of-2 inputcustompadding';
        this.uniqueId = 'FILE-' + 'collections'+Date.now()+ '-' +this.userId + '-' + Math.random().toString(36).substring(2, 10);
        this.collection.UniqueFileId__c = this.uniqueId;
        this.collection.Customer__c = this.acccountId;
        this.collection.Visit_For__c = this.isPrimaryCustomer ? 'Primary Customer':'Secondary Customer';
        this.collection.Visit__c=this.recordId;
        this.collectionItems[0].customClass =this.isDesktop ?'slds-size_1-of-5 inputcustompadding' : 'slds-size_1-of-2 inputcustompadding';
        this.collectionItems[0].isrequired = this.isPrimaryCustomer ? false : true;
        this.collectionItems[0].isUTRNumberRequired = false;
        this.getData();
    }
    getData(){
        if (!navigator.onLine) {
            this.showToast('Error', 'No internet connection. Please check your network and try again.', 'error');
            return;
        }
        this.isPageLoaded = true;
        getApexData({ 
            accountId: this.acccountId,
            isPrimaryCustomer:this.isPrimaryCustomer
        })
        .then(result => {
            this.modeOfPaymentOptions = result.modeOfPayment;
            if(this.isPrimaryCustomer)
            {
                this.collectionItems = []; // Start with an empty list

                // Add the Advance Amount item first
                this.collectionItems.push({
                    sObjectType: 'Collection_Item__c',
                    Id: null,
                    index: 1,
                    Invoice_Number__c: 'Advance Amount',
                    Invoice_Date__c: null,
                    Outstanding_Amount__c: null,
                    isAdwanceAmount: true,
                    customClass :this.isDesktop ?'slds-size_1-of-4 inputcustompadding' : 'slds-size_1-of-2 inputcustompadding'
                });
                
                // Then add the invoice items
                this.invoiceData = result.invoiceData;
                this.invoiceData.forEach((item, index) => {
                    this.collectionItems.push({
                        sObjectType: 'Collection_Item__c',
                        Id: null,
                        index: index + 2, // Advance is at index 1, so start from 2
                        Invoice_Number__c: item.Name,
                        Invoice_Date__c: item.Invoice_Date__c,
                        Outstanding_Amount__c: item.Outstanding_Amount__c,
                        isAdwanceAmount: false,
                        customClass :this.isDesktop ?'slds-size_1-of-5 inputcustompadding' : 'slds-size_1-of-2 inputcustompadding'
                    });
                });
            }
        
            this.isPageLoaded = false;
            setTimeout(() => {
                window.scrollTo({
                    top: 0,
                    behavior: 'smooth'
                });
            }, 0);
        })
        .catch(error => {
            console.error(error);
            this.isPageLoaded = false;
        });
    }
    

    handleInputChange(event) {
        const index = event.target.dataset.index;
        const field = event.target.name;
        const value = event.detail.value;
    
        this.collectionItems = this.collectionItems.map((item, i) => {
            if (i == index) {
                let updatedItem = { ...item, [field]: value };
                // Dynamically set isRequired based on isPrimaryCustomer and field
                if (field === 'Amount_Received__c' && this.isPrimaryCustomer && value !== '' && value !== 0 && value !== null) {
                    updatedItem.isrequired = true;
                }
                else if(field === 'Amount_Received__c' && this.isPrimaryCustomer && !value)
                {
                    updatedItem.isrequired = false;
                }
                else if(field === 'Mode_of_Payment__c' && value != 'Cash')
                {
                    updatedItem.isUTRNumberRequired = true;
                }
                else if(field === 'Mode_of_Payment__c' && value == 'Cash')
                {
                    updatedItem.isUTRNumberRequired = false;
                }
                return updatedItem;
            }
            return item;
        });
    }

    //Add and remove rows
    addRow() {
        const newRow =    {
            sObjectType: 'Collection_Item__c',
            Collection__c:null,
            index:1,
            Id: null,
            Amount_Received__c	:null,
            Mode_of_Payment__c:'',
            UTR_Number__c: null,
            Remarks__c :'',
            isrequired:this.isPrimaryCustomer ? false : true,
            isUTRNumberRequired:false,
            isAdwanceAmount:false,
            customClass :this.isDesktop ?'slds-size_1-of-5 inputcustompadding' : 'slds-size_1-of-2 inputcustompadding'
        }
        this.collectionItems = [...this.collectionItems, newRow];
    }
    removeRow(event) {
        const index = Number(event.target.dataset.index);

        // If only one row is left, clear its values using querySelector
        if (this.collectionItems.length === 1) {
            const rowElements = this.template.querySelectorAll(`[data-id="collectionFields"]`);
            rowElements.forEach(input => {
                input.value = ''; // Manually clear input fields
            });

            // Reset the only row instead of deleting it
            this.collectionItems = [  {
                sObjectType: 'Collection_Item__c',
                Collection__c:null,
                index:1,
                Id: null,
                Amount_Received__c	:null,
                Mode_of_Payment__c:'',
                UTR_Number__c: null,
                Remarks__c :'',
                isrequired:false,
                isUTRNumberRequired:false,
                isAdwanceAmount:false,
                customClass :this.isDesktop ?'slds-size_1-of-5 inputcustompadding' : 'slds-size_1-of-2 inputcustompadding'
            }];
        } else {
            // Create a copy of wagelist to ensure reactivity
            let updatedList = [...this.collectionItems];
            // Remove the selected row
            updatedList.splice(index, 1);

            // Assign the updated list to trigger reactivity
            this.collectionItems = updatedList;
        }
    }

    summaryCollections(event){
        const selectedName = event.target.dataset.name;
        if(selectedName == 'SelectedItems'){
            this.showAllProducts = true;
            this.isSummaryProduct = false;
        }
        else if(selectedName == 'Summary'){
            this.calculateTotal()
            if(this.validateReturns())
            {
                    // Only copy items where Amount_Received__c > 0
                this.summarycollectionItems = this.collectionItems
                .filter(item => item.Amount_Received__c > 0)
                .map(item => JSON.parse(JSON.stringify(item)));
                if(this.summarycollectionItems.length == 0 && this.isPrimaryCustomer)
                {
                    this.showToast('Error', 'Please enter the received amount for the advance or at least one invoice.', 'error');
                    return;
                }

                this.showAllProducts = false;
                this.isSummaryProduct = true;
            }
        }
    }
    calculateTotal() {
        let totalAmount = 0;
        this.collectionItems.forEach(item => {
            const amt = Number(item.Amount_Received__c) || 0;
            totalAmount += amt;
        });
        this.totalAmount = totalAmount;
        this.collection.Total_Received_Amount__c = totalAmount;
    }
    

  
    validateReturns() {
        let collectionItems = [...this.collectionItems];
    
        for (let index = 0; index < collectionItems.length; index++) {
            let item = collectionItems[index];
    
            if (this.isPrimaryCustomer) {
                // Validate only if Amount_Received__c is provided
                if (item.Amount_Received__c && item.Amount_Received__c > 0) {
                    if (!item.Mode_of_Payment__c   || !item.Remarks__c) {
                        this.showFieldError('collectionFields');
                        this.showToast('Error', `Please fill in all the mandatory fields for collection item ${index + 1}`, 'error');
                        return false;
                    }
                    if(item.Mode_of_Payment__c != 'Cash' && !item.UTR_Number__c)
                    {
                        this.showFieldError('collectionFields');
                        this.showToast('Error', `Please fill in all the mandatory fields for collection item ${index + 1}`, 'error');
                        return false;
                    }
                }
              
    
                // Ensure amount is not negative or zero when entered
                if (item.Amount_Received__c && item.Amount_Received__c <= 0) {
                    this.showFieldError('collectionFields');
                    this.showToast('Error', `Please enter a Received Amount greater than zero for collection item ${index + 1}`, 'error');
                    return false;
                }
                // Ensure received amount does not exceed outstanding amount
                if ( item.Outstanding_Amount__c && item.Amount_Received__c > item.Outstanding_Amount__c) {
                    this.showFieldError('collectionFields');
                    this.showToast('Error', `Received Amount for collection item ${index + 1} cannot be greater than the Outstanding Amount.`, 'error');
                    return false;
                }
    
            } else {
                // For non-primary customers: all fields must be filled
                if (!item.Amount_Received__c || !item.Mode_of_Payment__c || !item.Remarks__c) {
                    this.showFieldError('collectionFields');
                    this.showToast('Error', `Please fill in all the mandatory fields for collection item ${index + 1}`, 'error');
                  
                    return false;
                }
                if(item.Mode_of_Payment__c != 'Cash' && !item.UTR_Number__c)
                {
                    this.showFieldError('collectionFields');
                    this.showToast('Error', `Please fill in all the mandatory fields for collection item ${index + 1}`, 'error');
                    return false;
                }

                  // Ensure amount is not negative or zero when entered
                  if (item.Amount_Received__c && item.Amount_Received__c <= 0) {
                    this.showFieldError('collectionFields');
                    this.showToast('Error', `Please enter a Received Amount greater than zero for collection item ${index + 1}`, 'error');
                    return false;
                }
            }
        }
    
        return true;
    }
    
    //Save collection Data
    save() {
        if (!navigator.onLine) {
            this.showToast('Error', 'No internet connection. Please check your network and try again.', 'error');
            return;
        }
        this.isPageLoaded = true;
        saveCollection({ collectionData: this.collection, collectionItems: this.summarycollectionItems })
        .then(result => {
            this.showToast('Success', 'Collection Saved Successfully', 'Success');
             let message = { 
                message: 'executeScreen' ,
                screen : 3.2
            };
            this.genericDispatchEvent(message);
        })
        .catch(error => console.error(error))
        .finally(() => {
            this.isPageLoaded = false;
        });
    }

    /**------Helper methods--------**/
    //Show fiele Error
    showFieldError(fieldPrefix) {
        const inputFields = this.template.querySelectorAll(`[data-id^="${fieldPrefix}"]`); 
        if (inputFields.length > 0) {
            inputFields.forEach(input => {
                input.reportValidity(); // Show validation error
            });
        }
    }
    //disable pull to refesh
    disablePullToRefresh() {
        const disableRefresh = new CustomEvent("updateScrollSettings", {
            detail: {
            isPullToRefreshEnabled: false
            },
            bubbles: true,
            composed: true
        });
        this.dispatchEvent(disableRefresh);
    }
    //Show Toast
    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    } 
    genericDispatchEvent(message) {
        // Creating a custom event with a payload (optional)
        const event = new CustomEvent('screen4', {
            detail: message
        });

        // Dispatching the event
        this.dispatchEvent(event);
    }

  
}