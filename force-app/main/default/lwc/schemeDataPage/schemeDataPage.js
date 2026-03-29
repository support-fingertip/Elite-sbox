import { LightningElement, track, wire, api } from 'lwc';
import { getObjectInfo, getPicklistValues } from "lightning/uiObjectInfoApi";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { updateRecord, deleteRecord, createRecord } from 'lightning/uiRecordApi';

// Object name and fields names to get the picklist values
import SCHEME from "@salesforce/schema/Scheme__c";
import SCHEME_TYPE from "@salesforce/schema/Scheme__c.Scheme_Type__c";
import SCHEME_APPLIES from "@salesforce/schema/Scheme__c.Applies_to__c";
import SALES_CHANNEL from "@salesforce/schema/Product__c.Channel__c";

//Apex class 
import ALL_DATA from '@salesforce/apex/SchemeLwc.getAllProduct';
import PROD_DATA from '@salesforce/apex/SchemeLwc.getAllProductById';
import SAVE_DATA from '@salesforce/apex/SchemeLwc.saveData';
import SAVEEXC_DATA from '@salesforce/apex/SchemeLwc.saveExclude';

export default class SchemeDataPage extends LightningElement {

    @api recordId;
    @api header;
    @track productsToShow = [];
    @track originalProductData = [];
    @track allCategory = [];
    @wire(getObjectInfo, { objectApiName: SCHEME })
    schemeObject;
    @track slaOptions;
    @track upsellOptions;
    @track options = {
        schemeType: [],
        appliesToData: [],
        appliesTo: []
    };
    @track salesChannelOptions = [];
    @track secondaryCustomerCategoryOptions = [];
    schemeTypeOptions = [
        { label: 'Free Quantity', value: 'Free Quantity' },
        { label: 'Sale Value Discount', value: 'Sale Value Discount' },
        { label: 'Per Quantity Off', value: 'Per Quantity Off' },
    ];
    // Per-channel product cache. Key = salesChannel string, Value = Product[] array
    productCacheByChannel = {};

