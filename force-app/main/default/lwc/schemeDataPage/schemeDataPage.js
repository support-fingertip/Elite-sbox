import { LightningElement,track, wire,api } from 'lwc';
import { getObjectInfo, getPicklistValues } from "lightning/uiObjectInfoApi";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { updateRecord, deleteRecord, createRecord } from 'lightning/uiRecordApi';

// Object name and fields names to get the gicklist values
import SCHEME from "@salesforce/schema/Scheme__c";
import SCHEME_TYPE from "@salesforce/schema/Scheme__c.Scheme_Type__c";
import SCHEME_APPLIES from "@salesforce/schema/Scheme__c.Applies_to__c";
import SALES_CHANNEL from "@salesforce/schema/Product__c.Channel__c";

//Apex class 
import ALL_DATA from '@salesforce/apex/SchemeLwc.getAllProduct';
import PROD_DATA from '@salesforce/apex/SchemeLwc.getAllProductById';
import SAVE_DATA from '@salesforce/apex/SchemeLwc.saveData';
import SAVEEXC_DATA from '@salesforce/apex/SchemeLwc.saveExclude';
import Id from '@salesforce/schema/Account.Id';

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
        schemeType : [],
        appliesToData : [],
        appliesTo : []
    };
    @track salesChannelOptions = [];
    schemeTypeOptions = [
        { label: 'Free Quantity', value: 'Free Quantity' },
        { label: 'Sale Value Discount', value: 'Sale Value Discount' },
        { label: 'Per Quantity Off', value: 'Per Quantity Off' },
    ];
    allProductData = [];

    @wire(getPicklistValues, {recordTypeId: '$schemeObject.data.defaultRecordTypeId', fieldApiName: SCHEME_APPLIES  })
    appliesToFieldInfo({ data, error }) {
        if (data) {
            this.options.appliesToData  = data;
            this.checkAndCallDependency();

        }else if (error) {
            console.error('Error fetching SchemeType picklist values:', error);
        }
    }

    
    @wire(getPicklistValues, {recordTypeId:'$schemeObject.data.defaultRecordTypeId', fieldApiName: SCHEME_TYPE })
    schemeTypeFieldInfo({ data, error }) {
        if (data) {this.options.schemeType = data.values;
            this.checkAndCallDependency();
        }else if (error) {
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
    renderedCallback(){
        if(this.renderCall){
            return;
        }
        if (this.options.appliesToData?.values?.length > 0 && 
            this.options.schemeType?.length > 0 && 
            this.isDisable.appliesTo ){
                if(this.recordId != undefined && this.schemeData){
                    const scheme = this.schemeData;
                    let key = this.options.appliesToData.controllerValues[scheme.Scheme_Type__c];
                    this.options.appliesTo = this.options.appliesToData.values.filter(opt => opt.validFor.includes(key));    
                    this.renderCall = true;
                    this.isProductSelected = scheme.Scheme_Type__c == 'Product'?true:false;
                }
            }
    }
    @track  isDisable = {
        appliesTo : true,
        allFields : true,
        subLineItems : true,
        isButton : true,
        proCat : false,
        exc : true,
        excButton : true,
        isDisableAction : false
    };
    @track values = {
        schemeType : '',
        salesChannel : '',
        appliesTo : '',
        startDate : '',
        endDate : '',
        name : '',
        searchValueDta : '',
        searchedObjData : [],
        proCatId : '',
        searchExc : '',
        Description : ''
    };
    proHeading = [
        { name: 'Product Name' },
        { name: 'Free Quantity' },
        // { name: 'Buy Value' },
        // { name: 'Offer Quantity' },
        // { name: 'Offer Value' },
        // { name: 'Offer Percent' },
        { name: 'per sale Value (In %)'},
        { name: 'Per Kg' },
        { name: 'Flat Discount Per Box' },
        { name: 'Min' },
        // { name: 'Max' },
        { name: 'Action' }
    ];
    
    isPageLoaded = true; isSubPartLoaded = false; isProductCatSelected = false; isSaveButton = true;
    ListViewDetails; isProductSelected = true; isValueSearched = false; labelName = 'Search Product';
    placeHolderVal = 'Search Product....'; schemeTypeData = []; tempIndex = null;
    schemeData; buyProData = []; excludeDta = []; originalExc = []; isExclude = false; excIds = []; excProCatId; excludedId;
    
    isMapRegion = false; isArea = false; isRegion = false; isCustomer = false
    connectedCallback() {
        this.isPageLoaded = true;
        this.disablePullToRefresh();
        this.productsToShow = [];
        //this.addRow(); // ensure at least one row on load
        this.getDataOnload(false);
    }

    getDataOnload(dependPickList){
        
        this.isSubPartLoaded = true;
        ALL_DATA({
            recordId : this.recordId
        })
        .then(result => {
            this.excIds = [];
            this.originalProductData = result.allProductsCat;
            this.allCategory = result.allCategory;
            this.ListViewDetails = result.ListViewDetails;
            //alert(JSON.stringify(result.salesChannelPicklist));
            this.salesChannelOptions = result.salesChannelPicklist.map(channel => ({
                label: channel,
                value: channel
            }));
            if(this.recordId == undefined)
                this.addRow();
            else if(this.recordId != undefined){
                this.schemeData = result.scheme;
                this.buyProData = result.buyPro;
                if(result.scheme.Scheme_Type__c == 'Product'){
                    this.allProductData = result.allProducts;
                    this.schemeTypeData = this.allProductData;
                }
                else{
                    this.schemeTypeData = this.allCategory;
                }
                
                this.addDataInRows();
                const excData = result.excId != undefined ? result.excId : [];
              
                for(var i = 0; i < excData.length; i++){
                    const dt={
                        id:this.values.schemeType == 'Product' ? excData[i].Product__c : excData[i].Category__c,
                        recordId : excData[i].Id
                    };
                    this.excIds.push(dt);
                }
                this.isDisable.exc = false;
                this.excludedId = result.excData != undefined ? result.excData.Id : null;
                
            }
            if(dependPickList){
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
    addDataInRows(){
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
        this.productsToShow = buyPro.map(item => ({
            Id: item.Id,
            proId: item.Product__c,
            catId: item.Category__c,
            searchValueDta: item.Product__c !== undefined ? item.Product__r.Name : item.Category__r.Name,
            buyQuantity: item.Buy_Quantity__c,
            buyValue: item.Buy_Value__c,
            offerQuantity: item.Offer_Quantity__c,
            offerValue: item.Offer_Value__c,
            offerPercent: item.Offer_Percent__c,
            min: item.Min__c,
            max: item.Max__c,
            isValueSearched: false,
            isDisableFields: false,
            showDataDropDown: [],

            salesChannel: item.Sales_Channel__c || '',
            schemeType: item.Scheme_Type__c || '',
            isDisableSalesChannel: false,
            isDisableSchemeType: true,

            isBuyQnt : item.Buy_Quantity__c != 0 ? false : true,
            // isBuyVal : item.Buy_Value__c != 0? false : true,
            isBuyVal : item.Sale_Value__c != 0? false : true,
            isOfferQnt : item.Offer_Quantity__c != 0? false : true,
            isOfferVal : item.Offer_Value__c != 0? false : true,
            isOfferPer : item.Offer_Percent__c != 0? false : true,
            isMin : item.Min__c != 0? false : true,
            isMax : item.Min__c != 0? false : true,
            showCrossButton : true,

            Discount : item.Discount__c != 0 ? item.Discount__c : 0,
            SaleValue : item.Sale_Value__c != 0 ? item.Sale_Value__c : 0,
            PerKg : item.Sale_Value_Threshold__c != 0 ? item.Sale_Value_Threshold__c : 0,
            isDiscount : item.Discount__c != 0 ? false : true,
        }));
        this.isDisable.subLineItems = false;
       // this.isDisable.isButton = false;
        this.isDisable.proCat = true;
    }
    addRow(){
        var dta = this.productsToShow;
        dta.push({
            Id : '',
            proId : '',
            catId : '',
            searchValueDta : '',
            buyQuantity: 0,
            buyValue: 0,
            offerQuantity: 0,
            offerValue: 0,
            offerPercent: 0,
            min: 0,
            max: 0,
            salesChannel: '',
            schemeType: '',
            isDisableSalesChannel: false,
            isDisableSchemeType: true,
            isDisableFields: true,
            isValueSearched : false,
            isDisableFields : true,
            showDataDropDown : [],
            isBuyQnt : true,
            isBuyVal : true,
            isOfferQnt : true,
            isOfferVal : true,
            isOfferPer : true,
            isMin : true,
            isMax : true,
            showCrossButton : false,

            Discount : 0,
            SaleValue : 0,
            PerKg : 0,
            isDiscount : true,
        });
        if(this.values.schemeType == 'Product'){
            this.isDisable.subLineItems = this.values.proCatId  == '' ? true : false;
        }
        else if(this.values.schemeType == 'Category'){
            this.isDisable.subLineItems = false;
        }
        
        this.productsToShow = dta;
    }


    handleCloneRow(event) {
    const index = event.currentTarget.dataset.index;
    const rowData = this.productsToShow[index];

    // Clone the previous row data
    const clonedRow = { ...rowData };  // Spread operator to clone the object

    // Reset fields that should be unique for each row (e.g., Id, Disabled Fields, etc.)
    clonedRow.Id = '';  // Reset the Id for the new row
    clonedRow.isDisableFields = false;  // Enable the row for editing
    clonedRow.showCrossButton = true; 
    clonedRow.proId = null;
    clonedRow.searchValueDta = ''; // Show delete icon

    // Add the cloned row to the products array
    this.productsToShow.push(clonedRow);
    this.productsToShow = [...this.productsToShow]; // Trigger reactivity
}


    handleProductVal(event) {
    const index = parseInt(event.target.dataset.index, 10);
    const fieldName = event.target.name; 
    const value = event.target.value;
    const product = this.productsToShow[index];
    product[fieldName] = value;

    if (fieldName === 'salesChannel') {
        product.salesChannel = value;
        product.isDisableSchemeType = false;
    } 
    else if (fieldName === 'schemeType') {
    product.schemeType = value;

    // Reset all fields to disabled first
    product.isBuyQnt = true;
    product.isBuyVal = true;
    product.isOfferQnt = true;
    product.isDiscount = true;
    product.isMin = true;
    product.isMax = true;

    // Enable fields based on scheme type
    if (value === 'Free Quantity') {
        product.isBuyQnt = false; // Free Qty
        product.isMin = false;    // Min
    } 
    else if (value === 'Sale Value Discount') {
        product.isBuyVal = false; // SaleValue (%)
        product.isOfferQnt = false; // PerKg (Threshold)
    } 
    else if (value === 'Per Quantity Off') {
        product.isOfferQnt = false; // Threshold Value (PerKg)
        product.isDiscount = false; // Discount
        // Ensure Sale Value is disabled
        product.isBuyVal = true;
    }
}
    else {
        //this.disableFieldsCretria(fieldName, value, index);
    }

    this.productsToShow[index] = { ...product }; // trigger reactivity
}
    
    disableFieldsCretria(fieldName,value,index){
        const intVal = parseInt(value,10);
        if(fieldName == 'buyQuantity'){
            if(intVal != 0 && value != ''){
                this.productsToShow[index].isBuyVal = true;
                this.productsToShow[index].isDiscount = true;
            }
            else{
                this.productsToShow[index].isBuyQnt = false;
                this.productsToShow[index].isBuyVal = false;
                this.productsToShow[index].isDiscount = false;
            }
        }
        else if(fieldName == 'SaleValue' || fieldName == 'PerKg') {
            if(intVal != 0 && value != ''){
                this.productsToShow[index].isBuyQnt = true;
                this.productsToShow[index].isDiscount = true;
            }
            else {
                this.productsToShow[index].isBuyQnt = false;
                this.productsToShow[index].isBuyVal = false;
                this.productsToShow[index].isDiscount = false;
            }
        }
        else if(fieldName == 'Discount' && value != ''){
            if(intVal != 0){
                this.productsToShow[index].isBuyQnt = true;
                this.productsToShow[index].isBuyVal = true;
            }
            else{
                this.productsToShow[index].isBuyQnt = false;
                this.productsToShow[index].isBuyVal = false;
            }
        }
        else if(fieldName == 'min'){
            if(intVal != 0){
                this.productsToShow[index].isBuyVal = true;
                this.productsToShow[index].isDiscount = true;
            }
            else{
                this.productsToShow[index].isBuyQnt = false;
                this.productsToShow[index].isBuyVal = false;
                this.productsToShow[index].isDiscount = false;
            }
        }
    }
    
    handleClear(event){
        const index = parseInt( event.currentTarget.dataset.index, 10);
        const fieldName = event.currentTarget.dataset.name; 
        //const value = event.target.value; 
        this.productsToShow[index][fieldName] = 0;
        this.disableFieldsCretria(fieldName,0,index);
    }
    handleSearchPro(event) {
        const index = event.target.dataset.index;
        const searchText = event.target.value;
        const product = this.productsToShow[index];
      
        // 1. VALIDATE SALES CHANNEL IS SELECTED
        if (!product.salesChannel) {
          this.genericToastDispatchEvent("Error", "Select Sales Channel first!", "error");
          return;
        }
        if (!searchText.trim()) {
            this.productsToShow[index].isValueSearched = false;
            this.productsToShow[index].showDataDropDown = [];
            return;
        }
      
        // 2. FETCH PRODUCTS VIA APEX (ONLY ONCE)
        if (!this.allProductData || this.allProductData.length === 0) {
          PROD_DATA({ salesChannel: product.salesChannel })
            .then(data => {
              this.allProductData = data.allProducts; // Cache products
              this.filterAndDisplayProducts(index, searchText);
            })
            .catch(error => console.error(error));
        } else {
          this.filterAndDisplayProducts(index, searchText);
        }
      }
      
      // Helper: Filter products by search text
      filterAndDisplayProducts(index, searchText) {
        const filteredProducts = this.allProductData.filter(p => 
          p.Name.toLowerCase().includes(searchText.toLowerCase())
        );
        
        this.productsToShow[index].showDataDropDown = filteredProducts;
        this.productsToShow[index].isValueSearched = true;
      }
    
    
    handleSearch(event){
        this.values.searchValueDta = event.target.value;
        if(this.values.searchValueDta){
            var storeData = this.searchText(this.originalProductData,this.values.searchValueDta);
            this.isValueSearched = storeData != 0 ? true : false;
            this.values.searchedObjData = storeData;
       }else{
            this.values.proCatId = '';
            this.isDisable.subLineItems = true;
            this.productsToShow = [];
            this.addRow();
       } 
    }
    searchText(objData,serchTxt){
        if(objData == undefined) return;
        return objData.filter(obj => obj.Name && obj.Name.toLowerCase().includes(serchTxt.toLowerCase()));
    }
    handleOnBlur(){
        setTimeout(() => {
            this.isValueSearched = false;
            if(this.tempIndex != null){
                this.productsToShow[this.tempIndex].showDataDropDown = [];
                this.productsToShow[this.tempIndex].isValueSearched = false;
                this.tempIndex = null;
            }
                
        }, 1000);
    }
    handleSchemeType(event) {
        this.dependencyPickList(event.target.value);
        this.productsToShow = [];
        if(event.target.value == 'Product'){
            this.labelName = 'Search Product';
            this.placeHolderVal = 'Search Product....';
            this.schemeTypeData = this.allProductData;
            this.isProductSelected = true;
            this.isDisable.exc = true;
        }else{
            this.labelName = 'Search Category';
            this.placeHolderVal = 'Search Category....';
            this.schemeTypeData = this.allCategory;
            this.isProductSelected = false;
            this.isDisable.exc = false;
        }
        this.addRow();
    }
    dependencyPickList(val){
        let key = this.options.appliesToData.controllerValues[val];
        this.options.appliesTo = this.options.appliesToData.values.filter(opt => opt.validFor.includes(key));
        this.values.appliesTo = '';
        this.isDisable.appliesTo =false;
        this.values.schemeType = val;
    }
    handleChangeValues(event){
        this.values[event.target.name] = event.target.value;
    }
    handleSave(){
        const {name,startDate,endDate,schemeType,appliesTo,proCatId, Description} = this.values;
        let missingFields = [];

        if (!name) missingFields.push("Name");
        if (!startDate) missingFields.push("Start Date");
        if (!endDate) missingFields.push("End Date");
        if (!schemeType) missingFields.push("Scheme Type");
        if (!appliesTo) missingFields.push("Applies To");
        if(!Description) missingFields.push("Description")

        if (missingFields.length > 0) {
            const errorMessage = `Please fill ${missingFields.join(", ")}`;
            this.genericToastDispatchEvent("Error", errorMessage, "error");
            return;
        }
        const storData = this.productsToShow;
        if(this.validateFields(0,this.productsToShow.length - 1)){
            return;
        }
        
        for(let i=0;i<this.productsToShow.length;i++){
            // this.productsToShow[i].isValueSearched = true;
            // this.productsToShow[i].isDisableFields = true;
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
            Id : this.recordId,
            Applies_to__c : appliesTo,
            Scheme_End_Date__c : endDate,
            Name : name,
            Scheme_Start_Date__c : startDate,
            Scheme_Type__c : schemeType,
            IsActive__c : true,
            Product_Category__c : proCatId,
            Description__c : Description,
        }
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
        
            // ➕ Newly added fields
            Sales_Channel__c: item.salesChannel,
            Scheme_Type__c: item.schemeType
        }));
        
       
        this.productsToShow = this.productsToShow.map(item => ({ ...item, isDisableFields: true }));
        SAVE_DATA({ 
            ProductBuy, 
            schemeDta,
            proCatId,
            excProCatId : this.excProCatId,
            excludedId : this.excludedId
         })
        .then(data => {
            this.recordId = data;
            this.isDisable.isButton = false;
            this.isDisable.proCat = true;
            this.isDisable.subLineItems = true;
            this.isSaveButton = false;
            this.isDisable.isDisableAction = true;
            var dt = this.productsToShow;
            for(let i = 0; i < dt.length; i++){
                dt[i].isDisableAction = true;
            }
            this.productsToShow = dt;
            this.genericToastDispatchEvent("Success", "Scheme Created Successfully", "success");
        })
        .catch(error => {
            this.isDisable.allFields = false;
            console.log(error);
        });
    }
    handlePrevious(){
        this.refreshData();
    }
    refreshData(){
        // this.dependencyPickList('Product');
        this.values.startDate = '';
        this.values.endDate = '';
        this.values.name = '';
        this.isSaveButton = true;
        this.isDisable.allFields = true;
        this.isDisable.appliesTo = true;
        this.getDataOnload(true);
    }
    handleDone(){
        const msg = {
            message: 'Done',
            id : this.recordId   
        }
        this.genericDispatchEvent('ClickAction', msg);
    }
    handleCancel() {
        const msg = {
            message: 'close',
            id : this.ListViewDetails.Id   
        }
        this.genericDispatchEvent('ClickAction', msg);
    }
    
    selectObjName(event){
        this.values.proCatId = event.currentTarget.dataset.id;
        this.values.searchValueDta = event.currentTarget.dataset.name;
        this.isValueSearched = false;
        this.getProductData();
    }

    selectProName(event){
        const index = parseInt(event.currentTarget.dataset.index, 10);
    const productId = event.currentTarget.dataset.id;
    
    // Check for duplicates before assigning
    const isDuplicate = this.productsToShow.some((prod, i) => 
        i !== index && 
        prod.schemeType === this.productsToShow[index].schemeType && 
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
        if(this.values.schemeType == 'Product'){
            this.productsToShow[index].proId = event.currentTarget.dataset.id;
        }
        else if(this.values.schemeType == 'Category'){
            this.productsToShow[index].catId = event.currentTarget.dataset.id;
        }
        this.productsToShow[index].isValueSearched = false;
this.productsToShow[index].isDisableFields = false;
this.productsToShow[index].showCrossButton = true;

// Call same field enable logic based on schemeType
const schemeType = this.productsToShow[index].schemeType;
this.handleProductVal({
    target: {
        name: 'schemeType',
        value: schemeType,
        dataset: { index }
    }
});
    }
    handleAddRow(event){
        const index = parseInt(event.currentTarget.dataset.index, 10);
        if(this.validateFields(index,index))
            return;

        this.addRow();
    }
    handleRemoveRow(event){
        const index = parseInt(event.currentTarget.dataset.index, 10);
        var removeDta;
        if (index !== undefined && this.productsToShow.length > index) {
            removeDta = this.productsToShow[index];
            this.productsToShow.splice(index, 1);
            this.productsToShow = [...this.productsToShow]; // Refresh array to trigger reactivity
        } 
        if(removeDta != null){
            if(removeDta.Id == '')
                return;
            const itemId = removeDta.Id
            deleteRecord(itemId)
            .then(() => {
                
                this.genericToastDispatchEvent('Success', 'Deleted successfully', 'success');
            })
            .catch(error => {
                console.log(error);
                //this.showToast('Error', `Error deleting Competition: ${error.body.message}`, 'error');
            });
        } 
        if(this.productsToShow.length == 0){
            this.addRow();
        }  
    }
    validateFields(i, j) {
        for (let k = i; k <= j; k++) {
            const dta = this.productsToShow[k];
            const { schemeType } = this.values;
    
            const fieldValidations = [
                { condition: schemeType === 'Product' && !dta.proId , message: 'Please Select Product' },
                { condition: schemeType === 'Category' && !dta.catId, message: 'Please Select Category' },

                { condition: dta.buyQuantity == 0 && dta.min == 0 &&  dta.SaleValue == 0 && dta.PerKg == 0 && dta.Discount == 0, message: 'Please enter Values' },

                { condition: dta.buyQuantity == 0 && dta.min != 0, message: 'Please enter Free Quantity' },
                { condition: dta.buyQuantity != 0 && dta.min == 0, message: 'Please enter Min Value' },

                { condition: dta.SaleValue != 0 && dta.PerKg == 0, message: 'Please enter Per Kg' },
                
            ];
            
            for (const { condition, message } of fieldValidations) {
                if (condition) {
                    this.genericToastDispatchEvent("Error", message, "error");
                    return true;
                }
            }
        }
        for (let k = i; k <= j; k++) {
            this.productsToShow[k].buyQuantity =  this.productsToShow[k].buyQuantity != '' ?  this.productsToShow[k].buyQuantity : 0;
            this.productsToShow[k].min =  this.productsToShow[k].min != '' ?  this.productsToShow[k].min : 0;
            this.productsToShow[k].SaleValue =  this.productsToShow[k].SaleValue != '' ?  this.productsToShow[k].SaleValue : 0;
            this.productsToShow[k].PerKg =  this.productsToShow[k].PerKg != '' ?  this.productsToShow[k].PerKg : 0;
            this.productsToShow[k].Discount =  this.productsToShow[k].Discount != '' ?  this.productsToShow[k].Discount : 0;
        }
        return false;
    }    
    getProductData(){
        alert(product.salesChannel);
        if(this.values.proCatId == '')
            return;
        this.isSubPartLoaded = true;
        PROD_DATA({
            salesChannel: product.salesChannel // Pass the selected sales channel
        })
        .then(data => {
            this.allProductData = data.allProducts;
            this.schemeTypeData = this.allProductData;
        })
        .catch(error => {
            console.error('Error loading products', error);
        });
    }
    excludePro(){

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
        for(let i=0; i<this.originalExc.length; i++){
            if(this.excludeDta[index].Id == this.originalExc[i].Id){

                this.originalExc[i].isCheckBox = event.target.checked;
                break;
            }

        }
    }
    saveExcludePro(){
        var createId = [];
        for (let i = 0; i < this.excludeDta.length; i++) {
            if (this.excludeDta[i].isCheckBox && this.excludeDta[i].recordId == null) {
                const dt = {
                    Product__c : this.values.schemeType == 'Product' ? this.excludeDta[i].Id : null,
                    Category__c : this.values.schemeType == 'Category' ? this.excludeDta[i].Id : null,
                }
                createId.push(dt);
            }
        }
        var deleteId = [];
        if(this.recordId != undefined){
            for (let i = 0; i < this.excludeDta.length; i++) {
                if (!this.excludeDta[i].isCheckBox && this.excludeDta[i].recordId != null)  {
                    
                    deleteId.push(this.excludeDta[i].recordId);
                }
            }
        }
        
       // const storeIds = this.excIds.map(id => ({ Product__c: id }));
        if(createId.length == 0 && this.recordId == undefined){
            this.genericToastDispatchEvent("Error", "Please select atleast one product", "error");
            return;
        }
        
        this.isDisable.isExclude = true;
        SAVEEXC_DATA({
            prodCatId : this.values.proCatId ,
            exc : createId,
            exId : this.excludedId,
            deleteId : deleteId
        })
        .then(result => {
            this.excIds = [];
            const excData =result.excId;
              
            for(var i = 0; i < excData.length; i++){
                const dt={
                    id:this.values.schemeType == 'Product' ? excData[i].Product__c : excData[i].Category__c,
                    recordId : excData[i].Id
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
    closeExcludePopup(){
        this.isExclude = false;
    }
    handleMapAll(){
        this.isMapRegion = true;
        this.isArea = true; 
        this.isRegion = true; 
        this.isCustomer = true;
    }
    handleMapRegion(){
        this.isMapRegion = true;
        this.isArea = false; 
        this.isRegion = true; 
        this.isCustomer = false;
    }
    handleMapArea(){
        this.isMapRegion = true;
        this.isArea = true;  
        this.isRegion = false; 
        this.isCustomer = false;
    }
    handleMapCustomerCategory(){
        this.isMapRegion = true;
        this.isArea = false; 
        this.isRegion = false; 
        this.isCustomer = true;
    }
    onclickFun(event){
        const msg = event.detail;
        if(msg.message == "mapRegion_close"){
            this.isMapRegion = false;
            this.isArea = false; 
            this.isRegion = false; 
            this.isCustomer = false;
        }
        if(msg.message == "mapRegion_Save"){
            this.isMapRegion = false;
            this.isArea = false; 
            this.isRegion = false; 
            this.isCustomer = false;
            this.genericToastDispatchEvent('Success', 'Mapping Saved', 'success');
        }
    }

    handleSearchExclude(event){
        const val = event.target.value;
        this.values.searchExc = val;
        if(val != ''){

            var serchedDta = this.originalExc.filter(obj => obj.Name && obj.Name.toLowerCase().includes(val.toLowerCase()));
            //this.searchText(this.originalData,val);
            this.excludeDta = serchedDta;
        }else{
            this.excludeDta = this.originalExc;
        }
    }
    genericDispatchEvent(eventName, msg) {
        // Creating a custom event with a dynamic name and payload
        const event = new CustomEvent(eventName, { 
            detail : msg
         });
    
        // Dispatching the event
        this.dispatchEvent(event);
    }
    genericToastDispatchEvent(title,message,variant){
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant
            })
        );
    }
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
    
}