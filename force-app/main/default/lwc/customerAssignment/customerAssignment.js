import { LightningElement, api, track } from 'lwc';
import getData from '@salesforce/apex/EmployeeCustomerAssignmentController.getAllData';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import saveProductMapping from '@salesforce/apex/EmployeeCustomerAssignmentController.insertProductMaping';
import saveExecutiveCustomerMapping from '@salesforce/apex/EmployeeCustomerAssignmentController.insertExecutiveCustomerMapping';
import { deleteRecord } from 'lightning/uiRecordApi';
export default class ExpenseDetailedPage extends LightningElement {
    @api recordId ;
    @api objectName;
    @api isDesktop;
    @track dataItems = [];
    isLoading = false;
    showItems = false;
    isEmployeeActive = false;
    @track primaryCustomers = [];
    @track dataItem = {};

    //Primary customer search
    searchedCustomers = [];
    isShowPrimaryCustomers = false;
    isPrimaryCustoerReadOnly = false;

    isModalOpen = false;
    isDeleteModalOpen = false;
    customClass='slds-size_1-of-2 slds-p-horizontal_small';
    headerClass = 'slds-grid slds-align_absolute-center slds-wrap';
    @track showPopup = false;
    @track selectedItem = {};
    containerClass;
    modalTitle = '';
    itemtId = '';
    isDisabled = false;
    selectedUserId;
    selectedUserName;
    is_SSA_DSM;
    

    areas=[];
    searchedAreas = [];
    parentDeportChildDeportMap = {};
    isTerritoryReadOnly = false;
    userIdToSalesChannelsMap = {};
    paymentTermCreditDescriptionMap = {};
    isShowAreaValues = false;

    chanelOptions = [];
    @track creditTermsOptions = [];

    PDPDays=[];
    searchedPDPDays = [];

    primaryCustomerList = [];
    paymentTypeList = [];
    

    serchedProductPrimaryCustomers = [];
    customerType = '';
    showPrimaryfields = false;
    profileName;
    mandatepaymentInfo = false;
   

    @track productMappingchannelOptions = [];
    @track pdpDayList = [];
    @track ParentDeportOptions = [];
    @track childDeportOptions = [];
    @track salesOfficeList = [];
    @track orderTypeList = [];
    @track distributonChannelList = [];
    @track divisionList = [];
    @track  paymemtTermList = [];
    @track creditDescriptions = [];
    @track incotermList = [];
    @track currentUser = {};
    assignPrimaryCustomers = false;
    isCreditPaytypeCustomer = false;
    paymenttypeToOrdertypeMap = {}
    @track territoryCustomerMap = {};
    @track relatedPrimaryCustomers = [];
    executiveTerritoryId = '';
    executiveTerritoryName = '';
    orderTypeDependencyList = [];
    paymentType='';
    isShowDelete = false;

    dsmPrimaryCustomers = [];

    //New Change 
    employeeId ='';
    isUserDeactivated = false;
    @track uniquePrimaryCustomers = [];
    searchKey = '';
    allUniquePrimaryCustomers = []; 
   
    @api refreshData() {
        // Logic to refresh expense data
        this.getItems() ;
    }
    //On starting it will call this method
    connectedCallback() {
        this.containerClass = this.isDesktop ? 'slds-modal__container ' : '';
        this.customClass = this.isDesktop ? 'slds-size_1-of-2 slds-p-horizontal_small' : 'slds-size_1-of-1 slds-p-horizontal_small';
        this.headerClass = this.isDesktop ? '':'slds-grid slds-wrap slds-grid_vertical-align-center';
       // this.getItems();
        this.isLoading = true;
        this.disablePullToRefresh();
        console.log('Record Id'+this.recordId);
        console.log('objectName'+this.objectName);
    }

   

