import { LightningElement, track,api } from 'lwc';
import TargetPlanIcon from '@salesforce/resourceUrl/TargetPlanIcon';
import getAllData from '@salesforce/apex/TargetPlanController.getAllData';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import saveData from '@salesforce/apex/TargetPlanController.saveData';
export default class TargetPlan extends LightningElement {
    @api recordId;
    targetPlanIcon = TargetPlanIcon;
    @track logicList = [
        { 
            Id: null, 
            Name:'',
            targetPlan:null,
            index:1,
            targetType: '', 
            formula: '', 
            object: '', 
            field: '',
            weightage:'',
            maxIncentive:'',
            formulaOptions: [],
            objectOptions: [],
            fieldOptions: [],
            isFormulaDisabled: true,
            isObjectDisabled: true,
            isFieldDisabled: true,
            isShowProductCategory:false,
            isShowProduct:false,
            isShowAccountType:false,
            isDisabledfield:true,
            isShowProductCategoryValues:false,
            isShowProductValues:false,
            productCategoryName:'',
            productCategoryId:null,
            sellingCategoryName:'',
            sellingCategoryId:null,
            isShowSellingCategoryValues:false,
            isShowSellingCategory:false,
            sellingCategoryDisable:true,
            productId:null,
            productName:'',
            accountType:'',
            productCategoryDisable:true,
            prouctDisable:true,
            accountTypeDisable:true,
            productCatDataId:'Product_Category'+0,
            productDataId:'Product'+0,
            sellingCatDataId:'Selling_Category'+0

        }
    ];

    @track wagelist = [
        { Id: null,targetPlan:null,index:1, waFrom: null, waTo: null, incentivePercentage: null, incentiveAmount:null },
    ];
    @track targetPlan = {Id:null,Division__c: '', Region__c: '', Incentive_Type__c: '',Slab_Applied_At__c :'' ,Active__c:false};
    @track deleteLogicsList = [];
    @track deleteSlabsList = [];

    isLoading = false;
    AccountTypeOptions = [];
    targetTypeOptions = [];
    regionOptions = [];
    divisionOptions = [];
    incentiveTypeOptions = [];
    products=[];
    SearchedProduct = [];
    productCategories=[];
    SearchedProductCategoryData = [];
    sellingCategories = [];
    searchedSellingCategoryData = [];

    targetTypeformulaMap = {};
    formulaObjectMap = {};
    objectFieldMap = {};
    toggleclass='input__toggle';

