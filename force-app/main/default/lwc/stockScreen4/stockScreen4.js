import { LightningElement,api,track,wire } from 'lwc';
import getApexData from '@salesforce/apex/beatPlannerlwc.getStockProducts';
import saveOrderItem from '@salesforce/apex/beatPlannerlwc.upsertOrder';
import saveStockItem from '@salesforce/apex/beatPlannerlwc.upsertStock';
import PLANNER_ICON from '@salesforce/resourceUrl/planner';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class ProductScreen4 extends LightningElement {

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
    isProductAdded = false;
    isDropdownOrderOpen = true; isPageLoaded = false; isSummaryProduct = false;
    totalTaxAmt = 0; grandTotal = 0; totalQnt = 0;
    isCategorySelected = false;  isSpecialOffer = false;
    searchPro = '';
    OrderDate; subTotalAmt = 0; grandTotalAmt = 0; Discount = 0;
    showSummary = false;
    allProducts = true; 
    stockSummary = [];
    totalQuantity = 0;
    isProductDataExisted = false;
    
    connectedCallback(){
        this.isPageLoaded = true;
        this.getData();
    }
    getData(){
        if (!navigator.onLine) {
            this.genericDispatchToastEvent('Error', 'No internet connection. Please check your network and try again.', 'error');
            return;
        }
        getApexData({ 
            accountId:this.acccountId
        })
        .then(result => {
            
            this.productData = result.productCategories;
            this.isProductDataExisted = result.productCategories.length > 0 ? true:false; 
            this.originalSelectedProduct = result.productCategories;
            this.isPageLoaded = false;
        })
        .catch(error => {
            console.error(error);
            this.isPageLoaded = false;
        });
    }

    incProd(event){
        const index1 = parseInt(event.currentTarget.dataset.index);
        const index2 = parseInt(event.currentTarget.dataset.id);
        //this.productData[index].value = this.productValue;
        let inc = this.productData[index1].products[index2].value;
        inc++;
        this.productData[index1].products[index2].value = inc;
        this.sendUpdatedValue();
    }
    decProd(event){
        const index1 = parseInt(event.currentTarget.dataset.index);
        const index2 = parseInt(event.currentTarget.dataset.id);
        let dec =  this.productData[index1].products[index2].value;
        dec--;
        this.productData[index1].products[index2].value = dec > 0 ? dec : 0;
        this.sendUpdatedValue();
    }

    // Called when quantity input is changed
    prodChange(event) {
        const index1 = parseInt(event.target.dataset.index);
        const index2 = parseInt(event.target.dataset.id);
        const value = parseInt(event.target.value, 10);

        if (value > 0) {
            this.productData[index1].products[index2].value = value;
        } else {
            const oldVal = this.productData[index1].products[index2].value;
            event.target.value = oldVal;
            this.productData[index1].products[index2].value = oldVal;
        }

        // Always update originalSelectedProduct
        this.sendUpdatedValue();
    }

    // Update originalSelectedProduct quantities from productData
    sendUpdatedValue() {
        const updatedMap = new Map();
        this.productData.forEach(category => {
            category.products.forEach(product => {
                updatedMap.set(product.id, product.value);
            });
        });

        this.originalSelectedProduct.forEach(category => {
            category.products.forEach(product => {
                if (updatedMap.has(product.id)) {
                    product.value = updatedMap.get(product.id);
                }
            });
        });
    }

    // Called on Summary / Selected button click
    showSummaryProducts(event) {
        this.sendUpdatedValue();

        let summaryList = [];

        this.originalSelectedProduct.forEach(category => {
            category.products.forEach(product => {
                if (product.value > 0) {
                    summaryList.push({
                        sObjectType: 'Dealer_Stock__c',
                        Product__c: product?.id,
                        Product_Text__c:product?.name,
                        Account__c: this.acccountId,
                        Visit__c: this.recordId,
                        Quantity__c: product.value,
                        UOM__c: product.uom,
                        Store__c:this.acccountId
                    });
                }
            });
        });

        this.stockSummary = summaryList;

        if (summaryList.length === 0) {
            this.genericDispatchToastEvent('Error', 'Please enter the quantity for at least one SKU.', 'Error');
        } else {
            this.calculateTotal();
            this.allProducts = false;
            this.showSummary = true;
        }

        console.log('Summary products:', this.stockSummary);
    }
    showAllproducts()
    {
        this.showSummary = false;
        this.allProducts = true;
    }
    calculateTotal() {
        let totalQuantity = 0;
        this.stockSummary.forEach(item => {
            const qty = Number(item.Quantity__c) || 0;
            totalQuantity += qty;
        });
        this.totalQuantity = totalQuantity;
    }

    //Search Products
    @api onChangeProducts(event) {
        const rawInput = event?.target?.value;
        const searchTerm = rawInput ? rawInput.toLowerCase().trim() : '';
    
        if (!searchTerm) {
            this.productData = [...this.originalSelectedProduct];
            return;
        }
    
        this.productData = this.originalSelectedProduct
            .map(group => {
                // Filter products inside group
                const filteredProducts = group.products.filter(product =>
                    product.name.toLowerCase().includes(searchTerm)
                );
    
                if (filteredProducts.length > 0) {
                    return {
                        ...group,
                        products: filteredProducts
                    };
                }
                return null;
            })
            .filter(group => group !== null); 
        this.isProductDataExisted = this.productData.length > 0 ? true:false;     
    }
    
    saveStock(){
        if (!navigator.onLine) {
            this.genericDispatchToastEvent('Error', 'No internet connection. Please check your network and try again.', 'error');
            return;
        }
        saveStockItem({
            
            stocks : this.stockSummary
        })
        .then(result => {
            this.genericDispatchToastEvent('Success','Stock saved successfully','success');
            const  message = { 
                message: 'executeScreen' ,
                screen : 3.2,  
                isProgressVisit : true
                //orderData : this.orderData
            };
            this.genericDispatchEvent(message);
        })
        .catch(error => console.error(error))
        .finally(() => {
            this.isPageLoaded = false;
        });
    }




 
        
    genericDispatchToastEvent(title,message,variant){
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant
            })
        );
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