    //it will get existed primary customer assignments
    getItems() {
        if (!navigator.onLine) {
            this.isLoading = false;
            this.showToast('Error', 'No internet connection. Please check your network and try again.', 'error');
            return;
        }
        this.isLoading = true;
        getData({ recordId: this.recordId, objectName: this.objectName })
        .then((result) => {
            this.selectedUserId = result.selectedUserId;
            this.selectedUserName = result.selectedUserName;
            this.is_SSA_DSM = result.is_SSA_DSM;
            this.currentUser = result.currentUser;
            this.isUserDeactivated = result.isUserDeactivated;
            this.employeeId = result.employeeId;
            this.executiveTerritoryId = result.terriotyId;
            this.executiveTerritoryName = result.territoryName;
            this.orderTypeDependencyList = result.orderTypeDependencyList;

            this.dsmPrimaryCustomers = result.primarycustomerList;
            this.ParentDeportOptions = result.parentDeportList;
            this.productMappingchannelOptions = this.getPicklistValueFromList(result.salesChannelList || []);
            this.areas = result.areaList;
            this.territoryCustomerMap = result.territoryWiseCustomersMap;
            this.parentDeportChildDeportMap = result.parentDeportChildDeportMap || {};
            this.paymentTermCreditDescriptionMap = result.paymentTermCreditDescriptionMap || {};
            this.paymenttypeToOrdertypeMap = result.paymenttypeToOrdertypeMap || {};
            this.incotermList = result.incotermList;
            this.paymemtTermList = result.paymemtTermList;
            this.orderTypeList = result.orderTypeList;
            this.salesOfficeList = result.salesOfficeList;
            this.distributonChannelList = result.distributonChannelList;
            this.divisionList = result.divisionList;
            this.pdpDayList = this.getOptionValuesWithNone(result.pdpDayList);
            this.userIdToSalesChannelsMap = result.userIdToSalesChannelsMap;
            this.customClass = this.isDesktop ? this.is_SSA_DSM ? 
               'slds-size_1-of-2 slds-p-horizontal_small' : 'slds-size_1-of-7 slds-p-horizontal_small' : 'slds-size_1-of-1 slds-p-horizontal_small';
            
            this.assignPrimaryCustomers = false;
            console.log('this.currentUser'+JSON.stringify(this.currentUser));
            //Admin
            if (this.currentUser.isAdmin__c) {
                this.assignPrimaryCustomers = true;
                this.isShowDelete = true;
            } 
            //If user opned his own Employee record
            else if(!this.currentUser.isAdmin__c && this.currentUser.Id == this.selectedUserId)
            {
                this.assignPrimaryCustomers = false;
            }
            //FOR TSE/TSM/ASM/RSM for Their Subordinates DSM/SSA
            //current user is not admin
            //current user is not SSA/DSM but selected user DSM
            else if (!this.currentUser.isAdmin__c && !this.currentUser.Is_SSA_DSM__c && this.is_SSA_DSM) {
                this.assignPrimaryCustomers = true;
            }else {
                this.assignPrimaryCustomers = false;
            }

            if (this.is_SSA_DSM) {
                this.dataItems = result.primaryCustomerAssignment.map(item => ({
                    ...item,
                    Id:item.Id,
                    openPopup: false,
                    sObjectType: 'Employee_Customer_Assignment__c',
                    Executive_Name__c: item.Executive__r?.Name || item.Employee__r?.Name || '',
                    Customer_Name__c: item.Customer__r?.Name || '',
                    primaryCustomerType : item.Customer__r?.Primary_Customer_Type__c || '',
                    primaryCustomerCode : item.Customer__r?.SAP_Customer_Code__c || '',
                    customerCode : item.Customer__r?.Customer_Code__c || ''
                }));
            } else {
                this.dataItems = result.productMappingList.map(pm => ({
                    ...pm,
                    sObjectType: 'Product_Mapping__c',
                    openPopup: false,
                    Id:pm.Id,
                    primaryCustomerType : pm.Customer__r.Primary_Customer_Type__c,
                    Area_Name__c: pm.Area__r?.Name || '',
                    Executive_Name__c: pm.Exectuive__r?.Name || pm.Employee__r?.Name || '',
                    Customer_Name__c: pm.Customer__r?.Name || '',
                    primaryCustomerCode : pm.Customer__r?.SAP_Customer_Code__c || '',
                    customerCode : pm.Customer__r?.Customer_Code__c || '',
           
                }));
                // Use Map to keep only unique Customer__c entries
                
           
            }
            this.getUniqueCustomers();
            this.showItems = this.dataItems.length > 0;
        })
        .catch((error) => {
            console.error(error);
        })
        .finally(() => {
            this.isLoading = false;
        });
    }

