import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

//Apex class
import ALL_DATA from '@salesforce/apex/SalesStrategyLwc.getAllData';
import SAVE_DATA from '@salesforce/apex/SalesStrategyLwc.saveData';

export default class SalesStrategy extends LightningElement {

    @api recordId;
    @api header;

    @track regionName = '';
    @track salesProductCategoryData = [];
    @track salesProductData = [];
    @track salesCustomerData = [];
    @track salesAreaData = [];
    @track value = {
        proCat : '',
        pro : '',
        cust : '',
        area : '',
        regionData : []
    };

    originalData = {
        proCat : [],
        pro : [],
        cust : [],
        area : [],
        totalPro : []
    };
    listView;

    @track isDisable = {
        allFields : false,
    } 
    salesProData = []; customerType; salesRegion = [];

    isPageLoaded = false;

    @track salesStartegy = {
        Name : '',
        Customer_type__c : '',
        Region__c : ''
    }
    connectedCallback(){
        this.getDataOnLoad();
    }

    getDataOnLoad(){
        this.isPageLoaded = true;
        ALL_DATA({ recordId: this.recordId })
        .then(result => {
            this.salesProductCategoryData = result.salesProductCategoryData;
            this.salesProductData = this.recordId != undefined ? result.salesProductData : [];
            this.salesCustomerData = result.salesCustomerData;
            this.salesAreaData = result.salesAreaData;
            this.salesProData = result.salesAllProductData;
            this.listView = result.ListViewDetails.Id;
            this.originalData = {
                proCat : this.salesProductCategoryData,
                pro : this.salesProductData,
                cust : this.salesCustomerData ,
                area : this.salesAreaData,
                totalPro : result.salesAllProductData,
                region : result.region
            };
            var cat = [];
            const categoryType = result.customerType;
            for (let i = 0; i < categoryType.length; i++) {
                cat.push({
                    label: categoryType[i],
                    value: categoryType[i]
                });
            }
            this.customerType = cat;
            //this.regionData = result.region;
            if(this.recordId != undefined){
                this.salesRegion = result.salesRegion;
                this.salesStartegy = {
                    Name : this.salesRegion.Name,
                    Customer_type__c : this.salesRegion.Customer_type__c,
                    Region__c : this.salesRegion.Region__c
                }
                this.regionName = this.salesRegion.Region__r.Name
            }
            this.isPageLoaded = false;
        })
        .catch(error => {
            console.log(error);
            this.isPageLoaded = false;
        });
    }
    handleOnBlur(){
        setTimeout(() => {
            this.value.regionData = [];                
        }, 1000);
    }
    handleSearchRegion(event){
        const val = event.target.value;
        this.regionName = val;
        if(val != ''){

            var serchedDta = this.originalData.region.filter(obj => obj.Name && obj.Name.toLowerCase().includes(val.toLowerCase()));
            //this.searchText(this.originalData,val);
            this.value.regionData = serchedDta;
        }else{
            this.value.regionData = [];
            this.salesStartegy.Region__c = '';
        }
    }
    selectObjName(event){
        this.salesStartegy.Region__c = event.currentTarget.dataset.id;
        this.regionName = event.currentTarget.dataset.name;
        this.value.regionData = [];
    }
    handleSchemeType(event) {
        this.salesStartegy[ event.target.name] =  event.target.value;
    }
    handleSearchProCat(event){
        this.value[event.target.name] = event.target.value;
        if(event.target.value == '')
            this.salesProductCategoryData = this.originalData.proCat;
        
        else if(event.target.value.length > 1){
            var dta = this.searchText('productCategoryName',this.originalData.proCat, event.target.value);
            this.salesProductCategoryData = dta;
        }
    }
    handleSearchPro(event){
        this.value[event.target.name] = event.target.value;
        if(event.target.value == '')
            this.salesProductData = this.originalData.pro;
        
        else if(event.target.value.length > 1){
            var dta = this.searchText('productName',this.originalData.pro, event.target.value);
            this.salesProductData = dta;
        }
    }
    handleSearchCus(event){
        this.value[event.target.name] = event.target.value;
        if(event.target.value == '')
            this.salesCustomerData = this.originalData.cust;
        
        else if(event.target.value.length > 1){
            var dta = this.searchText('customerName',this.originalData.cust, event.target.value);
            this.salesCustomerData = dta;
        }
    }
    handleSearchArea(event){
        this.value[event.target.name] = event.target.value;
        if(event.target.value == '')
            this.salesAreaData = this.originalData.area;
        
        else if(event.target.value.length > 1){
            var dta = this.searchText('areaName',this.originalData.area, event.target.value);
            this.salesAreaData = dta;
        }
    }
    searchText(fieldName, objData, searchTxt) {
        if (!objData || !fieldName) return [];
        
        return objData.filter(obj => 
            obj[fieldName] && obj[fieldName].toLowerCase().includes(searchTxt.toLowerCase())
        );
    }
    handleCheckBoxProCat(event) {
        const index = parseInt(event.currentTarget.dataset.index, 10);
        this.salesProductCategoryData[index].isSaveDt = event.target.checked;
        
        const proCatID = event.currentTarget.dataset.procatid;
        const pro = this.originalData.totalPro;
    
        // Copy existing data to avoid mutating original reference
        let dta = [...this.originalData.pro];
    
        if (event.target.checked) {
            // Add products matching the category ID
            const matchedProducts = pro.filter(item => item.productCategoryId === proCatID);
            dta = [...dta, ...matchedProducts];
        } else {
            // Remove products matching the category ID
            dta = dta.filter(item => item.productCategoryId !== proCatID);
        }
    
        this.originalData.pro = dta;
        this.salesProductData = dta;
        for(let i=0;i<this.originalData.proCat;i++){
            if(this.originalData.proCat[i].productCategoryId == proCatID){
                this.originalData.proCat[i].isSaveDt = event.target.checked;
                break;
            }
        }

    }
    handleCheckBoxPro(event) {
        const index = parseInt(event.currentTarget.dataset.index, 10);
        this.salesProductData[index].isSaveDt = event.target.checked;
    
        const proId = event.currentTarget.dataset.proid;
    
        const product = this.originalData.pro.find(item => item.productCategoryId === proId);
        if (product) {
            product.isSaveDt = event.target.checked;
        }
    }