    connectedCallback() {
        this.getAllData();
    }
    getAllData() {
        this.isLoading = true;
        getAllData({recordId:this.recordId})
            .then(data => {
                this.productCategories = data.productCategoryList || [];
                this.sellingCategories = data.sellingCategoryList || [];
                this.products = data.productList || [];
                this.regionOptions = this.getPicklistValues(data.regionList || []);
                this.divisionOptions = this.getPicklistValues(data.divisionList || []);
                this.incentiveTypeOptions = data.incentiveType || [];
                this.targetTypeOptions = data.targetType || [];
                this.AccountTypeOptions = data.accountType || [];

                this.targetTypeformulaMap = data.targetTypeObjectMap || {};
                this.formulaObjectMap = data.formulaObjectMap || {};
                this.objectFieldMap = data.objectFieldMap || {};

                if (this.recordId) {
                    var targetPlanData = data.targetPlan;
                    console.log('values Taget Plan'+JSON.stringify(targetPlanData));
                    this.targetPlan = {
                        Id: targetPlanData?.Id || '',
                        Division__c: targetPlanData?.Division__c || '',
                        Region__c: targetPlanData?.Region__c || '',
                        Incentive_Type__c: targetPlanData?.Incentive_Type__c || '',
                        Slab_Applied_At__c:targetPlanData?.Slab_Applied_At__c || '',
                        Active__c: targetPlanData?.Active__c ?? false
                    };
                    this.toggleclass= targetPlanData.Active__c ? 'togglechecked':'input__toggle';
                    this.logicList = data.targetLogicList.map((logic, index) => {
                        let updatedItem = {
                            Id: logic.Id, 
                            Name:logic.Name,
                            index: index + 1,
                            productCatDataId:'Product_Category'+index,
                            productDataId:'Product'+index,
                            sellingCatDataId:'Selling_Category'+index,
                            targetPlan:logic.Target_Plan__c || null, 
                            targetType: logic.Target_Type__c || '', 
                            formula: logic.Formula__c || '', 
                            object: logic.Object__c || '', 
                            field: logic.Field__c || '',
                            weightage:logic.Weightage__c,
                            maxIncentive:logic.max_incentive__c,
                            formulaOptions: this.getOptionsList(this.targetTypeformulaMap[logic.Target_Type__c] || []),
                            objectOptions: this.getOptionsList(this.formulaObjectMap[logic.Formula__c] || []),
                            fieldOptions: this.getOptionsList(this.objectFieldMap[logic.Object__c] || []),
                            isFormulaDisabled: false,
                            isObjectDisabled: false,
                            isFieldDisabled: false,
                            isShowProductCategoryValues: false,
                            isShowProductValues: false,
                            isShowSellingCategoryValues:false,
                            productCategoryName: logic.Product_Category__r?.Name || '',
                            productCategoryId: logic.Product_Category__c || null,
                            sellingCategoryName:logic.Selling_Category__r?.Name || '',
                            sellingCategoryId:logic.Selling_Category__c || null,
                            productId: logic.Product__c || null,
                            productName: logic.Product__r?.Name || '',
                            accountType: logic.Account_Type__c,
                            productCategoryDisable: false,
                            prouctDisable: false,
                            accountTypeDisable: false,

                        };
                
                        // Call updateFieldVisibility to set visibility fields
                        this.updateFieldVisibility(updatedItem, logic.Target_Type__c);
                
                        return updatedItem;
                    });
                    this.wagelist = data.incentiveSlabList.map((slab, index) => {
                        let updatedItem = {
                            Id: slab.Id, 
                            index: index + 1,
                            waFrom: slab.Achievement_From__c || '', 
                            waTo: slab.Achievement_To__c || '', 
                            incentivePercentage: slab.Incentive_Percentage__c || 0, 
                            incentiveAmount: slab.Incentive_Amount__c || 0, 
                        };
                        return updatedItem;
                    });
                }
                this.isLoading = false;
            })
            .catch(error => {
                this.isLoading = false;
                this.showToast('Error', `Error fetching data: ${error.body?.message || JSON.stringify(error)}`, 'error');
            });
    }
    handleInputChnage(event) {
        const value = event.detail.value;
        const field = event.target.name;
        if (field === 'Division') {
            this.targetPlan.Division__c =value;
        }
        else if(field === 'Region'){
            this.targetPlan.Region__c =value;
        }
        else if(field === 'IncentiveType'){
            this.targetPlan.Incentive_Type__c =value;
        }
        else if(field === 'slabAppliedAt'){
            this.targetPlan.Slab_Applied_At__c =value;
        }
        else if(field === 'toggle')
        {
            this.toggleclass= event.target.checked ? 'togglechecked' : 'input__toggle';
            this.targetPlan.Active__c = event.target.checked ;
        }

      
    }
    handleInputLogicChange(event) {
        const index = event.target.dataset.index;
        const field = event.target.name;
        const value = event.detail.value;

        this.logicList = this.logicList.map((item, i) => {
            if (i == index) {
                let updatedItem = { ...item, [field]: value };
               
                if (field === 'targetType') {
                    updatedItem.formula = '';
                    updatedItem.object = '';
                    updatedItem.field = '';
                    updatedItem.formulaOptions = this.getOptionsList(this.targetTypeformulaMap[value] || []);
                    updatedItem.isFormulaDisabled = false;
                    updatedItem.isObjectDisabled = true;
                    updatedItem.isFieldDisabled = true;

                    updatedItem.productCategoryName = '';
                    updatedItem.productCategoryId = null;
                    updatedItem.sellingCategoryName = '';
                    updatedItem.sellingCategoryId = null;
                    updatedItem.productName = '';
                    updatedItem.productId = null;
                    updatedItem.accountType = '';

                    updatedItem.productCategoryDisable = true;
                    updatedItem.prouctDisable = true;
                    updatedItem.sellingCategoryDisable = true;
                    updatedItem.accountTypeDisable = true;

                    this.updateFieldVisibility(updatedItem, value);
                } 
                else if (field === 'formula') {
                    updatedItem.object = '';
                    updatedItem.field = '';
                    updatedItem.objectOptions = this.getOptionsList(this.formulaObjectMap[value] || []);
                    updatedItem.isObjectDisabled = false;
                    updatedItem.isFieldDisabled = true;
                } 
                else if (field === 'object') {
                    updatedItem.field = '';
                    updatedItem.fieldOptions = this.getOptionsList(this.objectFieldMap[value] || []);
                    updatedItem.isFieldDisabled = false;
                }
                else if (field === 'field') {
                    updatedItem.productCategoryDisable = false;
                    updatedItem.prouctDisable = false;
                    updatedItem.sellingCategoryDisable = false;
                    updatedItem.accountTypeDisable = false;
                }

                return updatedItem;
            }
            return item;
        });
    }
    updateFieldVisibility(updatedItem, value) {
        updatedItem.isShowProductCategory = false;
        updatedItem.isShowSellingCategory = false;
        updatedItem.isShowProduct = false;
        updatedItem.isShowAccountType = false;
        updatedItem.isDisabledfield = false;

        if(value =='Category Sales' || value =='Category Sales Quantity'){
            updatedItem.isShowProductCategory = true;
        
        }
        else if(value =='Must Sell SKU' || value =='Focused SKU')
        {
            updatedItem.isShowSellingCategory = true;
        }
        else if(value =='Product Sales' || value =='Product Sales Quantity'){
            updatedItem.isShowProduct = true;
        }
        else if(value=='Number of Visits' || value=='Number of Accounts Created'){
            updatedItem.isShowAccountType = true;
        }
        else{
            updatedItem.isDisabledfield = true;
        }
    }