    getItemsWithIndex() {
        this.uniquePrimaryCustomers = this.uniquePrimaryCustomers.map((item, idx) => {
            return {
                ...item,
                displayIndex: idx + 1
            };
        });
    }

    getUniqueCustomers()
    {
        const customerMap = new Map();

        this.dataItems.forEach(item => {
            if (!customerMap.has(item.Customer__c)) {
                customerMap.set(item.Customer__c, {
                    Id: item.Id,
                    primaryCustomerType: item.primaryCustomerType,
                    primaryCustomerCode : item.primaryCustomerCode,
                    customerCode : item.customerCode,
                    Area_Name__c: item.Area_Name__c,
                    Executive_Name__c: item.Executive_Name__c,
                    Customer_Name__c: item.Customer_Name__c,
                });
            }
        });

        // Assign the unique customer list
        this.allUniquePrimaryCustomers = Array.from(customerMap.values());
        this.uniquePrimaryCustomers = [...this.allUniquePrimaryCustomers]; // initially show all
        this.getItemsWithIndex();
    }
    handleSearch(event) {
        this.searchKey = event.target.value.toLowerCase();

        if (this.searchKey) {
            this.uniquePrimaryCustomers = this.allUniquePrimaryCustomers.filter(item =>
                (item.primaryCustomerCode && item.primaryCustomerCode.toLowerCase().includes(this.searchKey)) ||
                (item.customerCode && item.customerCode.toLowerCase().includes(this.searchKey)) ||
                (item.Customer_Name__c && item.Customer_Name__c.toLowerCase().includes(this.searchKey))
            );
        } else {
            // reset to original list
            this.uniquePrimaryCustomers = [...this.allUniquePrimaryCustomers];
        }
        this.getItemsWithIndex();
    }

