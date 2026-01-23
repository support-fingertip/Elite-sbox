import { LightningElement,api,track,wire } from 'lwc';
import getApexData from '@salesforce/apex/beatPlannerlwc.getReturnData';
import PLANNER_ICON from '@salesforce/resourceUrl/planner';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import FORM_FACTOR from '@salesforce/client/formFactor';
import saveReturn from '@salesforce/apex/beatPlannerlwc.saveReturn'; 
import Id from '@salesforce/user/Id';

export default class ReturnsScreen extends LightningElement {

    ice = PLANNER_ICON + "/planner/screen-4-ice.png";
    userId = Id;
    uniqueId = '';
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
    isAllOrder = true;  isCategorySelected = false; isOrder = true; isSpecialOffer = false;
    searchPro = '';
    customOrderButton;
    OrderDate; subTotalAmt = 0; grandTotalAmt = 0; Discount = 0;
    isUomDisabled = true;
    qantityLabel ='Quantity';
    isDesktop = false;
    isPhone = false;
    @track  retunData = [
        {
            sObjectType: 'Return_Item__c',
            Return__c:null,
            index:1,
            Id: null,
            SKU__c:null,
            SKU_Name__c:'',
            Quantity__c: null,
            Batch_Number__c :'',
            Reason_For_Return__c:'',
            UOM__c:'',
            Total_Amount__c:0,
            Unit_Price__c:0,
            isShowSKU:false,
            isProductReadonly : false
         },
    ];
    @track  productList = [];
    resonForReturnOptions = [];
    @track searchedSkus = [];
    uomOptions = [];
    customClass = 'slds-size_1-of-7 inputcustompadding';
    buttoncustomClass = 'slds-size_1-of-7 inputcustompadding';
    productcustomClass = 'slds-size_2-of-9 inputcustompadding';
    showAllProducts = true;
    isSummaryProduct = false;
    isPageLoaded = false; 
    totalQuantity = 0;
    totalAmount = 0;
    @track productIdWithMrp = {};

