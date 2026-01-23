import { LightningElement,api,track,wire } from 'lwc';
import getApexData from '@salesforce/apex/ReturnControllerLwc.getData';
import PLANNER_ICON from '@salesforce/resourceUrl/planner';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import FORM_FACTOR from '@salesforce/client/formFactor';
import saveShelfStock from '@salesforce/apex/beatPlannerlwc.saveShelfStock'; 
import Id from '@salesforce/user/Id';
import { NavigationMixin } from 'lightning/navigation';
import deleteFile from '@salesforce/apex/beatPlannerlwc.deleteFile';
import getFiles from '@salesforce/apex/beatPlannerlwc.getFiles';

export default class ShelfStockScreen extends NavigationMixin(LightningElement){
    userId = Id;
    @track uniqueId='';
    @track uploadedDocIds = [];
    ice = PLANNER_ICON + "/planner/screen-4-ice.png";
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
   
    isDesktop = false;
    isPhone = false;
    @track  shelfStockData = [
        {
            sObjectType: 'Shelf_Stock_Items__c',
            Shelf_Stock__c:null,
            index:1,
            Id: null,
            SKU__c:null,
            SKU_Name__c:'',
            Sales_Quantity__c:'', 
            Stock_Level__c:'',
            Comments__c:'',
            Compition_Remarks__c:'',
            isShowSKU:false
         },
    ];
    @track  productList = [];
   
    @track searchedSkus = [];
   
    customClass = 'slds-size_1-of-7 inputcustompadding';
    buttoncustomClass = 'slds-size_1-of-7 inputcustompadding';
    productcustomClass = 'slds-size_2-of-7 inputcustompadding';
    showAllProducts = true;
    isSummaryProduct = false;
    isPageLoaded = false; 
    totalSalesQuantity = 0;
    totalSalesStock = 0;

    connectedCallback(){
        this.isLoading=true;
        this.isDesktop = FORM_FACTOR === 'Large'? true : false;
        this.isPhone = FORM_FACTOR === 'Small'? true : false;
        if (FORM_FACTOR === 'Medium') this.isDesktop = true;
        this.isOrder = this.objType == 'Product' ? true : false;
        this.productcustomClass = this.isDesktop ? 'slds-size_2-of-7 inputcustompadding' : 'slds-size_1-of-1 inputcustompadding';
        this.customClass = this.isDesktop ? 'slds-size_1-of-7 inputcustompadding' : 'slds-size_1-of-2 inputcustompadding';
        this.buttoncustomClass = this.isDesktop ? 'slds-size_1-of-7 inputcustompadding' : 'slds-size_1-of-1 inputcustompadding';

        this.getData();
    }
    getData(){
        this.isPageLoaded = true;
        console.log('this.acccountId'+this.acccountId);
        getApexData({ 
            accountId: this.acccountId,
        })
        .then(result => {
            this.productList = result.productList;
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
            console.log('this.productList'+JSON.stringify(this.productList));
            let searchedData = [];
            if(objData)
            {
                for (let i = 0; i < objData.length; i++) {
                    const objName = objData[i];
                    if ((objName.Name && objName.Name.toLowerCase().indexOf(searchValueName.toLowerCase()) !== -1)) {
                        searchedData.push(objName);
                    }
                }
                this.shelfStockData[index].isShowSKU = searchedData != 0 ? true : false;
                this.searchedSkus = searchedData;
            }
       
        }
        else
        {
            this.shelfStockData[index].isShowSKU = false;
            this.shelfStockData[index].SKU_Name__c = '';
            this.shelfStockData[index].SKU__c = '';
            
        }

    }
    selectSKU(event) {
        const index = event.currentTarget.dataset.index;
        const selectedSKUId = event.currentTarget.dataset.id;
        const selectedSKUName = event.currentTarget.dataset.name;
        
    
        // Check if the SKU already exists in any other row
        const isDuplicate = this.shelfStockData.some((item, i) => 
            i != index && item.SKU__c === selectedSKUId
        );
    
        if (isDuplicate) {
            this.showToast('Error', `SKU "${selectedSKUName}" already selected`, 'error');
            // Optionally hide the dropdown
            this.shelfStockData[index].SKU_Name__c  = '';
            this.shelfStockData[index].isShowSKU = false;
            return;
        }
    
        // If not duplicate, proceed to assign values
        this.shelfStockData[index].SKU__c = selectedSKUId;
        this.shelfStockData[index].SKU_Name__c = selectedSKUName;
        this.shelfStockData[index].isShowSKU = false;

        
    }
    
    //input change
    handleInputChange(event) {
        const index = event.target.dataset.index;
        const field = event.target.name;
        const value = event.detail.value;
    
        this.shelfStockData = this.shelfStockData.map((item, i) => {
            if (i == index) {
                let updatedItem = { ...item, [field]: value };
    
                return updatedItem;
            }
            return item;
        });
    }

    //Add Product Mapping Item
    addReturnRow() {
        const newRow =   {
            sObjectType: 'Shelf_Stock_Items__c',
            Shelf_Stock__c:null,
            index:1,
            Id: null,
            SKU__c:null,
            SKU_Name__c:'',
            Sales_Quantity__c: null,
            Stock_Level__c:'',
            Comments__c:'',
            Compition_Remarks__c:'',
            isShowSKU:false
        }
        this.shelfStockData = [...this.shelfStockData, newRow];
    }
    removeReturnRow(event) {
        const index = Number(event.target.dataset.index);

        // If only one row is left, clear its values using querySelector
        if (this.shelfStockData.length === 1) {
            const rowElements = this.template.querySelectorAll(`[data-id="returnFields"]`);
            rowElements.forEach(input => {
                input.value = ''; // Manually clear input fields
            });

            // Reset the only row instead of deleting it
            this.shelfStockData = [ {
                sObjectType: 'Shelf_Stock_Items__c',
                Shelf_Stock__c:null,
                index:1,
                Id: null,
                SKU__c:null,
                SKU_Name__c:'',
                Sales_Quantity__c: null,
                Stock_Level__c:'',
                Comments__c:'',
                Compition_Remarks__c:'',
                isShowSKU:false
             }];
        } else {
            // Create a copy of wagelist to ensure reactivity
            let updatedList = [...this.shelfStockData];
            // Remove the selected row
            updatedList.splice(index, 1);

            // Assign the updated list to trigger reactivity
            this.shelfStockData = updatedList;
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
                this.uniqueId = 'FILE-' + Date.now()+ '-' +this.userId + '-' + Math.random().toString(36).substring(2, 10);
                    this.showAllProducts = false;
                    this.isSummaryProduct = true;
            }
        }
    }
    calculateTotal() {
        let totalQuantity = 0;
        let totalStock = 0;
        this.shelfStockData.forEach(item => {
            const qty = Number(item.Sales_Quantity__c) || 0;
            totalQuantity += qty;
            const amt = Number(item.Stock_Level__c) || 0;
            totalStock += amt;
        });
        this.totalSalesQuantity = totalQuantity;
        this.totalSalesStock = totalStock;
    }
    