    //Once we clicked on the 3 dots
    openMenu(event) {
        const index = parseInt(event.currentTarget.dataset.index, 10);
        this.uniquePrimaryCustomers = this.uniquePrimaryCustomers.map((item, i) => ({
            ...item,
            openPopup: i === index ? !item.openPopup : false
        }));
    }
    handleOnclickMenu(event) {
        const action = event.currentTarget.dataset.name;
        const itemId = event.currentTarget.dataset.id;
        const dataItem = this.dataItems.find(item => item.Id === itemId);
        this.isPrimaryCustoerReadOnly = false;

        this.showUpload = false;
        this.resetForm();
        this.itemtId = null;
        this.isModalOpen = false;
        this.dataItem = {};

        const isEdit = action === 'Edit' && dataItem;
        const isAdd = action === 'Add';

        if (isEdit || isAdd) {
            this.modalTitle = isEdit ? 'Edit Assignment' : 'New Assignment';
            const isSSA = this.is_SSA_DSM;

            if (isSSA) {
                this.dataItem = {
                    Id: isEdit ? dataItem.Id : null,
                    Executive_Name__c: isEdit ? dataItem.Executive_Name__c : this.selectedUserName,
                    Executive__c: isEdit ? dataItem.Executive__c : this.selectedUserId,
                    Employee__c: isEdit ? dataItem.Employee__c : this.employeeId,
                    Customer__c: isEdit ? dataItem.Customer__c : '',
                    Customer_Name__c: isEdit ? dataItem.Customer_Name__c : '',
                    isDisabled: false,
                    sObjectType: 'Employee_Customer_Assignment__c'
                };
                this.isPrimaryCustoerReadOnly = isEdit ? dataItem.Customer__c ? true : false : false,
                this.relatedPrimaryCustomers = this.dsmPrimaryCustomers;//show all primary customers
            } 
            else 
            {
             
                if (isEdit)
                {
                    this.childDeportOptions = this.getOptionsList(this.parentDeportChildDeportMap[dataItem.Parent_Depot__c] || []);
                    const creditDescriptionMap = this.paymentTermCreditDescriptionMap[dataItem.Payment_Term__c] || {};
                    this.creditDescriptions = this.getOptionsList(creditDescriptionMap);
                    const firstValue = Object.values(creditDescriptionMap)[0]; // Set first value
                    this.dataItem.Credit_Description__c = firstValue || '';
                    let paytype = dataItem.Payment_Type_Formula__c; 
                    this.isCreditPaytypeCustomer = paytype == 'Credit' ? true : false;
                    
                }

                this.dataItem = {
                    Id: isEdit ? dataItem.Id : null,
                    Executive_Name__c: isEdit ? dataItem.Executive_Name__c : this.selectedUserName,
                    Executive__c: isEdit ? dataItem.Executive__c : this.selectedUserId,
                    Exectuive__c:isEdit ? dataItem.Exectuive__c : this.selectedUserId,
                    Employee__c: isEdit ? dataItem.Employee__c : this.employeeId,
                    Customer__c: isEdit ? dataItem.Customer__c : '',
                    Customer_Name__c: isEdit ? dataItem.Customer_Name__c : '',
                    Area__c: isEdit ? dataItem.Area__c : '',
                    Area_Name__c: isEdit ? dataItem.Area_Name__c : '',
                    Parent_Depot__c: isEdit ? dataItem.Parent_Depot__c : '',
                    Child_Depot__c: isEdit ? dataItem.Child_Depot__c : '',
                    PDP_Name__c: isEdit ? dataItem.PDP_Name__c : '',
                    PDP_Day__c: isEdit ? dataItem.PDP_Day__c : '',
                    Payment_Type__c: isEdit ? dataItem.Payment_Type__c : '',
                    Payment_Term__c: isEdit ? dataItem.Payment_Term__c : '',
                    Credit_Limit__c: isEdit ? dataItem.Credit_Limit__c : '',
                    Credit_Description__c: isEdit ? dataItem.Credit_Description__c : '',
                    Inco_Terms__c: isEdit ? dataItem.Inco_Terms__c : '',
                    Order_Type__c: isEdit ? dataItem.Order_Type__c : '',
                    Distribution_Channel__c: isEdit ? dataItem.Distribution_Channel__c : '',
                    Sales_Office__c: isEdit ? dataItem.Sales_Office__c : '',
                    Division__c: isEdit ? dataItem.Division__c : '',
                    Primary_Customer__c: isEdit ? dataItem.Primary_Customer__c : '',
                    Primary_Customer_Name__c: isEdit ? dataItem.Primary_Customer_Name__c : '',
                    Chanel__c: isEdit ? dataItem.Chanel__c : '',
                    isDisabled: false,
                    sObjectType: 'Product_Mapping__c'
                };
                if (isEdit && dataItem.Area__c) {
                    const areaId = dataItem.Area__c;

                    if (this.territoryCustomerMap && this.territoryCustomerMap[areaId]) {
                        this.relatedPrimaryCustomers = this.territoryCustomerMap[areaId];
                    } else {
                        this.relatedPrimaryCustomers = [];
                    }
                } else {
                    this.relatedPrimaryCustomers = [];
                }
                this.isPrimaryCustoerReadOnly = isEdit ? dataItem.Customer__c ? true : false : false,
                this.isTerritoryReadOnly = this.dataItem.Area__c ? true : false;
            }

            this.itemtId = isEdit ? dataItem.Id : null;
            this.isModalOpen = true;
        }
        else if(action == 'Delete')
        {
            this.isDeleteModalOpen = true;
            this.itemtId = itemId;
        }
         else {
            console.error('Invalid action or item not found.');
        }
    }
    handleInputProductMappingChange(event) {
        const fieldName = event.target.name;
        const fieldValue  = event.detail.value;
        this.dataItem = { ...this.dataItem, [fieldName]: fieldValue };
        if(fieldName =='Parent_Depot__c')
        {
            this.childDeportOptions = this.getOptionsList(this.parentDeportChildDeportMap[fieldValue] || []);
        }
        if(fieldName == 'Payment_Term__c')
        {
             const creditDescriptionMap = this.paymentTermCreditDescriptionMap[fieldValue] || {};
            this.creditDescriptions = this.getOptionsList(creditDescriptionMap);
            const firstValue = Object.values(creditDescriptionMap)[0]; // Set first value
            this.dataItem.Credit_Description__c = firstValue || '';
        }
        else if (fieldName === 'Chanel__c') {
            this.dataItem.Area_Name__c = '';
            this.dataItem.Area__c = '';
            this.isTerritoryReadOnly = false;
            this.isShowAreaValues = false;
            this.relatedPrimaryCustomers = [];
            if( this.executiveTerritoryId && this.executiveTerritoryName)
            {
                const territoryRecord = this.areas.find(area => area.Id === this.executiveTerritoryId);
                if (territoryRecord) {
                    // Compare Sales_Channel__c with selected channel value
                    if (
                        territoryRecord.Sales_Channel__c &&
                        territoryRecord.Sales_Channel__c.toLowerCase() === fieldValue.toLowerCase()
                    ) {
                        this.dataItem.Area__c = this.executiveTerritoryId;
                        this.dataItem.Area_Name__c  = this.executiveTerritoryName;
                        this.isTerritoryReadOnly = true;
                        this.isShowAreaValues = false;
                           // Get primary customers for selected Area (territory)
                        if (this.territoryCustomerMap && this.territoryCustomerMap[this.executiveTerritoryId]) {
                            this.relatedPrimaryCustomers = this.territoryCustomerMap[this.executiveTerritoryId];
                        } else {
                            this.relatedPrimaryCustomers = [];
                        }
                    }
                }
            }
            this.dataItem.Order_Type__c = this.getOrderTypeFromDependency(
                this.dataItem.Chanel__c,
                this.dataItem.Division__c,
                this.paymentType,
                this.orderTypeDependencyList
            );

        }
        else if (fieldName === 'Division__c') {
            this.dataItem.Order_Type__c = this.getOrderTypeFromDependency(
                this.dataItem.Chanel__c,
                this.dataItem.Division__c,
                this.paymentType,
                this.orderTypeDependencyList
            );
        }
    }