    connectedCallback(){
        this.isLoading=true;
        this.isDesktop = FORM_FACTOR === 'Large'? true : false;
        this.isPhone = FORM_FACTOR === 'Small'? true : false;
        if (FORM_FACTOR === 'Medium') this.isDesktop = true;
        this.isOrder = this.objType == 'Product' ? true : false;
        this.productcustomClass = this.isDesktop ? 'slds-size_1-of-4 inputcustompadding' : 'slds-size_1-of-1 inputcustompadding';
        this.customClass = this.isDesktop ? 'slds-size_1-of-4 inputcustompadding' : 'slds-size_1-of-2 inputcustompadding';
        this.buttoncustomClass = this.isDesktop ? 'slds-size_1-of-4 inputcustompadding' : 'slds-size_1-of-1 inputcustompadding';
        this.uniqueId = 'FILE-' + 'returns'+Date.now()+ '-' +this.userId + '-' + Math.random().toString(36).substring(2, 10);
        this.getData();
    }
    getData(){
        if (!navigator.onLine) {
            this.showToast('Error', 'No internet connection. Please check your network and try again.', 'error');
            return;
        }
        this.isPageLoaded = true;
        console.log('this.acccountId'+this.acccountId);
        getApexData({ 
            accountId: this.acccountId,
        })
        .then(result => {
            this.productList = result.productList;
            this.productIdWithMrp = result.productIdWithMrp;
            this.resonForReturnOptions = result.resonForReturn;
            this.uomOptions = result.uom;
            this.isUomDisabled =  result.isUomDisabled;
            if(this.isUomDisabled)
            {
                this.qantityLabel = 'Quantity (Each)'
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
    //Product Search
    handleSKUSearch(event){
        const index = event.target.dataset.index;
        let searchValueName = event.target.value;
        if(searchValueName){
            let objData = this.productList;
     
            let searchedData = [];
            if(objData)
            {
                let searchLower = searchValueName.toLowerCase();
                for (let i = 0; i < objData.length; i++) {
                    const name = objData[i].Name ? objData[i].Name.toLowerCase() : '';
                    if (name.includes(searchLower)) {
                        searchedData.push(objData[i]);
                        if (searchedData.length >= 25) break;
                    }
                }
                this.retunData[index].isShowSKU = searchedData != 0 ? true : false;
                this.searchedSkus = searchedData;
            }
       
        }
        else
        {
            this.retunData[index].isShowSKU = false;
            this.retunData[index].SKU_Name__c = '';
            this.retunData[index].SKU__c = '';
            this.retunData[index].UOM__c = '';
            this.retunData[index].Unit_Price__c = 0;
            this.retunData[index].Total_Amount__c = 0;
            this.retunData[index].isProductReadonly = false;

        }

    }
    selectSKU(event) {
        const index = parseInt(event.currentTarget.dataset.index, 10);
        const selectedSKUId = event.currentTarget.dataset.id;
        const selectedSKUName = event.currentTarget.dataset.name;
        const selectedUOM = event.currentTarget.dataset.uom;
    
        // Check if the SKU already exists in any other row
        const isDuplicate = this.retunData.some((item, i) => 
            i !== index && item.SKU__c === selectedSKUId
        );
    
        if (isDuplicate) {
            this.showToast('Error', `SKU "${selectedSKUName}" already selected`, 'error');
            this.retunData[index].SKU_Name__c = '';
            this.retunData[index].isShowSKU = false;
            return;
        }
    
        // Assign selected SKU details
        const rowData = this.retunData[index];
        rowData.SKU__c = selectedSKUId;
        rowData.SKU_Name__c = selectedSKUName;
        rowData.UOM__c = selectedUOM;
        rowData.isShowSKU = false;
        rowData.isProductReadonly = true;
    
        // Assign unit price based on SKU
        const unitPrice = this.productIdWithMrp?.[selectedSKUId] ?? 0;
        rowData.Unit_Price__c = unitPrice;
    
        // If quantity exists, update unit price accordingly
        const qty = rowData.Quantity__c || 0;
        if (qty > 0) {
            rowData.Total_Amount__c = (qty * unitPrice).toFixed(2); // Returns string
        }

    }
    
    
    //input change
    handleInputChange(event) {
        const index = event.target.dataset.index;
        const field = event.target.name;
        const value = event.detail.value;
    
        this.retunData = this.retunData.map((item, i) => {
            if (i == index) {
                let updatedItem = { ...item, [field]: value };
    
                // If Quantity__c is being changed, calculate Total_Amount__c
                if (field === 'Quantity__c') {
                    const qty = parseFloat(value) || 0;
                    const unitPrice = parseFloat(updatedItem.Unit_Price__c) || 0;
                    updatedItem.Total_Amount__c = (qty * unitPrice).toFixed(2);
                }
    
                return updatedItem;
            }
            return item;
        });
    }

    //Add Product Mapping Item
    addReturnRow() {
        const newRow =   {
            sObjectType: 'Return_Item__c',
            Return__c:null,
            index:1,
            Id: null,
            SKU__c:null,
            SKU_Name__c:'',
            Quantity__c: null,
            Batch_Number__c :'',
            Invoice_Number__c:'',
            Reason_For_Return__c:'',
            UOM__c:'',
            Unit_Price__c:0,
            Total_Amount__c:0,
            isShowSKU:false,
            isProductReadonly : false
        }
        this.retunData = [...this.retunData, newRow];
    }
    removeReturnRow(event) {
        const index = Number(event.target.dataset.index);

        // If only one row is left, clear its values using querySelector
        if (this.retunData.length === 1) {
            const rowElements = this.template.querySelectorAll(`[data-id="returnFields"]`);
            rowElements.forEach(input => {
                input.value = ''; // Manually clear input fields
            });

            // Reset the only row instead of deleting it
            this.retunData = [ {
                sObjectType: 'Return_Item__c',
                Return__c:null,
                index:1,
                Id: null,
                SKU__c:null,
                SKU_Name__c:'',
                Quantity__c: null,
                Batch_Number__c :'',
                Invoice_Number__c:'',
                Reason_For_Return__c:'',
                UOM__c:'',
                Unit_Price__c:0,
                Total_Amount__c:0,
                isShowSKU:false,
                isProductReadonly : false
             }];
        } else {
            // Create a copy of wagelist to ensure reactivity
            let updatedList = [...this.retunData];
            // Remove the selected row
            updatedList.splice(index, 1);

            // Assign the updated list to trigger reactivity
            this.retunData = updatedList;
        }
    }

    selectedProduct(event){
        const selectedName = event.target.dataset.name;
        if(selectedName == 'SelectedItems'){
            this.showAllProducts = true;
            this.isSummaryProduct = false;
        }
        else if(selectedName == 'Summary'){
            this.calculateTotal()
            if(this.validateReturns())
            {
                this.showAllProducts = false;
                this.isSummaryProduct = true;
            }
        }
    }
    calculateTotal() {
        let totalQuantity = 0;
        let totalAmount = 0;
        this.retunData.forEach(item => {
            const qty = Number(item.Quantity__c) || 0;
            totalQuantity += qty;
            const amt = Number(item.Total_Amount__c) || 0;
            totalAmount += amt;
        });
        this.totalQuantity = totalQuantity;
        this.totalAmount = totalAmount.toFixed(2);
    }
    

    //Validate Returns
    validateReturns() {
        if (!navigator.onLine) {
            this.showToast('Error', 'No internet connection. Please check your network and try again.', 'error');
            return;
        }
        let retunData = [...this.retunData];
    
        for (let index = 0; index < retunData.length; index++) {
            let item = retunData[index];
    
            // Check if SKU fields are missing
            if (!item.SKU_Name__c || !item.SKU__c) {
                this.showFieldError('skufield');
                this.showToast('Error', `Please select a product for return item ${index + 1}`, 'error');
                return false;
            }
            // Check other required fields
            else if (!item.Quantity__c || !item.Batch_Number__c ||item.Batch_Number__c.trim() === ''  || !item.Reason_For_Return__c) {
                this.showFieldError('returnFields');
                this.showToast('Error', `Please fill in all the mandatory fields for return item ${index + 1}`, 'error');
                return false;
            }
            else if(item.Quantity__c  && item.Quantity__c <=0)
            {
                this.showFieldError('returnFields');
                this.showToast('Error', `Please enter a quantity greater than zero for return item ${index + 1}`, 'error');
                return false;
            }
        }
    
        return true;
    }
    

    //Save Retun Data
    save() {
        if (!navigator.onLine) {
            this.showToast('Error', 'No internet connection. Please check your network and try again.', 'error');
            return;
        }
        this.isPageLoaded = true;
    
        const returnParent = {
            sObjectType: 'Return__c',
            Customer__c: this.acccountId,
            Return_Date__c: new Date().toISOString(),
            Visit__c:this.recordId,
            Total_Quantity__c: this.totalQuantity,
            Total_Amount__c: this.totalAmount,
            UniqueFileId__c:this.uniqueId
        };
    
        saveReturn({ returnData: returnParent, returnItems: this.retunData })
        .then(result => {
            this.showToast('Success', 'Return Saved Successfully', 'Success');
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