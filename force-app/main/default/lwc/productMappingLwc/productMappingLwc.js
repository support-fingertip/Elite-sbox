import { LightningElement,api,track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import FORM_FACTOR from '@salesforce/client/formFactor';
import { LightningModal } from 'lightning/modal';
import { RefreshEvent } from 'lightning/refresh';
import modal from "@salesforce/resourceUrl/custommodalcss";
import { CloseActionScreenEvent } from "lightning/actions";
import { loadStyle } from "lightning/platformResourceLoader"
import GET_ALL_DATA from '@salesforce/apex/newCustomerLwcController.getAllData';
import saveProductData from '@salesforce/apex/newCustomerLwcController.saveProductData';
export default class ProductMappingLwc  extends NavigationMixin(LightningElement) {
    currectRecordId;
    isLoading = false;
    isPageLoaded = false; 
    isDesktop = false;
    isPhone = false;
    containerClass ='slds-modal__container';
    customClass='slds-size_1-of-6 slds-p-horizontal_small';
    buttoncustomClass='slds-size_1-of-6 slds-p-horizontal_small';
    @track productMappingList = [{
        sObjectType: 'Product_Mapping__c',
        Id: null,
        Customer__c:null,
        index:1,
        Area__c: null,
        Area_Name__c: null,
        Exectuive__c: null,
        Executive_Name__c:null,
        Parent_Depot__c:'',
        Child_Depot__c:'',
        Chanel__c:'',
        PDP_Name__c:'',
        PDP_Day__c:'',
        Payment_Type__c:'',
        Payment_Term__c:'',
        Credit_Description__c:'',
        Inco_Terms__c:'',
        Credit_Limit__c:'',
        creditDescriptions:[],
        childDeportOptions:[],
        disableChildDeprort:true,
        isShowExecutiveValues:false,
        isShowAreaValues:false,
        isShowPDPDayValues:false,
        disablePDPDay:true,
        mandateCreditField:false,
        Primary_Customer_Name__c:'',
        Primary_Customer__c:'',
        isShowPrimaryCustomerValues:false,
        productMappingchannelOptions :[],
        Order_Type__c:'',
        Distribution_Channel__c:'',
        Sales_Office__c:'',
        Division__c:'',
        isExecutiveReadOnly:false,
        isTerritoryReadOnly:false,
        isDistributorReadOnly:false,

        isSubstockiestDisabled :true,
        relatedSubStockiest:[],
        Sub_Stockiest__c:'',
        Sub_Stockiest_Name__c:'',
        isShowSubstockistValues:false,
        isSubStockiestReadOnly:false,

     },
    ];
    executives=[];
    searchedExecutives = [];
    areas=[];
    searchedAreas = [];
    parentDeportChildDeportMap = {};
    userIdToSalesChannelsMap = {};
    ParentDeportOptions = [];
    chanelOptions = [];
    @track creditTermsOptions = [];

    PDPDays=[];
    searchedPDPDays = [];
    @track deleteProductMappingList = [];
    hasRendered = false;

    paymentTermCreditDescriptionMap = {};
    primaryCustomerList = [];
    paymentTypeList = [];
    incotermList = [];
    pdpDayList = [];
    paymemtTermList = [];
    serchedProductPrimaryCustomers = [];
    customerType = '';
    showPrimaryfields = false;
    profileName;
    mandatepaymentInfo = false;
    @track orderTypeList = [];
    @track salesOfficeList = [];
    @track distributonChannelList = [];
    @track divisionList = [];
    parentDeportChildDeportMap = {};
    //Sub Stockiest
    searchedSubStockiests = [];
    primaryToSubStockiestMap = {};
    paymenttypeToOrdertypeMap = {};
    isSubstockiest = false;
    executiveWiseAccounts = {};
    executiveToSubStockiestIds = {};
    orderTypeDependencyList = [];
    paymentType = '';

    @api set recordId(value) {
        this.currentRecordId = value;
        console.log('RecordId from setter:', this.currentRecordId);

        // Call method that needs recordId
        if (this.currentRecordId) {
            this.getAllData(value);
        }
    }

    get recordId() {
        return this.currectRecordId;
    }

    //On loading this method will be called
    connectedCallback() {
        this.isLoading=true;
        this.isDesktop = FORM_FACTOR === 'Large'? true : false;
        this.isPhone = FORM_FACTOR === 'Small'? true : false;
        if (FORM_FACTOR === 'Medium') this.isDesktop = true;
        this.containerClass = this.isDesktop ? 'slds-modal__container' : 'mobilePopup';
        this.accountCustomClass = this.isDesktop ? 'slds-size_1-of-2' : 'slds-size_1-of-1';
        this.customClass = this.isDesktop ? 'slds-size_1-of-7 inputcustompadding' : 'slds-size_1-of-1 slds-p-horizontal_xx-small';
        this.isLoading = true; 
        this.disablePullToRefresh();
        loadStyle(this, modal);
    }
   
    getAllData(recordId){
        if (!navigator.onLine) {
            this.showToast('Error', 'No internet connection. Please check your network and try again.', 'error');
            return;
        }
        this.isLoading = true;
        console.log('record Id'+recordId);
        GET_ALL_DATA({accountId:recordId})
        .then(result => {
            this.primaryToSubStockiestMap = result.primaryToSubStockiestMap;
            this.executiveWiseAccounts = result.executiveWiseAccounts;
            this.executiveToSubStockiestIds = result.executiveToSubStockiestIds;
            this.ParentDeportOptions = result.parentDeportList; 
            this.executives = result.userList;
            this.areas = result.areaList;
            this.PDPDays = result.PDPList;
            this.parentDeportChildDeportMap = result.parentDeportChildDeportMap || {};
            this.paymentTermCreditDescriptionMap = result.paymentTermCreditDescriptionMap || {};
            this.paymenttypeToOrdertypeMap = result.paymenttypeToOrdertypeMap || {};
            this.primaryCustomerList = result.primaryCustomerList;
            this.incotermList =  result.incotermList;
            this.paymemtTermList = result.paymemtTermList;
            this.orderTypeDependencyList = result.orderTypeDependencyList || []; 
            
            this.orderTypeList = result.orderTypeList;
            this.salesOfficeList = result.salesOfficeList;
            this.distributonChannelList = result.distributonChannelList;
            this.divisionList = result.divisionList;
            this.pdpDayList = this.getOptionValuesWithNone(result.pdpDayList);

            this.userIdToSalesChannelsMap = result.userIdToSalesChannelsMap;
            this.customerType = result.currentAccount.Customer_Type__c;
            let paymentType = result.currentAccount.Payment_Type__c;
            this.paymentType = paymentType;
            this.mandatepaymentInfo = paymentType == 'Credit' ? true : false;
            this.isSubstockiest =result.currentAccount.Secondary_Customer_Type__c == 'Sub Stockiest' ? true :false;
            console.log('result.customerType'+result.customerType);
            this.showPrimaryfields = this.customerType =='Primary Customer' ? true :false;
            if(this.customerType == 'Primary Customer')
            {
                //this.orderTypeList = this.getOptionsList(this.paymenttypeToOrdertypeMap[ paymentType] || []);
            }
            this.customClass = this.isDesktop ? this.customerType =='Primary Customer' ?  
                                'slds-size_1-of-7 inputcustompadding' : 
                                this.isSubstockiest ? 'slds-size_3-of-7 inputcustompadding':'slds-size_2-of-7 inputcustompadding' : 
                                'slds-size_1-of-1 slds-p-horizontal_xx-small';
            this.buttoncustomClass =  this.isDesktop ?this.customerType  =='Primary Customer' ?  
                                    'slds-size_1-of-7 inputcustompadding' :
                                    this.isSubstockiest ? 'slds-size_1-of-7 inputcustompadding':'slds-size_1-of-7 inputcustompadding' 
                                     : 'slds-size_1-of-1 slds-p-horizontal_xx-small';   

           this.profileName = result.profileName;
            if(result.productMappingList.length > 0)
            {
                this.productMappingList = result.productMappingList.map((pm, index) => {
                    let updatedItem = {
                        sObjectType: 'Product_Mapping__c',
                        Id: pm.Id,
                        Customer__c:pm.Customer__c,
                        index: index + 1,
                        Area__c: pm.Area__c,
                        Area_Name__c:  pm.Area__r ? pm.Area__r.Name : '',
                        Exectuive__c:  pm.Exectuive__c,
                        Executive_Name__c: pm.Exectuive__r ? pm.Exectuive__r.Name:'',
                        Parent_Depot__c:pm.Parent_Depot__c,
                        Child_Depot__c:pm.Child_Depot__c,
                        
                        Customer__c:pm.Customer__c,
                        PDP_Name__c:pm.PDP_Name__c,
                        PDP_Day__c:pm.PDP_Day__c,
                        Payment_Type__c:pm.Payment_Type__c,
                        Payment_Term__c:pm.Payment_Term__c,
                        Credit_Limit__c:pm.Credit_Limit__c,
                        Credit_Description__c:pm.Credit_Description__c,
                        Inco_Terms__c:pm.Inco_Terms__c,
                        childDeportOptions:this.getOptionsList(this.parentDeportChildDeportMap[pm.Parent_Depot__c] || []),
                        creditDescriptions:this.getOptionsList(this.paymentTermCreditDescriptionMap[pm.Payment_Term__c] || []),
                        disableChildDeprort:false,
                        isShowExecutiveValues:false,
                        isShowAreaValues:false,
                        isShowPDPDayValues:false,
                        disablePDPDay:false,
                        Order_Type__c:pm.Order_Type__c,
                        Distribution_Channel__c:pm.Distribution_Channel__c,
                        Sales_Office__c:pm.Sales_Office__c,
                        Division__c:pm.Division__c,
                        mandateCreditField:pm.Payment_Type__c =='Credit' ? true : false,
                        Primary_Customer_Name__c: pm.Primary_Customer__r ? pm.Primary_Customer__r.Name : '',
                        Primary_Customer__c:pm.Primary_Customer__c,
                        isShowPrimaryCustomerValues:false,
                        productMappingchannelOptions :this.getPicklistValueFromList(
                            this.userIdToSalesChannelsMap[pm.Exectuive__c] || []
                        ),
                        Chanel__c:pm.Chanel__c,
                        isExecutiveReadOnly:pm.Exectuive__c ? true: false,
                        isTerritoryReadOnly:pm.Area__c ? true: false,
                        isDistributorReadOnly:pm.Primary_Customer__c ? true: false,

                        isSubstockiestDisabled :pm.Primary_Customer_Type__c == 'Superstockiest' ? false : true,
                        relatedSubStockiest: this.primaryToSubStockiestMap[pm.Primary_Customer__c] || [],
                        Sub_Stockiest__c: this.isSubstockiest ? '':pm.Sub_Stockiest__c,
                        Sub_Stockiest_Name__c: this.isSubstockiest ? '': pm.Sub_Stockiest__r ? pm.Sub_Stockiest__r.Name:'',
                        isShowSubstockistValues:false,
                        isSubStockiestReadOnly: pm.Sub_Stockiest__c ? true : false,


                    };
                    return updatedItem;
                });
            }
            else
            {
                this.productMappingList = [{
                    sObjectType: 'Product_Mapping__c',
                    Id: null,
                    index:1,
                    Area__c: null,
                    Area_Name__c: null,
                    Exectuive__c: null,
                    Executive_Name__c:null,
                    Parent_Depot__c:'',
                    Child_Depot__c:'',
                    Chanel__c:'',
                    PDP_Name__c:'',
                    PDP_Day__c:'',
                    Payment_Type__c:'',
                    Payment_Term__c:'',
                    Credit_Description__c:'',
                    Inco_Terms__c:'',
                    Credit_Limit__c:'',
                    creditDescriptions:[],
                    childDeportOptions:[],
                    disableChildDeprort:true,
                    isShowExecutiveValues:false,
                    isShowAreaValues:false,
                    isShowPDPDayValues:false,
                    disablePDPDay:true,
                    Customer__c:this.currentRecordId,
                    mandateCreditField:false,
                    Primary_Customer_Name__c:'',
                    Primary_Customer__c:'',
                    Order_Type__c:'',
                    Distribution_Channel__c:'',
                    Sales_Office__c:'',
                    Division__c:'',
                    isShowPrimaryCustomerValues:false,
                    productMappingchannelOptions :[],
                    isExecutiveReadOnly:false,
                    isTerritoryReadOnly:false,
                    isDistributorReadOnly:false,

                    isSubstockiestDisabled :true,
                    relatedSubStockiest:[],
                    Sub_Stockiest__c:'',
                    Sub_Stockiest_Name__c:'',
                    isShowSubstockistValues:false,
                    isSubStockiestReadOnly:false,
                    },
                   
                ];
    
            }
        
            this.isLoading = false;
        })
        .catch(error => {
            console.error(error);
            this.isLoading = false;
        });
    }

     /**--------Product Mapping Screeen--------**/
    //Executive Search
    handleExectieSearch(event){
        const index = event.target.dataset.index;
        let searchValueName = event.target.value;
        if(searchValueName){
            let objData = this.executives;
            let searchedData = [];
            for (let i = 0; i < objData.length; i++) {
                const objName = objData[i];
                // Skip if customer is Primary and executive is SSA/DSM
                if ( this.showPrimaryfields && objName.Is_SSA_DSM__c === true) {
                    continue;
                }
                const nameMatch = objName.Name && objName.Name.toLowerCase().includes(searchValueName.toLowerCase());
                const codeMatch = objName.Employee_Code__c && objName.Employee_Code__c.toLowerCase().includes(searchValueName.toLowerCase());

                if (nameMatch || codeMatch) {
                    searchedData.push(objName);
                    if (searchedData.length >= 50) break;
                }
            }
            this.productMappingList[index].isShowExecutiveValues = searchedData != 0 ? true : false;
            this.searchedExecutives = searchedData;
        }
        else
        {
            this.productMappingList[index].isShowExecutiveValues = false;
            this.productMappingList[index].Executive_Name__c = '';
            this.productMappingList[index].Exectuive__c = '';
            this.productMappingList[index].productMappingchannelOptions = [];
            this.productMappingList[index].Primary_Customer_Name__c = '';
            this.productMappingList[index].Primary_Customer__c = '';
            this.productMappingList[index].isExecutiveReadOnly = false;

            this.productMappingList[index].isDistributorReadOnly = false;
            this.productMappingList[index].isSubstockiestDisabled = true;
            this.productMappingList[index].Sub_Stockiest__c = '';
            this.productMappingList[index].Sub_Stockiest_Name__c = '';
            this.productMappingList[index].isSubStockiestReadOnly = false;
            this.primaryCustomerList = [];
            this.productMappingList[index].relatedSubStockiest = [];
        }

    }
    selectExective(event)
    {
        const index = event.currentTarget.dataset.index;
        const userid = event.currentTarget.dataset.id;
        this.productMappingList[index].Exectuive__c = userid;
        this.productMappingList[index].Executive_Name__c = event.currentTarget.dataset.name;
        this.productMappingList[index].isShowExecutiveValues = false;
        this.productMappingList[index].productMappingchannelOptions = this.getPicklistValueFromList(
            this.userIdToSalesChannelsMap[userid] || []
        );
        this.productMappingList[index].isExecutiveReadOnly = true;
        this.productMappingList[index].isDistributorReadOnly = false;
        this.primaryCustomerList = this.executiveWiseAccounts[userid];
        this.productMappingList[index].Chanel__c = '';
    }

    //Territory Search 
    handleAreaSearch(event){
        const index = event.target.dataset.index;
        const searchValueName = event.target.value?.trim().toLowerCase() || '';
        const salesChannel = this.productMappingList[index].Chanel__c?.toLowerCase() || ''; 

        if (searchValueName) {
            const objData = this.areas || [];
            const searchedData = [];
            if(objData)
            {
                for (let i = 0; i < objData.length; i++) {
                    const objName = objData[i];
                    const nameMatch = objName.Name?.toLowerCase().includes(searchValueName);
                    const channelMatch = objName.Sales_Channel__c?.toLowerCase() === salesChannel;

                    if (nameMatch && channelMatch) {
                        searchedData.push(objName);
                        if (searchedData.length >= 50) break;
                    }
                }
            }

            this.productMappingList[index].isShowAreaValues = searchedData.length > 0;
            this.searchedAreas = searchedData;
        } 
        else
        {
            this.productMappingList[index].isShowAreaValues = false;
            this.productMappingList[index].Area_Name__c = '';
            this.productMappingList[index].Area__c = '';
            this.productMappingList[index].PDP_Name__c = '';
            this.productMappingList[index].PDP_Day__c = '';
            this.productMappingList[index].disablePDPDay = true;
            this.productMappingList[index].isTerritoryReadOnly = false;
          
        }

    }
    selectArea(event)
    {
        const index = event.currentTarget.dataset.index;
        this.productMappingList[index].Area__c = event.currentTarget.dataset.id;
        this.productMappingList[index].Area_Name__c = event.currentTarget.dataset.name;
        this.productMappingList[index].isShowAreaValues = false;
        this.productMappingList[index].disablePDPDay = false;
        this.productMappingList[index].isTerritoryReadOnly = true;
    }

    //Primary Customer Search
    handlePrimaryCustomerSearch(event){
        const index = event.target.dataset.index;
        let searchValueName = event.target.value;
        const userid = this.productMappingList[index].Exectuive__c;
        if(searchValueName){
            let objData = this.executiveWiseAccounts[userid] || [];
            let searchedData = [];
            if(objData)
            {
                for (let i = 0; i < objData.length; i++) {
                    const objName = objData[i];
                    // If Substockiest, filter only Superstockiest
                    if (this.isSubstockiest && objName.Primary_Customer_Type__c !== 'Superstockiest') {
                        continue;
                    }

                    const nameMatch = objName.Name && objName.Name.toLowerCase().includes(searchValueName.toLowerCase());
                    const sapCode = objName.SAP_Customer_Code__c || '';
                    const sapCodeMatch = sapCode.toLowerCase().includes(searchValueName.toLowerCase());
                
                    if (nameMatch || sapCodeMatch) {
                        searchedData.push(objName);
                        if (searchedData.length >= 50) break; // Limit to 50 matches
                    }
                }
            }
            this.productMappingList[index].isShowPrimaryCustomerValues = searchedData != 0 ? true : false;
            this.serchedProductPrimaryCustomers = searchedData;
        }
        else
        {
            this.productMappingList[index].isShowPrimaryCustomerValues = false;
            this.productMappingList[index].Primary_Customer_Name__c= '';
            this.productMappingList[index].Primary_Customer__c = '';
            this.productMappingList[index].isDistributorReadOnly = false;
            this.productMappingList[index].isSubstockiestDisabled = true;
            this.productMappingList[index].Sub_Stockiest__c = '';
            this.productMappingList[index].Sub_Stockiest_Name__c = '';
            this.productMappingList[index].isSubStockiestReadOnly = false;
            this.searchedSubStockiests = [];
            this.productMappingList[index].isShowSubstockistValues = false;
        }

    }
    selectCustomer(event) {
        const index = event.currentTarget.dataset.index;
        const selectedCustomerId = event.currentTarget.dataset.customerid;
        const primarycustomerType = event.currentTarget.dataset.customertype; 
        const selectedExecutive =   this.productMappingList[index].Exectuive__c;

        //let accountData = this.accountData; 
        // If no duplicate, proceed to set the values
        this.productMappingList[index].Primary_Customer__c = selectedCustomerId;
        this.productMappingList[index].Primary_Customer_Name__c = event.currentTarget.dataset.name;
        this.productMappingList[index].isShowPrimaryCustomerValues = false;
        this.productMappingList[index].isDistributorReadOnly = true;
    
        this.searchedSubStockiests = [];
        this.productMappingList[index].isShowSubstockistValues = false;
        if( primarycustomerType == 'Superstockiest' && !this.showPrimaryfields
            &&   !this.isSubstockiest)
        {
            this.productMappingList[index].isSubstockiestDisabled = false;
            const subStockists = this.primaryToSubStockiestMap[selectedCustomerId] || [];
            const assignedSubstociestIds  = this.executiveToSubStockiestIds[selectedExecutive] || [];

            // Filter subStockists based on assignedSubstociestId
            const filteredSubStockists = subStockists.filter(acc => assignedSubstociestIds.includes(acc.Id));

            this.productMappingList[index].relatedSubStockiest = filteredSubStockists || [];
        }
        else
        {
            this.productMappingList[index].isSubstockiestDisabled = true;
            this.productMappingList[index].relatedSubStockiest = [];
        }
    }
  
    //Sub Stockiest Search
    handleSubstockiestSearch(event){
        const index = event.target.dataset.index;
        let searchValueName = event.target.value;
        if(searchValueName){
            let objData = this.productMappingList[index].relatedSubStockiest;
            let searchedData = [];
            if(objData)
            {
                for (let i = 0; i < objData.length; i++) {
                    const objName = objData[i];
                    const nameMatch = objName.Name && objName.Name.toLowerCase().includes(searchValueName.toLowerCase());
                    const code = objName.Customer_Code__c || '';
                    const codeMatch = code.toLowerCase().includes(searchValueName.toLowerCase());
                
                    if (nameMatch || codeMatch) {
                        searchedData.push(objName);
                        if (searchedData.length >= 50) break;
                    }
                }
            }
            this.productMappingList[index].isShowSubstockistValues = searchedData != 0 ? true : false;
            this.searchedSubStockiests = searchedData;
        }
        else
        {
            this.productMappingList[index].isShowSubstockistValues = false;
            this.productMappingList[index].Sub_Stockiest__c= '';
            this.productMappingList[index].Sub_Stockiest_Name__c = '';
            this.productMappingList[index].isSubStockiestReadOnly = false;
        }

    }
    selectSubStockiest(event)
    {
        const id = event.currentTarget.dataset.id;
        const index = event.currentTarget.dataset.index;
        const name = event.currentTarget.dataset.name;

        this.productMappingList[index].Sub_Stockiest__c = id;
        this.productMappingList[index].Sub_Stockiest_Name__c = name;
        this.productMappingList[index].isShowSubstockistValues = false;
        this.productMappingList[index].isSubStockiestReadOnly = true;
    }


    //Product Data Change
    handleInputProductMappingChange(event) {
        const index = event.target.dataset.index;
        const field = event.target.name;
        const value = event.detail.value;

        this.productMappingList = this.productMappingList.map((item, i) => {
            if (i == index) {
                let updatedItem = { ...item, [field]: value };
        
                if (field === 'Parent_Depot__c') {
                    updatedItem.Child_Depot__c = '';
                    updatedItem.childDeportOptions = this.getOptionsList(this.parentDeportChildDeportMap[value] || []);
                    updatedItem.disableChildDeprort = false;
                } 
                else if (field === 'Payment_Type__c') {
                    updatedItem.mandateCreditField = value === 'Credit';
                } 
                else if (field === 'Payment_Term__c') {
                    const creditDescriptionMap = this.paymentTermCreditDescriptionMap[value] || {};
                    updatedItem.creditDescriptions = this.getOptionsList(creditDescriptionMap);
                    const firstValue = Object.values(creditDescriptionMap)[0]; // Set first value
                    updatedItem.Credit_Description__c = firstValue || '';
                }
                else if (field === 'Chanel__c') {
                    // Get Executive Id from current row
                    const executiveId = item.Exectuive__c;
                    console.log('executiveId'+executiveId);
                    if (executiveId && this.executives && this.areas) {
                        // Find executive record
                        const executiveRecord = this.executives.find(exec => exec.Id === executiveId);
                        if (executiveRecord && executiveRecord.Territory__c && executiveRecord.Territory_Name__c) {
                            // Find territory record by Id
                            const territoryRecord = this.areas.find(area => area.Id === executiveRecord.Territory__c);
                            if (territoryRecord) {
                                // Compare Sales_Channel__c with selected channel value
                                if (
                                    territoryRecord.Sales_Channel__c &&
                                    territoryRecord.Sales_Channel__c.toLowerCase() === value.toLowerCase()
                                ) {
                                    updatedItem.Area__c = executiveRecord.Territory__c;
                                    updatedItem.Area_Name__c = executiveRecord.Territory_Name__c;
                                    updatedItem.isShowAreaValues = false;
                                    updatedItem.isTerritoryReadOnly = true;
                                }
                                else
                                {
                                    updatedItem.Area__c = '';
                                    updatedItem.Area_Name__c = '';
                                    updatedItem.isShowAreaValues = false;
                                    updatedItem.isTerritoryReadOnly = false;
                                }
                            }
                        }
                    }

                    updatedItem.Order_Type__c = this.getOrderTypeFromDependency(
                        updatedItem.Chanel__c,
                        updatedItem.Division__c,
                        this.paymentType,
                        this.orderTypeDependencyList
                    );


                }
                else if(field === 'Division__c')
                {
                    updatedItem.Order_Type__c = this.getOrderTypeFromDependency(
                        updatedItem.Chanel__c,
                        updatedItem.Division__c,
                        this.paymentType,
                        this.orderTypeDependencyList
                    );
                }
        
                return updatedItem;
            }
            return item;
        });
        
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
    //Add Product Mapping Item
    addProductMappingRow() {
        const newIndex = Number(this.productMappingList.length);
        console.log(newIndex);
        const newRow =  {
            sObjectType: 'Product_Mapping__c',
            Id: null,
            index:newIndex,
            Area__c: null,
            Area_Name__c: null,
            Exectuive__c: null,
            Executive_Name__c:null,
            Parent_Depot__c:'',
            Child_Depot__c:'',
            Chanel__c:'',
            PDP_Name__c:'',
            PDP_Day__c:'',
            Payment_Type__c:'',
            Payment_Term__c:'',
            Credit_Description__c:'',
            Inco_Terms__c:'',
            Credit_Limit__c:'',
            creditDescriptions:[],
            childDeportOptions:[],
            disableChildDeprort:true,
            isShowExecutiveValues:false,
            isShowAreaValues:false,
            isShowPDPDayValues:false,
            disablePDPDay:true,
            Customer__c:this.currentRecordId,
            mandateCreditField:false,
            Primary_Customer_Name__c:'',
            Primary_Customer__c:'',
            isShowPrimaryCustomerValues:false,
            productMappingchannelOptions :[],
            isExecutiveReadOnly:false,
            isTerritoryReadOnly:false,
            isDistributorReadOnly:false,

            isSubstockiestDisabled :true,
            relatedSubStockiest:[],
            Sub_Stockiest__c:'',
            Sub_Stockiest_Name__c:'',
            isShowSubstockistValues:false,
            isSubStockiestReadOnly:false,
         }
        this.productMappingList = [...this.productMappingList, newRow];
         this.primaryCustomerList = [];
    }
    removeProductMappingRow(event) {
        const index = Number(event.target.dataset.index);

        // If only one row is left, clear its values using querySelector
        if (this.productMappingList.length === 1) {
            const rowElements = this.template.querySelectorAll(`[data-id="productMapping"]`);
            rowElements.forEach(input => {
                input.value = ''; // Manually clear input fields
            });

            if (this.productMappingList[index].Id) {
                this.deleteProductMappingList = [...(this.deleteProductMappingList || []), this.productMappingList[index].Id];
            }

            // Reset the only row instead of deleting it
            this.productMappingList = [{
                sObjectType: 'Product_Mapping__c',
                Id: null,
                Customer__c:this.currentRecordId,
                index:1,
                Area__c: null,
                Area_Name__c: null,
                Exectuive__c: null,
                Executive_Name__c:null,
                Parent_Depot__c:'',
                Child_Depot__c:'',
                Chanel__c:'',
                PDP_Name__c:'',
                PDP_Day__c:'',
                Payment_Type__c:'',
                Payment_Term__c:'',
                Credit_Description__c:'',
                Inco_Terms__c:'',
                Credit_Limit__c:'',
                creditDescriptions:[],
                childDeportOptions:[],
                disableChildDeprort:true,
                isShowExecutiveValues:false,
                isShowAreaValues:false,
                isShowPDPDayValues:false,
                disablePDPDay:true,
                mandateCreditField:false,
                Primary_Customer_Name__c:'',
                Primary_Customer__c:'',
                isShowPrimaryCustomerValues:false,
                productMappingchannelOptions :[],
                isExecutiveReadOnly:false,
                isTerritoryReadOnly:false,
                isDistributorReadOnly:false,

                isSubstockiestDisabled :true,
                relatedSubStockiest:[],
                Sub_Stockiest__c:'',
                Sub_Stockiest_Name__c:'',
                isShowSubstockistValues:false,
                isSubStockiestReadOnly:false,
             }];
        } else {
            // Create a copy of wagelist to ensure reactivity
            let updatedList = [...this.productMappingList];

            if (updatedList[index].Id) {
                this.deleteProductMappingList = [...(this.deleteProductMappingList || []), updatedList[index].Id];
            }
            // Remove the selected row
            updatedList.splice(index, 1);
            
         

            // Assign the updated list to trigger reactivity
            this.productMappingList = updatedList;
        }
    }
    cloneProductMappingRow(event) {
        const index = Number(event.target.dataset.index);
        const itemToClone = this.productMappingList[index];
        let executiveId = itemToClone.Exectuive__c;

        // Deep clone the item
        const clonedItem = JSON.parse(JSON.stringify(itemToClone));

        // Set a new index and update any fields that need to be unique
        const newIndex = this.productMappingList.length;
        clonedItem.index = newIndex;
        clonedItem.Id = null;
        this.primaryCustomerList = this.executiveWiseAccounts[executiveId];

        // Add the cloned item to the list
        this.productMappingList = [...this.productMappingList, clonedItem];
    }


    //Save and Cancel and validate
    ValidateProductMappingFields() {
        if (!navigator.onLine) {
            this.showToast('Error', 'No internet connection. Please check your network and try again.', 'error');
            return;
        }
        let isAllValid = true;
        let productMappingList = [...this.productMappingList];
        let customerType = this.customerType;

        for (let index = 0; index < productMappingList.length; index++) {
            const item = productMappingList[index];
            if (customerType === 'Primary Customer') {
                if (
                    !item.Exectuive__c || !item.Area__c || 
                    !item.Chanel__c || !item.Parent_Depot__c || !item.Child_Depot__c ||
                    !item.Inco_Terms__c || !item.Sales_Office__c || 
                    !item.Order_Type__c || !item.Distribution_Channel__c || !item.Division__c
                ) {
                    this.showFieldError('productMapping');
                    this.showToast('Error', `Please fill in all the mandatory fields for product mapping item ${index + 1}`, 'error');
                    isAllValid = false;
                    return isAllValid;
                }

                if (this.mandatepaymentInfo && (!item.Payment_Term__c || !item.Credit_Description__c)) {
                    this.showFieldError('productMapping');
                    this.showToast('Error', `Please fill in all the mandatory fields for product mapping item ${index + 1}`, 'error');
                    isAllValid = false;
                    return isAllValid;
                }
            } else if (customerType === 'Secondary Customer') {
                if (!item.Exectuive__c) {
                    this.showFieldError('productMapping');
                    this.showToast('Error', `Please fill in all the mandatory fields for product mapping item ${index + 1}`, 'error');
                    isAllValid = false;
                    return isAllValid;
                }

                if (!item.Primary_Customer__c) {
                    this.showFieldError('Primary_Customer_Name');
                    this.showToast('Error', `Please fill in all the mandatory fields for product mapping item ${index + 1}`, 'error');
                    isAllValid = false;
                    return isAllValid;
                }
            }
        }

        // Step 2: Duplicate validation (ensure works for 2+ records)
        for (let i = 0; i < productMappingList.length; i++) {
            const item1 = productMappingList[i];

            for (let j = i + 1; j < productMappingList.length; j++) {
                const item2 = productMappingList[j];

                let isDuplicate = false;

                if (customerType === 'Primary Customer') {
                    isDuplicate =
                        String(item1.Exectuive__c || '') === String(item2.Exectuive__c || '') &&
                        String(item1.Area__c || '') === String(item2.Area__c || '') &&
                        String(item1.PDP_Day__c || '') === String(item2.PDP_Day__c || '') &&
                        String(item1.Chanel__c || '') === String(item2.Chanel__c || '') &&
                        String(item1.Parent_Depot__c || '') === String(item2.Parent_Depot__c || '') &&
                        String(item1.Child_Depot__c || '') === String(item2.Child_Depot__c || '') &&
                        String(item1.Inco_Terms__c || '') === String(item2.Inco_Terms__c || '') &&
                        String(item1.Sales_Office__c || '') === String(item2.Sales_Office__c || '') &&
                        String(item1.Order_Type__c || '') === String(item2.Order_Type__c || '') &&
                        String(item1.Distribution_Channel__c || '') === String(item2.Distribution_Channel__c || '') &&
                        String(item1.Division__c || '') === String(item2.Division__c || '');
                        String(item1.Payment_Term__c || '') === String(item2.Payment_Term__c || '');

                } else if (customerType === 'Secondary Customer') {
                    isDuplicate =
                        String(item1.Exectuive__c || '') === String(item2.Exectuive__c || '') &&
                        String(item1.Primary_Customer__c || '') === String(item2.Primary_Customer__c || '') &&
                        String(item1.Sub_Stockiest__c || '') === String(item2.Sub_Stockiest__c || '') ;
                }

                if (isDuplicate) {
                    this.showToast('Error', `Duplicate product mapping found at product mapping item  ${i + 1} with product mapping item  ${j + 1}`, 'error');
                      isAllValid = false;
                    return isAllValid;
                }
            }
        }

        return isAllValid;
    }
    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent('close'));
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.currentRecordId,
                objectApiName: 'Account', // Change to your object
                actionName: 'view'
            }
        });
    }
    handleSave() {
        if(this.ValidateProductMappingFields())
        {
            if (!navigator.onLine) {
                this.showToast('Error', 'No internet connection. Please check your network and try again.', 'error');
                return;
            }
            this.isLoading = true;
            saveProductData({productMappingList: this.productMappingList,deleteProductMappingList:this.deleteProductMappingList })
            .then(() => {
                    this.isLoading = false;
                    this.showToast('Success', 'Product mappings saved successfully', 'success');
                    
                     // Implement save functionality
                    this.dispatchEvent(new CloseActionScreenEvent('close'));
                    this[NavigationMixin.Navigate]({
                        type: 'standard__recordPage',
                        attributes: {
                            recordId: this.currentRecordId,
                            objectApiName: 'Account', // Change to your object
                            actionName: 'view'
                        }
                    });
                    this.dispatchEvent(new RefreshEvent());
            })
            .catch(error => {
                console.error(error);
                this.isLoading = false;
            });
        }
       
    }

    /**Helper Methods**/
    showFieldError(fieldPrefix) {
        const inputFields = this.template.querySelectorAll(`[data-id^="${fieldPrefix}"]`); 
        if (inputFields.length > 0) {
            inputFields.forEach(input => {
                input.reportValidity(); // Show validation error
            });
        }
    }
    //Genric method to get the picklist values
    populateOptions(dataList, labelField, valueField) {
        const options = dataList?.map(item => ({
            label: item[labelField],
            value: item[valueField]
        })) || [];
        return options;
    }
    getPicklistValues(optionsArray) { 
        return optionsArray.map(option => ({ label: option.Name, value: option.Id })); 
    }
    getPicklistValueFromList(optionsArray) {
        return optionsArray.map(option => ({ label: option, value: option }));
    }
    getOptionsList(optionsMap) {
        return Object.keys(optionsMap).map(label => ({
            label: label, 
            value: optionsMap[label] // Use API value instead of label
        }));
    }
    getOptionValuesWithNone(optionsArray)
    {
        const selectOption = { label: 'Select option', value: '' };
        return [selectOption, ...optionsArray];
    }
    dispatchToAura(textMessage,expenseId){
        // Created a custom event to Pass to aura component
        const event =  new CustomEvent('closepopup', {
            detail: {
                eventType: textMessage,
                Id:expenseId,
            },
          });
        this.dispatchEvent(event);
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
}