    @wire(getPicklistValues, { recordTypeId: '$schemeObject.data.defaultRecordTypeId', fieldApiName: SCHEME_APPLIES })
    appliesToFieldInfo({ data, error }) {
        if (data) {
            this.options.appliesToData = data;
            this.checkAndCallDependency();
        } else if (error) {
            console.error('Error fetching SchemeType picklist values:', error);
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$schemeObject.data.defaultRecordTypeId', fieldApiName: SCHEME_TYPE })
    schemeTypeFieldInfo({ data, error }) {
        if (data) {
            this.options.schemeType = data.values;
            this.checkAndCallDependency();
        } else if (error) {
            console.error('Error fetching SchemeType picklist values:', error);
        }
    }

    checkAndCallDependency() {
        if (this.options.appliesToData?.values?.length > 0 &&
            this.options.schemeType?.length > 0 &&
            this.isDisable.appliesTo &&
            this.recordId == undefined) {
            this.dependencyPickList('Product');
            this.values.appliesTo = this.options.appliesToData.values[0].value;
            this.values.schemeType = this.options.schemeType[0].value;
        }
    }

    renderCall = false;
    renderedCallback() {
        if (this.renderCall) {
            return;
        }
        if (this.options.appliesToData?.values?.length > 0 &&
            this.options.schemeType?.length > 0 &&
            this.isDisable.appliesTo) {
            if (this.recordId != undefined && this.schemeData) {
                const scheme = this.schemeData;
                let key = this.options.appliesToData.controllerValues[scheme.Scheme_Type__c];
                this.options.appliesTo = this.options.appliesToData.values.filter(opt => opt.validFor.includes(key));
                this.renderCall = true;
                this.isProductSelected = scheme.Scheme_Type__c == 'Product' ? true : false;
            }
        }
    }

    @track isDisable = {
        appliesTo: true,
        allFields: true,
        subLineItems: true,
        isButton: true,
        proCat: false,
        exc: true,
        excButton: true,
        isDisableAction: false
    };

    @track values = {
        schemeType: '',
        salesChannel: '',
        appliesTo: '',
        startDate: '',
        endDate: '',
        name: '',
        searchValueDta: '',
        searchedObjData: [],
        proCatId: '',
        searchExc: '',
        Description: ''
    };

    proHeading = [
        { name: 'Product Name' },
        { name: 'Free Quantity' },
        { name: 'per sale Value (In %)' },
        { name: 'Per Kg' },
        { name: 'Flat Discount Per Box' },
        { name: 'Min' },
        { name: 'Action' }
    ];

    isPageLoaded = true; isSubPartLoaded = false; isProductCatSelected = false; isSaveButton = true;
    ListViewDetails; isProductSelected = true; isValueSearched = false; labelName = 'Search Product';
    placeHolderVal = 'Search Product....'; schemeTypeData = []; tempIndex = null;
    schemeData; buyProData = []; excludeDta = []; originalExc = []; isExclude = false; excIds = []; excProCatId; excludedId;
    isMapRegion = false; isArea = false; isRegion = false; isCustomer = false;

    connectedCallback() {
        this.isPageLoaded = true;
        this.disablePullToRefresh();
        this.productsToShow = [];
        this.getDataOnload(false);
    }

    // ─── Helper: recompute sNo for every row after any add/remove/clone ───
    _recomputeSerialNumbers() {
        this.productsToShow = this.productsToShow.map((row, idx) => ({
            ...row,
            sNo: idx + 1
        }));
    }

    getDataOnload(dependPickList) {
        this.isSubPartLoaded = true;
        ALL_DATA({ recordId: this.recordId })
            .then(result => {
                this.excIds = [];
                this.originalProductData = result.allProductsCat;
                this.allCategory = result.allCategory;
                this.ListViewDetails = result.ListViewDetails;
                this.salesChannelOptions = result.salesChannelPicklist.map(channel => ({
                    label: channel,
                    value: channel
                }));
                this.secondaryCustomerCategoryOptions = (result.secondaryCustomerCategoryPicklist || []).map(cat => ({
                    label: cat,
                    value: cat
                }));
                if (this.recordId == undefined) {
                    this.addRow();
                } else {
                    this.schemeData = result.scheme;
                    this.buyProData = result.buyPro;
                    if (result.scheme.Scheme_Type__c == 'Product') {
                        this.allProductData = result.allProducts;
                        this.schemeTypeData = this.allProductData;
                    } else {
                        this.schemeTypeData = this.allCategory;
                    }
                    this.addDataInRows();
                    const excData = result.excId != undefined ? result.excId : [];
                    for (var i = 0; i < excData.length; i++) {
                        const dt = {
                            id: this.values.schemeType == 'Product' ? excData[i].Product__c : excData[i].Category__c,
                            recordId: excData[i].Id
                        };
                        this.excIds.push(dt);
                    }
                    this.isDisable.exc = false;
                    this.excludedId = result.excData != undefined ? result.excData.Id : null;

                    if (this.productsToShow.length === 0) {
                        this.addRow();
                    }
                }
                if (dependPickList) {
                    this.dependencyPickList('Product');
                    this.values.schemeType = this.options.schemeType[0].value;
                    this.values.appliesTo = this.options.appliesToData.values[0].value;
                }
                this.isPageLoaded = false;
                this.isSubPartLoaded = false;
                this.isDisable.allFields = false;
            })
            .catch(error => {
                console.error(error);
                this.isPageLoaded = false;
                this.isSubPartLoaded = false;
            });
    }

    addDataInRows() {
        const scheme = this.schemeData;
        this.values.Description = scheme.Description__c;
        this.values.startDate = scheme.Scheme_Start_Date__c;
        this.values.name = scheme.Name;
        this.values.endDate = scheme.Scheme_End_Date__c;
        this.values.schemeType = scheme.Scheme_Type__c;
        this.values.appliesTo = scheme.Applies_to__c;
        this.values.proCatId = scheme.Product_Category__c ? scheme.Product_Category__c : null;
        this.values.searchValueDta = scheme.Product_Category__c ? scheme.Product_Category__r.Name : null;

        const buyPro = this.buyProData;
        this.productsToShow = buyPro.map((item, idx) => {
            const rowSchemeType = item.Scheme_Type__c || '';
            const fieldFlags = this.computeFieldFlags(rowSchemeType);

            return {
                Id: item.Id,
                proId: item.Product__c,
                catId: item.Category__c,
                searchValueDta: item.Product__c !== undefined ? item.Product__r.Name : item.Category__r.Name,
                buyQuantity: item.Buy_Quantity__c || 0,
                buyValue: item.Buy_Value__c || 0,
                offerQuantity: item.Offer_Quantity__c || 0,
                offerValue: item.Offer_Value__c || 0,
                offerPercent: item.Offer_Percent__c || 0,
                min: item.Min__c || 0,
                max: item.Max__c || 0,
                isValueSearched: false,
                isDisableFields: false,
                showDataDropDown: [],

                salesChannel: item.Sales_Channel__c || '',
                secondaryCustomerCategory: item.Secondary_Customer_Category__c || '',
                schemeType: rowSchemeType,
                isDisableSalesChannel: false,
                isDisableSchemeType: item.Sales_Channel__c ? false : true,

                isBuyQnt: fieldFlags.isBuyQnt,
                isBuyVal: fieldFlags.isBuyVal,
                isOfferQnt: fieldFlags.isOfferQnt,
                isOfferVal: true,
                isOfferPer: true,
                isMin: fieldFlags.isMin,
                isMax: true,
                isDiscount: fieldFlags.isDiscount,
                showCrossButton: true,

                Discount: item.Discount__c || 0,
                SaleValue: item.Sale_Value__c || 0,
                PerKg: item.Sale_Value_Threshold__c || 0,

                // Serial number
                sNo: idx + 1,
            };
        });

        this.isDisable.subLineItems = false;
        this.isDisable.proCat = true;
    }

    /**
     * Central method to compute which fields are enabled/disabled
     * based purely on schemeType string.
     * Returns an object of boolean flags — true = DISABLED.
     */
    computeFieldFlags(schemeType) {
        let flags = {
            isBuyQnt: true,
            isBuyVal: true,
            isOfferQnt: true,
            isMin: true,
            isDiscount: true,
        };

        if (schemeType === 'Free Quantity') {
            flags.isBuyQnt = false;
            flags.isMin = false;
        } else if (schemeType === 'Sale Value Discount') {
            flags.isBuyVal = false;
            flags.isOfferQnt = false;
        } else if (schemeType === 'Per Quantity Off') {
            flags.isOfferQnt = false;
            flags.isDiscount = false;
        }

        return flags;
    }

    addRow() {
        var dta = this.productsToShow;
        dta.push({
            Id: '',
            proId: '',
            catId: '',
            searchValueDta: '',
            buyQuantity: 0,
            buyValue: 0,
            offerQuantity: 0,
            offerValue: 0,
            offerPercent: 0,
            min: 0,
            max: 0,
            salesChannel: '',
            secondaryCustomerCategory: '',
            schemeType: '',
            isDisableSalesChannel: false,
            isDisableSchemeType: true,
            isDisableFields: true,
            isValueSearched: false,
            showDataDropDown: [],
            isBuyQnt: true,
            isBuyVal: true,
            isOfferQnt: true,
            isOfferVal: true,
            isOfferPer: true,
            isMin: true,
            isMax: true,
            isDiscount: true,
            showCrossButton: false,
            Discount: 0,
            SaleValue: 0,
            PerKg: 0,
            // sNo will be assigned by _recomputeSerialNumbers below
            sNo: dta.length + 1,
        });

        if (this.values.schemeType == 'Product') {
            this.isDisable.subLineItems = this.values.proCatId == '' ? true : false;
        } else if (this.values.schemeType == 'Category') {
            this.isDisable.subLineItems = false;
        }

        this.productsToShow = dta;
        this._recomputeSerialNumbers();
    }

    handleCloneRow(event) {
        const index = event.currentTarget.dataset.index;
        const rowData = this.productsToShow[index];
        const clonedRow = { ...rowData };
        clonedRow.Id = '';
        clonedRow.isDisableFields = false;
        clonedRow.showCrossButton = true;
        clonedRow.proId = null;
        clonedRow.searchValueDta = '';
        this.productsToShow.push(clonedRow);
        this.productsToShow = [...this.productsToShow];
        this._recomputeSerialNumbers();
    }

    handleProductVal(event) {
        const index = parseInt(event.target.dataset.index, 10);
        const fieldName = event.target.name;
        const value = event.target.value;
        const product = { ...this.productsToShow[index] };
        product[fieldName] = value;

        if (fieldName === 'salesChannel') {
            product.salesChannel = value;
            product.isDisableSchemeType = false;
            product.searchValueDta = '';
            product.proId = '';
            product.catId = '';
            product.isValueSearched = false;
            product.showDataDropDown = [];

        } else if (fieldName === 'schemeType') {
            product.schemeType = value;

            // Reset all numeric field values to 0 when scheme type changes
            product.buyQuantity = 0;
            product.min = 0;
            product.SaleValue = 0;
            product.PerKg = 0;
            product.Discount = 0;
            product.buyValue = 0;
            product.offerQuantity = 0;
            product.offerValue = 0;
            product.offerPercent = 0;

            // Use central computeFieldFlags so both new & edit behave identically
            const flags = this.computeFieldFlags(value);
            product.isBuyQnt   = flags.isBuyQnt;
            product.isBuyVal   = flags.isBuyVal;
            product.isOfferQnt = flags.isOfferQnt;
            product.isMin      = flags.isMin;
            product.isDiscount = flags.isDiscount;
            product.isOfferVal = true;
            product.isOfferPer = true;
            product.isMax      = true;
        }

        this.productsToShow[index] = product;
        this.productsToShow = [...this.productsToShow];
    }

    handleSearchPro(event) {
        const index = parseInt(event.target.dataset.index, 10);
        const searchText = event.target.value;
        const product = this.productsToShow[index];
        const salesChannel = product.salesChannel;

        if (!salesChannel) {
            this.genericToastDispatchEvent("Error", "Select Sales Channel first!", "error");
            return;
        }

        if (!searchText || !searchText.trim()) {
            this.productsToShow[index].isValueSearched = false;
            this.productsToShow[index].showDataDropDown = [];
            this.productsToShow = [...this.productsToShow];
            return;
        }

        if (this.productCacheByChannel[salesChannel] && this.productCacheByChannel[salesChannel].length > 0) {
            this.filterAndDisplayProducts(index, searchText, salesChannel);
        } else {
            PROD_DATA({ salesChannel: salesChannel })
                .then(data => {
                    this.productCacheByChannel[salesChannel] = data.allProducts || [];
                    this.filterAndDisplayProducts(index, searchText, salesChannel);
                })
                .catch(error => {
                    console.error('Error fetching products for channel:', salesChannel, error);
                    this.genericToastDispatchEvent("Error", "Failed to load products", "error");
                });
        }
    }

    filterAndDisplayProducts(index, searchText, salesChannel) {
        const channelProducts = this.productCacheByChannel[salesChannel] || [];
        const filteredProducts = channelProducts.filter(p =>
            p.Name.toLowerCase().includes(searchText.toLowerCase())
        );
        this.productsToShow[index].showDataDropDown = filteredProducts;
        this.productsToShow[index].isValueSearched = filteredProducts.length > 0;
        this.productsToShow = [...this.productsToShow];
    }

    handleSearch(event) {
        this.values.searchValueDta = event.target.value;
        if (this.values.searchValueDta) {
            var storeData = this.searchText(this.originalProductData, this.values.searchValueDta);
            this.isValueSearched = storeData != 0 ? true : false;
            this.values.searchedObjData = storeData;
        } else {
            this.values.proCatId = '';
            this.isDisable.subLineItems = true;
            this.productsToShow = [];
            this.addRow();
        }
    }

    searchText(objData, serchTxt) {
        if (objData == undefined) return;
        return objData.filter(obj => obj.Name && obj.Name.toLowerCase().includes(serchTxt.toLowerCase()));
    }

    handleOnBlur() {
        setTimeout(() => {
            this.isValueSearched = false;
            if (this.tempIndex != null) {
                this.productsToShow[this.tempIndex].showDataDropDown = [];
                this.productsToShow[this.tempIndex].isValueSearched = false;
                this.tempIndex = null;
            }
        }, 1000);
    }

    handleSchemeType(event) {
        this.dependencyPickList(event.target.value);
        this.productsToShow = [];
        if (event.target.value == 'Product') {
            this.labelName = 'Search Product';
            this.placeHolderVal = 'Search Product....';
            this.schemeTypeData = this.allProductData;
            this.isProductSelected = true;
            this.isDisable.exc = true;
        } else {
            this.labelName = 'Search Category';
            this.placeHolderVal = 'Search Category....';
            this.schemeTypeData = this.allCategory;
            this.isProductSelected = false;
            this.isDisable.exc = false;
        }
        this.addRow();
    }

    dependencyPickList(val) {
        let key = this.options.appliesToData.controllerValues[val];
        this.options.appliesTo = this.options.appliesToData.values.filter(opt => opt.validFor.includes(key));
        this.values.appliesTo = '';
        this.isDisable.appliesTo = false;
        this.values.schemeType = val;
    }

    handleChangeValues(event) {
        this.values[event.target.name] = event.target.value;
    }

    handleSave() {
        const { name, startDate, endDate, schemeType, appliesTo, proCatId, Description } = this.values;
        let missingFields = [];
        if (!name) missingFields.push("Name");
        if (!startDate) missingFields.push("Start Date");
        if (!endDate) missingFields.push("End Date");
        if (!schemeType) missingFields.push("Scheme Type");
        if (!appliesTo) missingFields.push("Applies To");
        if (!Description) missingFields.push("Description");

        if (missingFields.length > 0) {
            this.genericToastDispatchEvent("Error", `Please fill ${missingFields.join(", ")}`, "error");
            return;
        }

        const storData = this.productsToShow;
        if (this.validateFields(0, this.productsToShow.length - 1)) {
            return;
        }

        for (let i = 0; i < this.productsToShow.length; i++) {
            this.productsToShow[i].isBuyQnt = true;
            this.productsToShow[i].isBuyVal = true;
            this.productsToShow[i].isOfferQnt = true;
            this.productsToShow[i].isOfferVal = true;
            this.productsToShow[i].isOfferPer = true;
            this.productsToShow[i].isMin = true;
            this.productsToShow[i].isMax = true;
            this.productsToShow[i].isDiscount = true;
            this.productsToShow[i].showCrossButton = false;
        }

        this.isDisable.allFields = true;
        this.isDisable.appliesTo = true;

        const schemeDta = {
            Id: this.recordId,
            Applies_to__c: appliesTo,
            Scheme_End_Date__c: endDate,
            Name: name,
            Scheme_Start_Date__c: startDate,
            Scheme_Type__c: schemeType,
            IsActive__c: true,
            Product_Category__c: proCatId,
            Description__c: Description,
        };

        const ProductBuy = storData.map(item => ({
            Id: item.Id === '' ? null : item.Id,
            Buy_Quantity__c: item.buyQuantity,
            Buy_Value__c: item.buyValue,
            Offer_Percent__c: item.offerPercent,
            Offer_Quantity__c: item.offerQuantity,
            Offer_Value__c: item.offerValue,
            Min__c: item.min,
            Max__c: item.max,
            Product__c: item.proId,
            Category__c: item.catId,
            Discount__c: item.Discount,
            Sale_Value__c: item.SaleValue,
            Sale_Value_Threshold__c: item.PerKg,
            Sales_Channel__c: item.salesChannel,
            Scheme_Type__c: item.schemeType,
            Secondary_Customer_Category__c: item.secondaryCustomerCategory
        }));

        this.productsToShow = this.productsToShow.map(item => ({ ...item, isDisableFields: true }));

        SAVE_DATA({
            ProductBuy,
            schemeDta,
            proCatId,
            excProCatId: this.excProCatId,
            excludedId: this.excludedId
        })
            .then(data => {
                this.recordId = data;
                this.isDisable.isButton = false;
                this.isDisable.proCat = true;
                this.isDisable.subLineItems = true;
                this.isSaveButton = false;
                this.isDisable.isDisableAction = true;
                var dt = this.productsToShow;
                for (let i = 0; i < dt.length; i++) {
                    dt[i].isDisableAction = true;
                }
                this.productsToShow = dt;
                this.genericToastDispatchEvent("Success", "Scheme Created Successfully", "success");
                const msg = { message: 'Done', id: this.recordId };
                this.genericDispatchEvent('ClickAction', msg);
            })
            .catch(error => {
                this.isDisable.allFields = false;
                console.log(error);
            });
    }

    handlePrevious() {
        this.refreshData();
    }

    refreshData() {
        this.values.startDate = '';
        this.values.endDate = '';
        this.values.name = '';
        this.isSaveButton = true;
        this.isDisable.allFields = true;
        this.isDisable.appliesTo = true;
        this.getDataOnload(true);
    }

    handleDone() {
        const msg = { message: 'Done', id: this.recordId };
        this.genericDispatchEvent('ClickAction', msg);
    }

    handleCancel() {
        const msg = { message: 'close', id: this.ListViewDetails.Id };
        this.genericDispatchEvent('ClickAction', msg);
    }

    selectObjName(event) {
        const index = parseInt(event.currentTarget.dataset.index, 10);
        this.values.proCatId = event.currentTarget.dataset.id;
        this.values.searchValueDta = event.currentTarget.dataset.name;
        this.isValueSearched = false;
        const salesChannel = index !== undefined && this.productsToShow[index]
            ? this.productsToShow[index].salesChannel
            : this.values.salesChannel;
        this.getProductData(salesChannel);
    }

    selectProName(event) {
        const index = parseInt(event.currentTarget.dataset.index, 10);
        const productId = event.currentTarget.dataset.id;

        const isDuplicate = this.productsToShow.some((prod, i) =>
            i !== index &&
            prod.schemeType === this.productsToShow[index].schemeType &&
            prod.secondaryCustomerCategory === this.productsToShow[index].secondaryCustomerCategory &&
            (prod.proId === productId || prod.catId === productId)
        );

        if (isDuplicate) {
            this.genericToastDispatchEvent(
                "Error",
                "This product with the selected Scheme Type already exists in the table",
                "error"
            );
            return;
        }

        this.productsToShow[index].searchValueDta = event.currentTarget.dataset.name;
        if (this.values.schemeType == 'Product') {
            this.productsToShow[index].proId = event.currentTarget.dataset.id;
        } else if (this.values.schemeType == 'Category') {
            this.productsToShow[index].catId = event.currentTarget.dataset.id;
        }
        this.productsToShow[index].isValueSearched = false;
        this.productsToShow[index].isDisableFields = false;
        this.productsToShow[index].showCrossButton = true;

        const schemeType = this.productsToShow[index].schemeType;
        this.handleProductVal({
            target: {
                name: 'schemeType',
                value: schemeType,
                dataset: { index }
            }
        });
    }

    handleAddRow(event) {
        const index = parseInt(event.currentTarget.dataset.index, 10);
        if (this.validateFields(index, index)) return;
        this.addRow();
    }

    handleRemoveRow(event) {
        const index = parseInt(event.currentTarget.dataset.index, 10);

        if (index === undefined || this.productsToShow.length <= index) return;

        const removeDta = this.productsToShow[index];

        this.productsToShow.splice(index, 1);
        this.productsToShow = [...this.productsToShow];

        // Recompute serial numbers after removal
        this._recomputeSerialNumbers();

        if (this.productsToShow.length === 0) {
            this.addRow();
        }

        if (removeDta && removeDta.Id !== '' && removeDta.Id != null) {
            deleteRecord(removeDta.Id)
                .then(() => {
                    this.genericToastDispatchEvent('Success', 'Deleted successfully', 'success');
                })
                .catch(error => {
                    console.log(error);
                    this.genericToastDispatchEvent('Error', 'Failed to delete record', 'error');
                });
        }
    }

    validateFields(i, j) {
        for (let k = i; k <= j; k++) {
            const dta = this.productsToShow[k];
            const lineNo = dta.sNo || (k + 1);
            const { schemeType } = this.values;

            const fieldValidations = [
                {
                    condition: !dta.salesChannel,
                    message: `Line ${lineNo}: Please select Sales Channel`
                },
                {
                    condition: !dta.schemeType,
                    message: `Line ${lineNo}: Please select Scheme Type`
                },
                {
                    condition: schemeType === 'Product' && !dta.proId,
                    message: `Line ${lineNo}: Please select Product`
                },
                {
                    condition: schemeType === 'Category' && !dta.catId,
                    message: `Line ${lineNo}: Please select Category`
                },
                {
                    condition: !dta.secondaryCustomerCategory,
                    message: `Line ${lineNo}: Please select Secondary Customer Category`
                },
                {
                    condition: dta.buyQuantity == 0 && dta.min == 0 && dta.SaleValue == 0 && dta.PerKg == 0 && dta.Discount == 0,
                    message: `Line ${lineNo}: Please enter at least one value`
                },
                {
                    condition: dta.buyQuantity == 0 && dta.min != 0,
                    message: `Line ${lineNo}: Please enter Free Quantity`
                },
                {
                    condition: dta.buyQuantity != 0 && dta.min == 0,
                    message: `Line ${lineNo}: Please enter Min Value`
                },
                {
                    condition: dta.SaleValue != 0 && dta.PerKg == 0,
                    message: `Line ${lineNo}: Please enter Threshold value`
                },
            ];

            for (const { condition, message } of fieldValidations) {
                if (condition) {
                    this.genericToastDispatchEvent("Error", message, "error");
                    return true;
                }
            }
        }

        for (let k = i; k <= j; k++) {
            this.productsToShow[k].buyQuantity = this.productsToShow[k].buyQuantity != '' ? this.productsToShow[k].buyQuantity : 0;
            this.productsToShow[k].min = this.productsToShow[k].min != '' ? this.productsToShow[k].min : 0;
            this.productsToShow[k].SaleValue = this.productsToShow[k].SaleValue != '' ? this.productsToShow[k].SaleValue : 0;
            this.productsToShow[k].PerKg = this.productsToShow[k].PerKg != '' ? this.productsToShow[k].PerKg : 0;
            this.productsToShow[k].Discount = this.productsToShow[k].Discount != '' ? this.productsToShow[k].Discount : 0;
        }
        return false;
    }

    getProductData(salesChannel) {
        if (this.values.proCatId == '') return;
        if (!salesChannel) {
            console.warn('getProductData called without a salesChannel — skipping fetch');
            return;
        }
        if (this.productCacheByChannel[salesChannel] && this.productCacheByChannel[salesChannel].length > 0) {
            this.allProductData = this.productCacheByChannel[salesChannel];
            this.schemeTypeData = this.allProductData;
            return;
        }
        this.isSubPartLoaded = true;
        PROD_DATA({ salesChannel: salesChannel })
            .then(data => {
                this.productCacheByChannel[salesChannel] = data.allProducts || [];
                this.allProductData = this.productCacheByChannel[salesChannel];
                this.schemeTypeData = this.allProductData;
                this.isSubPartLoaded = false;
            })
            .catch(error => {
                console.error('Error loading products for channel:', salesChannel, error);
                this.isSubPartLoaded = false;
            });
    }

    excludePro() {
        this.excludeDta = this.schemeTypeData.map(item => {
            const matchedExc = this.excIds.find(exc => exc.id === item.Id);
            return {
                ...item,
                isCheckBox: !!matchedExc,
                recordId: matchedExc ? matchedExc.recordId : null
            };
        });
        this.originalExc = this.excludeDta;
        this.excButton = false;
        this.isExclude = true;
        this.isDisable.isExclude = false;
        this.excProCatId = this.values.proCatId;
    }

    handleCheckBoxValue(event) {
        const index = parseInt(event.currentTarget.dataset.index, 10);
        this.excludeDta[index].isCheckBox = event.target.checked;
        for (let i = 0; i < this.originalExc.length; i++) {
            if (this.excludeDta[index].Id == this.originalExc[i].Id) {
                this.originalExc[i].isCheckBox = event.target.checked;
                break;
            }
        }
    }

    saveExcludePro() {
        var createId = [];
        for (let i = 0; i < this.excludeDta.length; i++) {
            if (this.excludeDta[i].isCheckBox && this.excludeDta[i].recordId == null) {
                const dt = {
                    Product__c: this.values.schemeType == 'Product' ? this.excludeDta[i].Id : null,
                    Category__c: this.values.schemeType == 'Category' ? this.excludeDta[i].Id : null,
                };
                createId.push(dt);
            }
        }
        var deleteId = [];
        if (this.recordId != undefined) {
            for (let i = 0; i < this.excludeDta.length; i++) {
                if (!this.excludeDta[i].isCheckBox && this.excludeDta[i].recordId != null) {
                    deleteId.push(this.excludeDta[i].recordId);
                }
            }
        }
        if (createId.length == 0 && this.recordId == undefined) {
            this.genericToastDispatchEvent("Error", "Please select atleast one product", "error");
            return;
        }
        this.isDisable.isExclude = true;
        SAVEEXC_DATA({
            prodCatId: this.values.proCatId,
            exc: createId,
            exId: this.excludedId,
            deleteId: deleteId
        })
            .then(result => {
                this.excIds = [];
                const excData = result.excId;
                for (var i = 0; i < excData.length; i++) {
                    const dt = {
                        id: this.values.schemeType == 'Product' ? excData[i].Product__c : excData[i].Category__c,
                        recordId: excData[i].Id
                    };
                    this.excIds.push(dt);
                }
                this.isDisable.exc = false;
                this.excludedId = result.excData.Id;
                this.isDisable.isExclude = false;
                this.isExclude = false;
            })
            .catch(error => {
                this.isDisable.isExclude = false;
                console.log(error);
            });
    }

    closeExcludePopup() {
        this.isExclude = false;
    }

    handleMapAll() { this.isMapRegion = true; this.isArea = true; this.isRegion = true; this.isCustomer = true; }
    handleMapRegion() { this.isMapRegion = true; this.isArea = false; this.isRegion = true; this.isCustomer = false; }
    handleMapArea() { this.isMapRegion = true; this.isArea = true; this.isRegion = false; this.isCustomer = false; }
    handleMapCustomerCategory() { this.isMapRegion = true; this.isArea = false; this.isRegion = false; this.isCustomer = true; }

    onclickFun(event) {
        const msg = event.detail;
        if (msg.message == "mapRegion_close") {
            this.isMapRegion = false; this.isArea = false; this.isRegion = false; this.isCustomer = false;
        }
        if (msg.message == "mapRegion_Save") {
            this.isMapRegion = false; this.isArea = false; this.isRegion = false; this.isCustomer = false;
            this.genericToastDispatchEvent('Success', 'Mapping Saved', 'success');
        }
    }

    handleSearchExclude(event) {
        const val = event.target.value;
        this.values.searchExc = val;
        if (val != '') {
            var serchedDta = this.originalExc.filter(obj => obj.Name && obj.Name.toLowerCase().includes(val.toLowerCase()));
            this.excludeDta = serchedDta;
        } else {
            this.excludeDta = this.originalExc;
        }
    }

    genericDispatchEvent(eventName, msg) {
        const event = new CustomEvent(eventName, { detail: msg });
        this.dispatchEvent(event);
    }

    genericToastDispatchEvent(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    disablePullToRefresh() {
        const disableRefresh = new CustomEvent("updateScrollSettings", {
            detail: { isPullToRefreshEnabled: false },
            bubbles: true,
            composed: true
        });
        this.dispatchEvent(disableRefresh);
    }
}