    getOrderTypeFromDependency(channel, division, paymentType, orderTypeDependencyList) {
        if (!channel || !division || !paymentType || !orderTypeDependencyList || !orderTypeDependencyList.length) {
            return '';
        }

        const match = orderTypeDependencyList.find(dep => {
            const salesChannels = dep.Sales_Channel__c?.split(';').map(s => s.trim().toLowerCase()) || [];
            return (
                salesChannels.includes(channel.toLowerCase()) &&
                String(dep.Division__c) === String(division) &&
                dep.Payment_Type__c?.toLowerCase() === paymentType.toLowerCase()
            );
        });

        return match?.Order_Type__c || '';
    }

    //Customer Search 
    handlePrimarySearch(event)
    {
        let searchValueName = event.target.value;
        if (searchValueName) {
            let objData = this.relatedPrimaryCustomers;
            let searchedData = [];
            for (let i = 0; i < objData.length; i++) {
                const objName = objData[i];
                const nameMatch = objName.customerName && objName.customerName.toLowerCase().includes(searchValueName.toLowerCase());
                const codeMatch = objName.sapCode && objName.sapCode.toLowerCase().includes(searchValueName.toLowerCase());

                if (nameMatch || codeMatch) {
                    searchedData.push(objName);
                    if (searchedData.length >= 50) break;
                }
            }
            this.isShowPrimaryCustomers = searchedData.length > 0;
            this.searchedCustomers = searchedData;
        }
        else
        {
            this.isShowPrimaryCustomers = false;
            this.searchedCustomers = [];
            this.dataItem.Customer__c = '';
            this.dataItem.Customer_Name__c = '';
            this.isPrimaryCustoerReadOnly = false;
        }
    }
    selectPrimaryCustomer(event)
    {
        this.isShowPrimaryCustomers = false;
        this.isPrimaryCustoerReadOnly = true;
        this.searchedCustomers = [];
        this.dataItem.Customer__c =  event.currentTarget.dataset.id; 
        this.dataItem.Customer_Name__c=  event.currentTarget.dataset.name; 
        let paytype =  event.currentTarget.dataset.paytype; 
        this.paymentType = paytype;
        this.isCreditPaytypeCustomer = paytype == 'Credit' ? true : false;
        //this.orderTypeList = this.getOptionsList(this.paymenttypeToOrdertypeMap[ paytype] || []);
    }
    getAllUniqueCustomers() {
        const allCustomersMap = new Map();

        if (this.territoryCustomerMap) {
            for (const areaId in this.territoryCustomerMap) {
                const customerList = this.territoryCustomerMap[areaId];

                for (const cust of customerList) {
                    if (!allCustomersMap.has(cust.customerId)) {
                        allCustomersMap.set(cust.customerId, cust);
                    }
                }
            }
        }

        // Convert to list
        return Array.from(allCustomersMap.values());
    }