    handleInputWageChange(event) {
        const index = event.target.dataset.index;
        const field = event.target.name;
        const value = event.detail.value;

        this.wagelist = this.wagelist.map((item, i) => {
            if (i == index) {
                let updatedItem = { ...item, [field]: value };
                return updatedItem;
            }
            return item;
        });
    }
    getOptionsList(optionsMap) {
        return Object.keys(optionsMap).map(label => ({
            label: label, 
            value: optionsMap[label] // Use API value instead of label
        }));
    }
    getPicklistValues(optionsArray) { 
        return optionsArray.map(option => ({ label: option.Name, value: option.Id })); 
    }
    //Logic methods
    addRow() {
        const newRow = {
            Id: null, 
            targetPlan:null,
            index:  this.logicList.length + 1, 
            targetType: '', 
            formula: '', 
            object: '', 
            field: '',
            formulaOptions: [],
            objectOptions: [],
            fieldOptions: [],
            isFormulaDisabled: true,
            isObjectDisabled: true,
            isFieldDisabled: true,
            isShowProductCategory:false,
            isShowProduct:false,
            isShowAccountType:false,
            isDisabledfield:true,
            isShowProductCategoryValues:false,
            isShowProductValues:false,
            ProductCategoryName:'',
            productCategoryId:null,
            productId:null,
            productName:'',
            accountType:'',
            productCategoryDisable:true,
            prouctDisable:true,
            accountTypeDisable:true,
            productCatDataId:'Product_Category'+Number(this.logicList.length),
            productDataId:'Product'+Number(this.logicList.length),
            sellingCatDataId:'Selling_Category'+Number(this.logicList.length)
        };
        this.logicList = [...this.logicList, newRow];
    }
    removeRow(event) {
        const index = Number(event.target.dataset.index);
    
        // If only one row is left, clear its values using querySelector
        if (this.logicList.length === 1) {
            const rowElements = this.template.querySelectorAll(`[data-id="logicFields"]`);
            rowElements.forEach(input => {
                input.value = ''; // Manually clear input fields
            });

            if (this.logicList[index].Id) {
                this.deleteLogicsList = [...(this.deleteLogicsList || []), this.logicList[index].Id];
            }
    
            // Reset the only row instead of deleting it
            this.logicList = [{
                Id: null, 
                index:  this.logicList.length + 1, 
                targetType: '', 
                formula: '', 
                object: '', 
                field: '',
                formulaOptions: [],
                objectOptions: [],
                fieldOptions: [],
                isFormulaDisabled: true,
                isObjectDisabled: true,
                isFieldDisabled: true,
                isShowProductCategory:false,
                isShowProduct:false,
                isShowAccountType:false,
                isDisabledfield:true,
                isShowProductCategoryValues:false,
                isShowProductValues:false,
                ProductCategoryName:'',
                productCategoryId:null,
                productId:null,
                productName:'',
                accountType:'',
                productCategoryDisable:true,
                prouctDisable:true,
                accountTypeDisable:true,
                productCatDataId:'Product_Category'+0,
                productDataId:'Product'+0,
                sellingCatDataId:'Selling_Category'+0
            }];
        } else {
            // Create a copy of wagelist to ensure reactivity
            let updatedList = [...this.logicList];
    
            if (updatedList[index].Id) {
                this.deleteLogicsList = [...(this.deleteLogicsList || []), updatedList[index].Id];
            }
            // Remove the selected row
            updatedList.splice(index, 1);

            // Recalculate index values
            updatedList = updatedList.map((item, i) => ({
            ...item,
            productCatDataId:'Product_Category'+i,
            productDataId:'Product'+i,
            sellingCatDataId:'Selling_Category'+i
            }));
    
            // Assign the updated list to trigger reactivity
            this.logicList = updatedList;
        }
    }
    //Slab methods
    addWageRow(event) {
        const index =event.target.dataset.index;
        let wagelistUpdate = this.wagelist;
        let waFrom = Number( wagelistUpdate[index].waFrom);
        let waTo =  Number(wagelistUpdate[index].waTo);
        console.log('waFrom'+waFrom);
        console.log('waTo'+waTo);
        if(waFrom > waTo)
        {
            this.showToast('Error', 'WA From cannot be greater than WA To', 'error');
            return;
        }

        const newRow = {
            Id:null,
            index:  this.wagelist.length + 1, // Ensure unique ID
            waFrom: null, 
            waTo: null,
            incentivePercentage: null,
            incentiveAmount:null
        };
        this.wagelist = [...this.wagelist, newRow];
    }
    removeWageRow(event) {
        const index = Number(event.target.dataset.index);
    
        // If only one row is left, clear its values using querySelector
        if (this.wagelist.length === 1) {
            const rowElements = this.template.querySelectorAll(`[data-id="wageFields"]`);
            rowElements.forEach(input => {
                input.value = ''; // Manually clear input fields
            });

            if (this.wagelist[index].Id) {
                this.deleteSlabsList = [...(this.deleteSlabsList || []), this.wagelist[index].Id];
            }
    
            // Reset the only row instead of deleting it
            this.wagelist = [{ Id: null, index: 1, waFrom: null, waTo: null, incentivePercentage: null,incentiveAmount:null }];
        } else {
            // Create a copy of wagelist to ensure reactivity
            let updatedList = [...this.wagelist];
    
            if (updatedList[index].Id) {
                this.deleteSlabsList = [...(this.deleteSlabsList || []), updatedList[index].Id];
            }
            // Remove the selected row
            updatedList.splice(index, 1);
    
            // Assign the updated list to trigger reactivity
            this.wagelist = updatedList;
        }
    }