    handleCheckBoxCus(event) {
        const index = parseInt(event.currentTarget.dataset.index, 10);
        this.salesCustomerData[index].isSaveDt = event.target.checked;
    
        const cusId = event.currentTarget.dataset.cusid;
    
        const cust = this.originalData.cust.find(item => item.customerId === cusId);
        if (cust) {
            cust.isSaveDt = event.target.checked;
        }
    }
    handleCheckBoxArea(event) {
        const index = parseInt(event.currentTarget.dataset.index, 10);
        this.salesAreaData[index].isSaveDt = event.target.checked;
    
        const areaId = event.currentTarget.dataset.areaid;
    
        const area = this.originalData.pro.find(item => item.areaId === areaId);
        if (area) {
            area.isSaveDt = event.target.checked;
        }
    }        
    handleSave() {
        const { proCat, pro, cust, area } = this.originalData;
        const { Name, Customer_type__c, Region__c } = this.salesStartegy;
        var proCatDt = [], proDt = [], custDt = [], areaDt = [];
        var proCatDel = [], proDel = [], custDel = [], areaDel = [];
    
        if(Name == ''){
            this.genericToastDispatchEvent('', 'Please enter name to save.', 'error');
            return;
        }
        if(Customer_type__c == ''){
            this.genericToastDispatchEvent('', 'Please enter Customer type to save.', 'error');
            return;
        }
        if(Region__c == ''){
            this.genericToastDispatchEvent('', 'Please enter Region.', 'error');
            return;
        }

        if (!proCat.some(item => item.isSaveDt)) {
            this.genericToastDispatchEvent('', 'Please select at least one product category to save.', 'error');
            return;
        }
    
        proCat.forEach(item => {
            if (item.isSaveDt  ) {
                if(item.salesProductCategories == ''){
                    const dt={
                        Product_Category__c : item.productCategoryId
                    };
                    proCatDt.push(dt);
                }
                else if(item.salesProductCategories != ''){
                    const dt={
                        Product_Category__c : item.productCategoryId,
                        Id : item.salesProductCategories
                    };
                    proCatDt.push(dt);
                }
            } 
            if (!item.isSaveDt && this.recordId != undefined && item.salesProductCategories != '') {
                proCatDel.push(item.salesProductCategories);
            }
        });

        // if (!pro.some(item => item.isSaveDt)) {
        //     this.genericToastDispatchEvent('', 'Please select at least one product to save.', 'error');
        //     return;
        // }
        this.isDisable.allFields = true;
        pro.forEach(item => {
            if (item.isSaveDt  && item.salesProducts == '') {
                const dt={
                    Product_Category__c : item.productCategoryId,
                    Product__c : item.productId
                };
                proDt.push(dt);
            } 
            if (!item.isSaveDt && this.recordId != undefined && item.salesProducts != '') {
                proDel.push(item.salesProducts);
            }
        });

        cust.forEach(item => {
            if (item.isSaveDt && item.salesCustomers == '') {
                const dt ={
                    Customer__c : item.customerId
                };
                custDt.push(dt);
            } 
            if (!item.isSaveDt && this.recordId != undefined && item.salesCustomers != '') {
                custDel.push(item.salesCustomers);
            }
        });

        area.forEach(item => {
            if (item.isSaveDt  && item.salesAreas == '') {
                const dt = {
                    Area__c : item.areaId
                };
                areaDt.push(dt);
            } 
            if (!item.isSaveDt && this.recordId != undefined && item.salesAreas != '') {
                areaDel.push(item.salesAreas);
            }
        });
        
        SAVE_DATA({
            recordId : this.recordId,
            sales : this.salesStartegy,
            proCat : proCatDt,
            pro : proDt,
            cust : custDt,
            area : areaDt,
            proCatDel : proCatDel,
            proDel : proDel,
            custDel : custDel,
            areaDel : areaDel
        })
        .then(result => {
            this.recordId = result;
            const msg = {
                message: 'Done',
                id : this.recordId   
            };
            this.isDisable.allFields = false;
            this.genericDispatchEvent('ClickAction', msg);
        })
        .catch(error => {
            console.log(error);
            this.isDisable.allFields = false;
        });
    }
    
    handleCancel(){
        const msg = {
            message: 'close',
            id : this.listView   
        }
        this.genericDispatchEvent('ClickAction', msg);
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
}