    //Territory Search 
    handleTerritorySearch(event) {
        const searchValueName = event.target.value?.trim().toLowerCase();

        if (searchValueName) {
            const objData = this.areas || [];
            const channelValue = this.dataItem?.Chanel__c?.toLowerCase() || '';
            const searchedData = objData.filter(obj => {
                const nameMatch = obj.Name?.toLowerCase().includes(searchValueName);
                const channelMatch = obj.Sales_Channel__c?.toLowerCase() === channelValue;
                return nameMatch && channelMatch;
            });

            this.isShowAreaValues = searchedData.length > 0;
            this.searchedAreas = searchedData;
        } else {
            this.isShowAreaValues = false;
            this.searchedAreas = [];
            this.dataItem.Area_Name__c = '';
            this.dataItem.Area__c = '';
            this.isShowPrimaryCustomers = false;
            this.searchedCustomers = [];
            this.dataItem.Customer__c = '';
            this.dataItem.Customer_Name__c = '';
            this.isPrimaryCustoerReadOnly = false;
            this.isTerritoryReadOnly = false;
            this.relatedPrimaryCustomers = [];
        }
    }
    selectTerritory(event)
    {
        const areaName = event.currentTarget.dataset.name;
        const areaId = event.currentTarget.dataset.id;
        this.dataItem.Area_Name__c = areaName; 
        this.dataItem.Area__c = areaId;
        this.isTerritoryReadOnly = true;
        this.isShowAreaValues = false;
        this.searchedAreas = [];

        // Get primary customers for selected Area (territory)
        if (this.territoryCustomerMap && this.territoryCustomerMap[areaId]) {
            this.relatedPrimaryCustomers = this.territoryCustomerMap[areaId];
        } else {
            this.relatedPrimaryCustomers = [];
        }
    }


    closeModal() {
        this.isModalOpen = false;
        this.resetForm();
    }
    resetForm() {
       this.dataItem = {
       };
    }
    handleDeleteCancel() {
        this.isDeleteModalOpen = false;
    }

    deleteassignment() {
        const itemId = this.itemtId;
        this.isDeleteModalOpen = false;
        this.isLoading = true;
        deleteRecord(itemId)
        .then(() => {
            this.dataItems = this.dataItems.filter(item => item.Id !== itemId);
            console.log('Entered');
            this.showItems = this.dataItems.length > 0;
            this.isLoading = false;
            this.showToast('Success', 'Primary Customer Assignment Deleted Successfully', 'success');
        })
        .catch(error => {
            this.isLoading = false;
            this.showToast('Error', 'Error deleting ' + JSON.stringify(error), 'error');
        });
    }


    vaidateMappingsFields()
    {
        if (!navigator.onLine) {
            this.showToast('Error', 'No internet connection. Please check your network and try again.', 'error');
            return;
        }
        let isAllValid = true;
        const isSSA = this.is_SSA_DSM;

        const item = this.dataItem;
        if (isSSA) {

            if (!item.Employee__c) {
                this.showFieldError('customerAssignmentFields');
                this.showToast('Error', `Please fill in all the mandatory fields`, 'error');
                isAllValid = false;
                return isAllValid;
            }

            if (!item.Customer__c) {
                this.showFieldError('customerAssignmentFields');
                this.showToast('Error', `Please fill in all the mandatory fields`, 'error');
                isAllValid = false;
                return isAllValid;
            }


        
        } else {
            if (
                !item.Area__c || !item.Employee__c ||
                !item.Chanel__c || !item.Parent_Depot__c || !item.Child_Depot__c ||
                !item.Inco_Terms__c || !item.Sales_Office__c || 
                !item.Order_Type__c || !item.Distribution_Channel__c || !item.Division__c
            ) {
                console.log(JSON.stringify(item));
                this.showFieldError('customerAssignmentFields');
                this.showToast('Error', `Please fill in all the mandatory fields `, 'error');
                isAllValid = false;
                return isAllValid;
            }

            if (this.isCreditPaytypeCustomer && (!item.Payment_Term__c || !item.Credit_Description__c)) {
                this.showFieldError('customerAssignmentFields');
                this.showToast('Error', `Please fill in all the mandatory fields`, 'error');
                isAllValid = false;
                return isAllValid;
            }
    
        }
        return isAllValid;
            
    }
    handleSaveButtonClick()
    {
        if(this.vaidateMappingsFields())
        {
            this.save();
        }
    }