    //Product Category Search 
    handleProductCategorySearch(event){
        const index = event.target.dataset.index;
        let searchValueName = event.target.value;
        if(searchValueName){
            let objData = this.productCategories;
            let storeData = [];
            for (let i = 0; i < objData.length; i++) {
                const objName = objData[i];
                if ((objName.Name && objName.Name.toLowerCase().indexOf(searchValueName.toLowerCase()) !== -1)) {
                    storeData.push(objName);
                }
            }
            this.logicList[index].isShowProductCategoryValues = storeData != 0 ? true : false;
            this.SearchedProductCategoryData = storeData;
         
        }
        else
        {
            this.logicList[index].isShowProductCategoryValues = false;
            this.logicList[index].productCategoryId = '';
            this.logicList[index].productCategoryName = '';
        }

    }
    selectProductCategory(event)
    {
        const index = event.currentTarget.dataset.index;
        console.log('Name'+event.currentTarget.dataset.name);
        console.log('index'+event.currentTarget.dataset.index);
        this.logicList[index].productCategoryId = event.currentTarget.dataset.id;
        this.logicList[index].productCategoryName = event.currentTarget.dataset.name;
        this.logicList[index].isShowProductCategoryValues = false;
    }

    //product
    handleProductSearch(event){
        const index = event.target.dataset.index;
        let searchValueName = event.target.value;
        if(searchValueName){
            let objData = this.products;
            let storeData = [];
            for (let i = 0; i < objData.length; i++) {
                const objName = objData[i];
                if ((objName.Name && objName.Name.toLowerCase().indexOf(searchValueName.toLowerCase()) !== -1)) {
                    storeData.push(objName);
                }
            }
            this.logicList[index].isShowProductValues = storeData != 0 ? true : false;
            this.SearchedProduct = storeData;
        }
        else
        {
            this.logicList[index].isShowProductValues = false;
            this.logicList[index].productId = '';
            this.logicList[index].productName = '';
        }

    }
    selectProduct(event)
    {
        const index = event.currentTarget.dataset.index;
        console.log('Name'+event.currentTarget.dataset.name);
        console.log('index'+event.currentTarget.dataset.index);
        this.logicList[index].productId = event.currentTarget.dataset.id;
        this.logicList[index].productName = event.currentTarget.dataset.name;
        this.logicList[index].isShowProductValues = false;
    }

