import { LightningElement, track, wire } from 'lwc';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import PRODUCT_OBJECT from '@salesforce/schema/Product__c';
import CATEGORY_FIELD from '@salesforce/schema/Product__c.Category__c';
import getProductGalleryData from '@salesforce/apex/DMSPortalLwc.getProductGalleryData';

export default class ProductGalleryLwc extends LightningElement {
    @track allProducts = [];
    @track filteredProducts = [];
    @track categoryOptions = [{ label: 'All Categories', value: '' }];
    @track selectedCategory = '';
    @track productSearchKey = '';
    isLoading = false;
    errorMessage = '';
    productRecordTypeId;

    @wire(getObjectInfo, { objectApiName: PRODUCT_OBJECT })
    objectInfoHandler({ data }) {
        if (data) {
            this.productRecordTypeId = data.defaultRecordTypeId;
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$productRecordTypeId', fieldApiName: CATEGORY_FIELD })
    picklistHandler({ data, error }) {
        if (data) {
            this.categoryOptions = [
                { label: 'All Categories', value: '' },
                ...data.values.map(v => ({ label: v.label, value: v.value }))
            ];
        }
        if (error) {
            console.error('Error loading category picklist:', JSON.stringify(error));
        }
    }

    connectedCallback() {
        this.loadProductGalleryData();
    }

    loadProductGalleryData() {
        this.isLoading = true;
        this.errorMessage = '';
        getProductGalleryData()
            .then(products => {
                console.log('Products received:', products ? products.length : 0);
                if (!products || products.length === 0) {
                    this.errorMessage = 'No products returned from server.';
                    this.isLoading = false;
                    return;
                }

                const mappedProducts = products.map(p => {
                    return {
                        id: p.Id,
                        name: p.Name,
                        sku: p.SKU_Code__c || '',
                        price: p.List_Price__c,
                        mrp: p.MRP__c,
                        category: p.Category__c || 'Uncategorized',
                        channel: p.Channel__c,
                        uom: p.UOM__c,
                        taxPercent: p.Tax_Percent__c,
                        imageUrl: p.Product_Image_Url__c || null,
                        hasImage: !!p.Product_Image_Url__c
                    };
                });

                this.allProducts = mappedProducts;
                this.filteredProducts = mappedProducts;
                this.isLoading = false;
            })
            .catch(error => {
                console.error('Error loading product gallery:', JSON.stringify(error));
                this.errorMessage = error?.body?.message || error?.message || 'Unknown error loading products';
                this.isLoading = false;
            });
    }

    handleProductCategoryChange(event) {
        this.selectedCategory = event.detail.value;
        this.filterProducts();
    }

    handleProductSearch(event) {
        this.productSearchKey = event.target.value;
        this.filterProducts();
    }

    filterProducts() {
        let result = this.allProducts;
        if (this.selectedCategory) {
            result = result.filter(p => p.category === this.selectedCategory);
        }
        if (this.productSearchKey) {
            const key = this.productSearchKey.toLowerCase();
            result = result.filter(p => p.name && p.name.toLowerCase().includes(key));
        }
        this.filteredProducts = result;
    }

    get hasProducts() {
        return this.filteredProducts && this.filteredProducts.length > 0;
    }
}