    save() {
        const isSSA = this.is_SSA_DSM;
        if (isSSA) {
            this.saveCustomerExecutiveMapping();
        }
        else
        {
            this.saveProductMapping();
        }
    }

    saveProductMapping()
    {
        //Duplication Check
        const isDuplicate = this.dataItems.some(item => {
            if (this.dataItem.Id && item.Id === this.dataItem.Id) {
                return false;
            }
            return item.Customer__c === this.dataItem.Customer__c &&
                item.Chanel__c === this.dataItem.Chanel__c &&
                item.Area__c === this.dataItem.Area__c &&
                item.PDP_Day__c === this.dataItem.PDP_Day__c &&   
                item.Parent_Depot__c === this.dataItem.Parent_Depot__c &&
                item.Child_Depot__c === this.dataItem.Child_Depot__c && 
                item.Order_Type__c === this.dataItem.Order_Type__c &&
                item.Distribution_Channel__c === this.dataItem.Distribution_Channel__c && 
                item.Division__c === this.dataItem.Division__c &&
                item.Payment_Term__c === this.dataItem.Payment_Term__c && 
                item.Inco_Terms__c === this.dataItem.Inco_Terms__c ;
        });

        if (isDuplicate) {
            this.showToast('Error', 'Duplicate Customer Mapping: A mapping for this customer with the same details already exists.', 'error');
            return;
        }
        if (!navigator.onLine) {
            this.isLoading = false;
            this.showToast('Error', 'No internet connection. Please check your network and try again.', 'error');
            return;
        }

        this.isLoading = true;
        saveProductMapping({ productMapping: this.dataItem })
        .then((pm) => {
            console.log('Result:', JSON.stringify(pm));

            const newItem = {
                sObjectType: 'Product_Mapping__c',
                openPopup: false,
                Id:pm.Id,
                primaryCustomerType : pm.Customer__r?.Primary_Customer_Type__c || '',
                Exectuive__c:pm.Exectuive__c,
                Area__c:pm.Area__c,
                Area_Name__c: pm.Area__r?.Name || '',
                Executive_Name__c: pm.Exectuive__r?.Name || pm.Employee__r?.Name || '',
                Employee__c:pm.Employee__c,
                Customer_Name__c: pm.Customer__r?.Name || '',
                Customer__c:pm.Customer__c,
                PDP_Day__c:pm.PDP_Day__c,
                Chanel__c:pm.Chanel__c,
                Parent_Depot__c:pm.Parent_Depot__c,
                Child_Depot__c:pm.Child_Depot__c,
                Sales_Office__c:pm.Sales_Office__c,
                Order_Type__c:pm.Order_Type__c,
                Distribution_Channel__c:pm.Distribution_Channel__c,
                Division__c:pm.Division__c,
                Payment_Term__c:pm.Payment_Term__c,
                Credit_Description__c:pm.Credit_Description__c,
                Inco_Terms__c:pm.Inco_Terms__c,
                primaryCustomerCode : pm.Customer__r?.SAP_Customer_Code__c || '',
                customerCode : pm.Customer__r?.Customer_Code__c || '',
            };

            // Handle modal visibility
            this.isModalOpen = false;

            if (this.itemtId) {
                // Update existing record
                this.dataItems = [newItem, ...this.dataItems.filter(item => item.Id !== this.itemtId)];
            } else {
                // Add new record
                this.dataItems = [newItem, ...this.dataItems];
                this.itemtId = pm.Id;
            }
            this.getUniqueCustomers();

            this.showItems = this.dataItems.length > 0;
            this.isLoading = false;
           
            this.showToast("Success","Primary Customer Assignment Saved Successfully", "success");   
        })
        .catch((error) => {
            this.isLoading = false;
            console.error('Save Error:', JSON.stringify(error));

            let message = 'Unknown error';
            if (error.body && error.body.message) {
                message = error.body.message;
            }

            this.showToast('Error', `Error while saving expense: ${message}`, 'error');
        });

    }
    saveCustomerExecutiveMapping()
    {
         //Duplication Check
        const isDuplicate = this.dataItems.some(item => {
            if (this.dataItem.Id && item.Id === this.dataItem.Id) {
                return false;
            }
            return item.Customer__c === this.dataItem.Customer__c;
             
        });

        if (isDuplicate) {
            this.showToast('Error', 'Duplicate Customer Mapping: A mapping for this customer with the same details already exists.', 'error');
            return;
        }
        if (!navigator.onLine) {
            this.isLoading = false;
            this.showToast('Error', 'No internet connection. Please check your network and try again.', 'error');
            return;
        }
        this.isLoading = true;
        saveExecutiveCustomerMapping({ executiveCustomerMapping: this.dataItem })
        .then((item) => {
           // console.log('Result:', JSON.stringify(item));

            const newItem = {
                sObjectType: 'Employee_Customer_Assignment__c',
                Id:item.Id,
                Executive_Name__c: item.Executive__r?.Name || item.Employee__r?.Name || '',
                Employee__c:item.Employee__c,
                primaryCustomerType : item.Customer__r?.Primary_Customer_Type__c || '',
                Customer_Name__c: item.Customer__r?.Name || '',
                Customer__c:item.Customer__c,
                Executive__c:item.Executive__c,
                primaryCustomerCode : item.Customer__r?.SAP_Customer_Code__c || '',
                customerCode : item.Customer__r?.Customer_Code__c || '',
            };

            // Handle modal visibility
            this.isModalOpen = false;

            if (this.itemtId) {
                // Update existing record
                this.dataItems = [newItem, ...this.dataItems.filter(item => item.Id !== this.itemtId)];
            } else {
                // Add new record
                this.dataItems = [newItem, ...this.dataItems];
                this.itemtId = item.Id;
            }
            this.getUniqueCustomers();

            this.showItems = this.dataItems.length > 0;
            this.isLoading = false;
           
            this.showToast("Success","Primary Customer Assignment Saved Successfully", "success");   
        })
        .catch((error) => {
            this.isLoading = false;
            console.error('Save Error:', JSON.stringify(error));

            let message = 'Unknown error';
            try {
              // Check for trigger validation errors (addError)
                if (error.body && Array.isArray(error.body.pageErrors) && error.body.pageErrors.length > 0) {
                    message = error.body.pageErrors[0].message;
                } else if (error.body && error.body.message) {
                    message = error.body.message;
                } else if (typeof error === 'string') {
                    message = error;
                }
            } catch (e) {
                console.error('Error parsing error message:', e);
            }

            this.showToast('Error', message, 'error'); });
    }


    showFieldError(fieldPrefix) {
        const inputFields = this.template.querySelectorAll(`[data-id^="${fieldPrefix}"]`); 
        if (inputFields.length > 0) {
            inputFields.forEach(input => {
                input.reportValidity(); // Show validation error
            });
        }
    }
    getOptionsList(optionsMap) {
        return Object.keys(optionsMap).map(label => ({
            label: label, 
            value: optionsMap[label] // Use API value instead of label
        }));
    }
    getPicklistValueFromList(optionsArray) {
        return optionsArray.map(option => ({ label: option, value: option }));
    }
    getOptionValuesWithNone(optionsArray)
    {
        const selectOption = { label: 'Select option', value: '' };
        return [selectOption, ...optionsArray];
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
    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
    addAllOption(options) {
       return [{ label: 'Select an Option', value: '' }, ...options];
    }
}