    //Selling Category Search 
    handleSellingCategorySearch(event){
        const index = event.target.dataset.index;
        let searchValueName = event.target.value;
        if(searchValueName){
            let objData = this.sellingCategories;
            let storeData = [];
            for (let i = 0; i < objData.length; i++) {
                const objName = objData[i];
                if ((objName.Name && objName.Name.toLowerCase().indexOf(searchValueName.toLowerCase()) !== -1)) {
                    storeData.push(objName);
                }
            }
            this.logicList[index].isShowSellingCategoryValues = storeData != 0 ? true : false;
            this.searchedSellingCategoryData = storeData;
         
        }
        else
        {
            this.logicList[index].isShowSellingCategoryValues = false;
            this.logicList[index].sellingCategoryId = '';
            this.logicList[index].sellingCategoryName = '';
        }

    }
    selectSelllingCategory(event)
    {
        const index = event.currentTarget.dataset.index;
        console.log('Name'+event.currentTarget.dataset.name);
        console.log('index'+event.currentTarget.dataset.index);
        this.logicList[index].sellingCategoryId = event.currentTarget.dataset.id;
        this.logicList[index].sellingCategoryName = event.currentTarget.dataset.name;
        this.logicList[index].isShowSellingCategoryValues = false;
    }

    handleSave() 
    {
        try {
            if (this.validateFields()) {
                this.isLoading = true;
                let targetPlanData = {
                    sobjectType: 'Target_Plan__c',
                    Id:this.targetPlan.Id || null,
                    Division__c: this.targetPlan.Division__c,
                    Region__c: this.targetPlan.Region__c,
                    Incentive_Type__c: this.targetPlan.Incentive_Type__c,
                    Slab_Applied_At__c: this.targetPlan.Slab_Applied_At__c,
                    Active__c: this.targetPlan.Active__c
                };
                // Collect all entered logics
                let targetLogicList = [];
                this.logicList.forEach((logic) => {
                    targetLogicList.push({
                        sobjectType: 'Target_Logic__c',
                        Id:logic.Id || null,
                        Target_Plan__c:logic.targetPlan,
                        Name:logic.Name,
                        Target_Type__c:logic.targetType,
                        Formula__c: logic.formula,
                        Object__c: logic.object, 
                        Field__c: logic.field,
                        Weightage__c: logic.weightage,
                        max_incentive__c:logic.maxIncentive,
                        Account_Type__c:logic.accountType,
                        Product_Category__c:logic.productCategoryId,
                        Product__c:logic.productId,
                        isActive__c: true
                    });
                });
                // Collect all entered Slabs
                let slabs = [];
                this.wagelist.forEach((wg) => {
                slabs.push({
                        sobjectType: 'Incentive_Slab__c',
                        Id:wg.Id || null,
                        Target_Plan__c:wg.targetPlan,
                        Achievement_From__c:wg.waFrom,
                        Achievement_To__c:wg.waTo,
                        Incentive_Percentage__c: wg.incentivePercentage,
                        Incentive_Amount__c: wg.incentiveAmount, 
                    });
                });
                this.isLoading = true;
                saveData({ targetPlan: targetPlanData, targetLogicList: targetLogicList, slabs: slabs, deleteLogicsList:this.deleteLogicsList, deleteSlabsList:this.deleteSlabsList })
                .then(data => {
                    this.isLoading = false;
                    if (data.recordId) {
                        // Success case
                        this.showToast('Success', 'Target plan saved successfully.', 'success');
                        this.dispatchToAura('Done', data.recordId);
                    } 
                    else if (!data.recordId && data.recordAction === 'Duplicate') {
                        // Duplicate record case
                        this.showToast('Error', 'A target plan with the same Division, Region, and Incentive Type already exists.', 'error');
                    } 
                    else if (!data.recordId && data.recordAction === 'Cannot Activate') {
                        // Active target plan already exists case
                        this.showToast('Error', 'An active target plan already exists for this Division and Region. Cannot activate this target plan.', 'error');
                    } 
                    else if (!data.recordId && data.recordAction === 'Cannot Deactivate') {
                        // Deactivation failure due to connected target items
                        this.showToast('Error', 'Cannot deactivate this target plan as target distribution already done for the current period.', 'error');
                    } 
                   
                  
                })
                .catch(error => {
                    this.isLoading = false;
                    console.error("Error while saving data:", error);
                    
                    this.showToast('Error', `Error while saving data: ${error.body?.message || JSON.stringify(error)}`, 'error');
                });
            }
        }
        catch(error){
            this.isLoading = false;
            console.error("Error while saving data", error);
            this.showToast('Error', `Error while saving data: ${error.body?.message || JSON.stringify(error)}`, 'error');
        }
    }
    validateFields()
    {
        let isAllValid = true;
        let logicList = [...this.logicList];
        let slabList = [...this.wagelist];
        let targetPlan = this.targetPlan; 

         // Validate Expense From Date and To Date
        if (!targetPlan.Division__c) {
            isAllValid = false;
            this.showFieldError('Division'); 
            this.showToast('Error','Please select the Division', 'error');
            return isAllValid;
        }
        else if(!targetPlan.Region__c){
            isAllValid = false;
            this.showFieldError('Region'); 
            this.showToast('Error','Please select the Region', 'error');
            return isAllValid;
        }
        else if (!targetPlan.Incentive_Type__c){
            isAllValid = false;
            this.showFieldError('IncentiveType'); 
            this.showToast('Error','Please select the Incentive Type', 'error');
            return isAllValid;
        }
        else{
            let totalWeightage = 0;
            const targetTypeMap = new Map();
            const uniqueTargetTypeSet = new Set();
            // Loop through each Logic list to validate
            for (let i = 0; i < logicList.length; i++) {
                if (!logicList[i].Name || !logicList[i].targetType ||  !logicList[i].formula ||  !logicList[i].object || !logicList[i].field ||
                    !logicList[i].weightage || !logicList[i].maxIncentive 
                ) {
                    isAllValid = false;
                    this.showFieldError('logicFields'); 
                    this.showToast('Error','Please fill in all the mandatory fields','error');
                    return isAllValid;
                }
                if(logicList[i].targetType && (logicList[i].targetType =='Category Sales' || logicList[i].targetType =='Category Sales Quantity') &&
                  !logicList[i].productCategoryId){
                    logicList[i].productCategoryName = '';
                    this.logicList = [...logicList];
                    const inputField = this.template.querySelector(`[data-id="${logicList[i].productCatDataId}"]`);
                    if (inputField) {
                        inputField.value = ''; 
                    }
                    isAllValid = false;
                    this.showFieldError('productCategoryName'); 
                    this.showToast('Error','Please fill in all the Product Categories','error');
                    return isAllValid;
                }
                if(logicList[i].targetType && (logicList[i].targetType =='Must Sell SKU' || logicList[i].targetType =='Focused SKU' ) &&  !logicList[i].sellingCategoryId) {
                    logicList[i].sellingCategoryName = '';
                    this.logicList = [...logicList];
                    const inputField = this.template.querySelector(`[data-id="${logicList[i].sellingCatDataId}"]`);
                    if (inputField) {
                        inputField.value = ''; 
                    }
                    isAllValid = false;
                    this.showFieldError('sellingCategoryName'); 
                    this.showToast('Error','Please fill in all the Selling Categories','error');
                    return isAllValid;
                }
                if(logicList[i].targetType && (logicList[i].targetType =='Product Sales' || logicList[i].targetType =='Product Sales Quantity') &&  !logicList[i].productId){
                    logicList[i].productName = '';
                    this.logicList = [...logicList];
                    const inputField = this.template.querySelector(`[data-id="${logicList[i].productDataId}"]`);
                    if (inputField) {
                        inputField.value = ''; 
                    }
                    isAllValid = false;
                    this.showFieldError('productName'); 
                    this.showToast('Error','Please fill in all the select Products','error');
                    return isAllValid;
                }
                if(logicList[i].targetType && (logicList[i].targetType =='Number of Visits' || logicList[i].targetType =='Number of Accounts Created') &&  !logicList[i].accountType){
                    isAllValid = false;
                    this.showFieldError('logicFields'); 
                    this.showToast('Error','Please fill in all the mandatory fields','error');
                    return isAllValid;
                }

              //Check for other target types (only one allowed)
                if (
                    logicList[i].targetType !== 'Category Sales' && 
                    logicList[i].targetType !== 'Category Sales Quantity' &&
                    logicList[i].targetType !== 'Must Sell SKU' &&
                    logicList[i].targetType !== 'Focused SKU' &&
                    logicList[i].targetType !== 'Product Sales' &&
                    logicList[i].targetType !== 'Product Sales Quantity' &&
                     logicList[i].targetType !== 'Number of Visits' &&
                      logicList[i].targetType !== 'Number of Accounts Created'
                ) {
                    if (uniqueTargetTypeSet.has(logicList[i].targetType)) {
                        isAllValid = false;
                        this.showToast('Error', `Duplicate entry found for "${logicList[i].targetType}" target type.`, 'error');
                        return isAllValid;
                    }
                    uniqueTargetTypeSet.add(logicList[i].targetType);
                }


                //total Weightage
                totalWeightage += Number(logicList[i].weightage);
            }

            // Check for duplicates in the existing six target types
            const duplicateCheckMap = new Map();

            for (let i = 0; i < logicList.length; i++) {
                let key;
                if (logicList[i].targetType === 'Category Sales' || logicList[i].targetType === 'Category Sales Quantity') {
                    key = `${logicList[i].targetType}-${logicList[i].productCategoryId}`;
                }
                if (logicList[i].targetType === 'Must Sell SKU' || logicList[i].targetType === 'Focused SKU') {
                    key = `${logicList[i].targetType}-${logicList[i].sellingCategoryId}`;
                }
                if (logicList[i].targetType === 'Product Sales' || logicList[i].targetType === 'Product Sales Quantity') {
                    key = `${logicList[i].targetType}-${logicList[i].productId}`;
                }
                if (logicList[i].targetType === 'Number of Visits' || logicList[i].targetType === 'Number of Accounts Created') {
                    key = `${logicList[i].targetType}-${logicList[i].accountType}`;
                }

                if (key) {
                    if (duplicateCheckMap.has(key)) {
                        isAllValid = false;
                        this.showToast('Error', `Duplicate entry found for "${logicList[i].targetType}" target type.`, 'error');
                        return isAllValid;
                    }
                    duplicateCheckMap.set(key, true);
                }
            }
      
            // Check if total weightage equals 100
            if (totalWeightage !== 100) {
                isAllValid = false;
                this.showToast('Error', `Total weightage must equal 100. Current weightage total : ${totalWeightage}`, 'error');
                return isAllValid;
            }

            //Looping through each Slab item to valdidate
            let slabSet = new Set(); // To store unique slab ranges

            for (let i = 0; i < slabList.length; i++) {
                let from = slabList[i].waFrom;
                let to = slabList[i].waTo;
                let key = `${from}-${to}`;

                // Check for missing fields
                if (!from || !to || !slabList[i].incentivePercentage || !slabList[i].incentiveAmount) {
                    isAllValid = false;
                    this.showFieldError('wageFields');
                    this.showToast('Error', 'Please fill in all the mandatory fields', 'error');
                    return isAllValid;
                }
                if( Number(from) >  Number(to)) {
                    this.showToast('Error', 'WA From is greater than WA To at slab : '+(i+1), 'error');
                    isAllValid = false;
                    return isAllValid;
                }
                // Check for duplicate slabs
                if (slabSet.has(key)) {
                    isAllValid = false;
                    this.showToast('Error', `Duplicate slab range found: ${from} to ${to}`, 'error');
                    return isAllValid;
                }
                slabSet.add(key); // Add the slab range to the set
            }

        }
        return isAllValid;
    }
    showFieldError(fieldPrefix) {
        const inputFields = this.template.querySelectorAll(`[data-id^="${fieldPrefix}"]`); 
        if (inputFields.length > 0) {
            inputFields.forEach(input => {
                input.reportValidity(); // Show validation error
            });
        }
    }
    handleCancel(){
        if(this.recordId){
            this.dispatchToAura('Done',this.recordId);
        }
        else{
            this.dispatchToAura('Cancel',null);
        }
       
    }

    dispatchToAura(textMessage,Id){
        // Created a custom event to Pass to aura component
        const event =  new CustomEvent('closepopup', {
            detail: {
                eventType: textMessage,
                Id:Id,
            },
          });
          this.dispatchEvent(event);
    }

    //Show Toast
    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    } 
}