    //Validate Returns
    validateReturns() {
        let shelfStockData = [...this.shelfStockData];
    
        for (let index = 0; index < shelfStockData.length; index++) {
            let item = shelfStockData[index];
    
            // Check if SKU fields are missing
            if (!item.SKU_Name__c || !item.SKU__c) {
                this.showFieldError('skufield');
                this.showToast('Error', `Please select a product for Shelf Stock item ${index + 1}`, 'error');
                return false;
            }
            // Check other required fields
            else if (!item.Sales_Quantity__c || !item.Stock_Level__c ) {
                this.showFieldError('returnFields');
                this.showToast('Error', `Please fill in all the mandatory fields for Shelf Stock  item ${index + 1}`, 'error');
                return false;
            }
            else if(item.Sales_Quantity__c  && item.Sales_Quantity__c <=0)
            {
                this.showFieldError('returnFields');
                this.showToast('Error', `Please enter a quantity greater than zero for Shelf Stock item ${index + 1}`, 'error');
                return false;
            }
        }
    
        return true;
    }
    

    //Save Retun Data
    save() {
        if(this.uploadedDocIds.length == 0)
        {
            this.showToast('Error', 'Please upload  a image', 'error');
            return;
        }
        this.isPageLoaded = true;
    
        const ShelfStockParent = {
            sObjectType: 'Shelf_Stock__c',
            Total_Stock_Level__c : this.totalSalesStock,
            Total_Sales_Quantity__c : this.totalSalesQuantity,
            Visit__c:this.recordId
        };
        const fileIds = this.uploadedDocIds.map(doc => doc.id);
    
        saveShelfStock({ ShelfStock: ShelfStockParent, ShelfStockItems: this.shelfStockData, uploadedFileIds: fileIds})
        .then(result => {
            this.showToast('Success', 'Shelf Stock Saved Successfully', 'Success');
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

    openCamera(){
        this.showCameraModal = true;
    }
    handleCameraStopped()
    {
        this.showCameraModal = false;
        this.loadAllFiles();
    }
    handleUploadFinished(event) {
        const uploadedFiles = event.detail.files;
    
        uploadedFiles.forEach(file => {
            let files = {name:file.name,id:file.documentId}
            this.uploadedDocIds.push(files);
        });
    
        // Trigger UI re-render if needed
        this.uploadedDocIds = [...this.uploadedDocIds];
    }
    
    async deleteFile(event) {
        console.log('Event received:', event);
        console.log('event.currentTarget.dataset:', event.currentTarget.dataset);
        
        const fileId = event.currentTarget.dataset.id;
        console.log('FileId::::::::::::::> ' + fileId);
    
        if (!fileId) {
            this.showToast('Error', 'File ID not found. Check the HTML data-id attribute.', 'error');
            return;
        }
    
        if (confirm('Confirm deleting this file?')) {
            this.isLoading = true;
            try {
                await deleteFile({ contentDocumentId: fileId });
                this.uploadedDocIds = this.uploadedDocIds.filter(file => file.id !== fileId);
                this.loadAllFiles();
                this.showToast('Success', 'File has been deleted successfully!', 'success');
            } catch (err) {
                console.error('Delete error', err);
                this.showToast('Error', 'Deletion failed', 'error');
            } finally {
                this.isLoading = false;
            }
        }
    }
    
    
    previewFile(event) {
        let recordId = event.currentTarget.dataset.id;
        console.log('recordId =====>'+recordId);
        //  const filetype = event.currentTarget.id
        // this[NavigationMixin.Navigate]({)
        this[NavigationMixin.Navigate]({
            type: 'standard__namedPage',
            attributes: {
                pageName: 'filePreview'
            },
            state: {
                selectedRecordId: recordId
            }
        });
    }

    loadAllFiles() {
        this.isLoading = true;
    
        getFiles({ uniqueId: this.uniqueId })
        .then(result => {
            this.uploadedFiles = result || [];
            this.uploadedDocIds = this.uploadedFiles.map(file => ({
                name: file.Title,  // ContentDocument's title
                id: file.Id        // Correct ID field
            }));
            console.log('================> ', this.uploadedDocIds);
        })
        .catch(error => {
            console.error('Error loading files:', error);
            this.uploadedDocIds = [];
        })
        .finally(() => {
            this.isLoading = false;
        });
    }

  
}