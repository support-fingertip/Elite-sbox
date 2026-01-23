import { LightningElement, track,api,wire  } from 'lwc';
import GET_ALL_DATA from '@salesforce/apex/newCustomerLwcController.getAllData';
import sendOTP from '@salesforce/apex/newCustomerLwcController.sendOtp';
import VALIDATE_FILE from '@salesforce/apex/newCustomerLwcController.validateFileUpload';
import DUPLICATOION_CHECK from '@salesforce/apex/CustomDuplicationService.dupicationCheck';
import Id from '@salesforce/user/Id';
import { loadScript } from 'lightning/platformResourceLoader';
import jsOTPResource from '@salesforce/resourceUrl/jsOTP';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import FORM_FACTOR from '@salesforce/client/formFactor';
import saveData from '@salesforce/apex/newCustomerLwcController.saveData';
import { NavigationMixin } from 'lightning/navigation';
import { getLocationService } from 'lightning/mobileCapabilities';


export default class NewCustomerLwc extends NavigationMixin(LightningElement) {

    // Tracks current step
    @api recordId;
    accountIdReturned ='';
    userId = Id;
    showPopup = true;
    OTPVerificationSkipCustomerTypes = '';
    backbuttonlabel='Cancel';
    proceedbuttonlabel='Proceed'
    @track currentStep = 'Customer Details'; 
    @track profileName;
    @track recordTypes = [];
    @track allRecordTypes = [];
    @track selectedRecordType;
    @track accountData = {
        sObjectType: 'Account',
        Name: '',
        Primary_Customer_Type__c: '',
        Secondary_Customer_Type__c: '',
        Distributor__c: '',
        Distributor_Name__c:'',
        Customer_Type__c: '',
        RecordTypeId:'',
        Primary_Customer_Business_Type__c: '',
        Secondary_Customer_Business_Type__c: '',
        Secondary_Customer_Category__c:'',
        Email_ID__c: '',
        Contact_Person_Name__c: '',
        Contact_Person_Phone__c: '',
        Aadhaar_No__c: '',
        OwnerId: '',
        Primary_Phone_Number__c: '',
        Secondary_Phone_Number__c: '',
        PAN_Number__c: '',
        GST_Number__c: '',
        Street__c: '',
        On_Customer_Premises__c: false,
        Pincode__c: '',
        UniqueFileId__c:'',
        OTP_Verification_Completed__c:false,
        OwnerId:this.userId,
        GeoLocation__Longitude__s:'',
        GeoLocation__Latitude__s:'',
        Account_Holder_Name__c:'',
        Bank_Name__c:'',
        Account_No__c:'',
        IFSC_Code__c:'',
        Branch_Name__c:'',
        Payment_Type__c:'',
        Payment_Term__c:'',
        Credit_Description__c:'',
        Credit_Limit__c:'',
        Inco_Terms__c:'',
        Reference_Contact_Name__c:'',
        Reference_Contact_Mobile__c:'',
        Reference_Email__c:'',
        Reference_Address__c:'',
        Expected_Turn_over_PA__c:'',
        Distribution_Channel__c:'',
        Order_Type__c:'',
        Division__c:'',
        State__c:'',
        District__c:'',
        High_Margin__c:'No',
        Customer_Group__c:'',
        Company_Name__c:'',
        Owner_Name__c:'',
        Security_Cheque_Status__c:'',
        Security_Amount__c:'',
        Door_No__c:'',
        Building_Name__c:'',
        Land_Mark__c:'',
        Is_Customer_Duplicate__c:false,
        City_Town__c:''
    };
    creditFieldMandate = false;
    showAccountScreen = true;
    showProductScreen = false;
    showCameraScreen = false;
    showVerificationScreen = false;
    showPrimaryfields = false;
    showSecoundaryfields = false;
    showSuccessScreen  = false;
    isLoading = false;
    isPageLoaded = false; 
    isDesktop = false;
    isPhone = false;
    labelvarient ='label-hidden';
    objectApiName = 'Account';
    containerClass ='slds-modal__container';
    customClass='slds-size_1-of-7 slds-p-horizontal_small';
    buttoncustomClass='slds-size_1-of-6 slds-p-horizontal_small';
    accountCustomClass = 'slds-size_1-of-2';
 

    //OTP
    otpValue = '';
    @track otpSendOptions = [];
    @track selectedOtpOption = '';
    @track otpValue = '';
    @track otpButtonLabel = 'Send CCN';
    @track disabled = false;
    @track showResendOtp = false;
    refreshCounter = 30;
    secret = '12345';
    code;
    @track otpSkipSalesChannels = '';
  
    interval;
    otpInputDisabled = true;
    callcustomerFileUpload = false;
    myLocationService;
    locationButtonDisabled = false;
    showHighMargin = false;
    mandatepaymentInfo = false;
    disablePaymentInfo = true;
    verifiedPhoneNumber = '';
    verifiedCode;

    //Sub Stockiest
    searchedSubStockiests = [];
    primaryToSubStockiestMap = {};
    isSubstockiest = false;
   

    //Product Mapping Fields
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
        isSubStockiestReadOnly:false
     },
    ];
    executives=[];
    searchedExecutives = [];
    areas=[];
    searchedAreas = [];
    serchedProductPrimaryCustomers = [];
    parentDeportChildDeportMap = {};
    paymentTermCreditDescriptionMap = {};
    paymenttypeToOrdertypeMap = {};
    userIdToSalesChannelsMap = {};
    ParentDeportOptions = [];
    chanelOptions = [];
    primaryCustomerList = [];
    paymentTypeList = [];
    incotermList = [];
    paymemtTermList = [];
    searchedPrimaryCustomers = [];
    isShowPrimaruCustomers = false;
    @track creditTermsOptions = [];
    PDPDays=[];
    searchedPDPDays = [];
    @track deleteProductMappingList = [];
    @track orderTypeList = [];
    @track salesOfficeList = [];
    @track distributonChannelList = [];
    @track divisionList = [];
    isPhoneNumberChanged = false;
    editCreditInformation = false;
    mapfirstExecutive = false;
    pdpDayList=[];
    
    //Beat Search
    beatList = [];
    searchedBeats = [];
    isShowBeats = false;
    isReadOnly = false;
    selectedBeat = '';
    lastScreenSelected = '';
    showBeat = false;
    
    currentUserId = '';
    currentUserName = '';
    isAdmin = false;
    executiveWiseAccounts = {};
    executiveToSubStockiestIds = {};
    assignedSubstockiest = [];
    orderTypeDependencyList = [];
    
    duplicationChecked = false; // new flag duplicateErrorFound = false; // for UI red button
    duplicateErrorFound = false; // for UI red button

    userSalesChannel = '';
    

    isMobilePublisher = window.navigator.userAgent.indexOf('CommunityHybridContainer') > 0;
    //On loading this method will be called
    connectedCallback() {
        this.isLoading=true;
        this.isDesktop = FORM_FACTOR === 'Large'? true : false;
        this.isPhone = FORM_FACTOR === 'Small'? true : false;
        if (FORM_FACTOR === 'Medium') this.isDesktop = true;
        this.isLoading = true; 
        this.containerClass = this.isDesktop ? 'slds-modal__container' : 'mobilePopup';
        this.accountCustomClass = this.isDesktop ? 'slds-size_1-of-2' : 'slds-size_1-of-1';
        this.customClass = this.isDesktop ? 'slds-size_1-of-7 inputcustompadding' : 'slds-size_1-of-1 slds-p-horizontal_xx-small';
        this.disablePullToRefresh();
        this.getAllData();
        
        loadScript(this, jsOTPResource).then(() => {
            this.isLoading=false;
        });
    }
  
    getAllData(){
        if (!navigator.onLine) {
            this.showToast('Error', 'No internet connection. Please check your network and try again.', 'error');
            return;
        }
        this.isLoading = true;
        GET_ALL_DATA({
        })
        .then(result => {
            this.allRecordTypes = result.RecordTypeList;
            this.recordTypes = this.populateOptions(result.RecordTypeList, 'Name', 'Name');
            this.isAdmin =  result.currentUserRecord.isAdmin__c;
            this.userSalesChannel =  result.currentUserRecord.Sales_Channel__c;
            
            this.executiveWiseAccounts = result.executiveWiseAccounts;
            this.executiveToSubStockiestIds = result.executiveToSubStockiestIds;
            //auto selection customer type for DSM
            if(result.RecordTypeList.length == 1)
            {
                this.accountData.Customer_Type__c = result.RecordTypeList[0].Name;
                this.accountData.RecordTypeId = result.RecordTypeList[0].Id;
                
                if (result.RecordTypeList[0].Name === 'Primary Customer') {
                    this.showPrimaryfields = true;
                }else if (result.RecordTypeList[0].Name === 'Secondary Customer') {
                    this.showSecoundaryfields = true;
                }
            }
            this.profileName = result.profileName;
        
            this.primaryToSubStockiestMap = result.primaryToSubStockiestMap;
            this.ParentDeportOptions = result.parentDeportList; 
            this.paymentTypeList =  result.paymentTypeList;
            this.incotermList =  result.incotermList;
            this.paymemtTermList = result.paymemtTermList;
            this.executives = result.userList;
            this.areas = result.areaList;
            this.beatList =  result.beatList;
            this.parentDeportChildDeportMap = result.parentDeportChildDeportMap || {};
            this.paymentTermCreditDescriptionMap = result.paymentTermCreditDescriptionMap || {};
            this.paymenttypeToOrdertypeMap = result.paymenttypeToOrdertypeMap || {};
            this.orderTypeDependencyList = result.orderTypeDependencyList || []; 
           // this.primaryCustomerList = result.primaryCustomerList;

            this.orderTypeList = result.orderTypeList;
            this.salesOfficeList = result.salesOfficeList;
            this.distributonChannelList = result.distributonChannelList;
            this.divisionList = result.divisionList;
            this.pdpDayList = this.getOptionValuesWithNone(result.pdpDayList);

            this.accountData.UniqueFileId__c = 'FILE-' + Date.now()+ '-' +this.userId + '-' + Math.random().toString(36).substring(2, 10);
            this.userIdToSalesChannelsMap = result.userIdToSalesChannelsMap;
            this.mapfirstExecutive = result.employeeAccess.Map_Executive_In_Product_Mapping__c;
            this.editCreditInformation = result.employeeAccess.Edit_Credit_Information__c;
            //Auto selection of executive for product mapping
            if( this.mapfirstExecutive ){
                this.currentUserId =  result.currentUserRecord.Id;
                this.currentUserName =  result.currentUserRecord.Name;
               // let userId = this.currentUserId;
                this.productMappingList[0].Executive_Name__c = this.currentUserName ;
                this.productMappingList[0].Exectuive__c = this.currentUserId;
                this.productMappingList[0].isExecutiveReadOnly = true;
            
                this.productMappingList[0].productMappingchannelOptions = this.getPicklistValueFromList(
                    this.userIdToSalesChannelsMap[this.currentUserId] || []
                );
                  
                this.primaryCustomerList = this.executiveWiseAccounts[this.currentUserId];
            }
            if( this.editCreditInformation)
            {
                this.mandatepaymentInfo = true;
                this.disablePaymentInfo = false;
            }
            this.OTPVerificationSkipCustomerTypes = result.OTPVerificationSkipCustomerTypes;
            this.otpSkipSalesChannels = result.OTPVerificationSkipSalesChannels;
            
          
            this.isLoading = false;
        })
        .catch(error => {
            console.error(error);
            this.isLoading = false;
        });
    }

    /**--------Customer Details Screen----------**/
    handleInputChangeChange(event) {
        const fieldName = event.target.fieldName;
        const fieldValue  = event.detail.value;
        // Dynamically update the field in accountData
        this.accountData = { ...this.accountData, [fieldName]: fieldValue };

        if(fieldName =='On_Customer_Premises__c' && fieldValue == false)
        {
            this.accountData = {
                ...this.accountData,
                GeoLocation__Latitude__s: '',
                GeoLocation__Longitude__s: ''
            };
        }
        else if(fieldName =='Payment_Type__c')
        {
            if(fieldValue == 'Credit')
            {
                this.creditFieldMandate = true;
            }
            else
            {
                this.creditFieldMandate = false;
            }
             // Update Order Type for each product mapping item
            let updatedList = this.productMappingList.map(item => {
                const updatedItem = { ...item };

                updatedItem.Order_Type__c = this.getOrderTypeFromDependency(
                    updatedItem.Chanel__c,
                    updatedItem.Division__c,
                    fieldValue, // Payment type just changed
                    this.orderTypeDependencyList
                );

                return updatedItem;
            });

            this.productMappingList = updatedList;
           
        }
        else if (fieldName === 'Payment_Term__c') {
            let creditDescriptionMap = this.paymentTermCreditDescriptionMap[fieldValue] || {};
            let firstKey = Object.keys(creditDescriptionMap)[0]; // Get the first key
            this.accountData.Credit_Description__c = firstKey || '';
            
        }
        else if (fieldName === 'Primary_Phone_Number__c') {
           
            this.duplicationChecked = false; // reset flag
            this.duplicateErrorFound = false; // reset error

            if (this.verifiedPhoneNumber == fieldValue) {
                this.showSuccessScreen = true;
                this.accountData.OTP_Verification_Completed__c = true;
            } else {
                if (this.interval) {
                    clearInterval(this.interval);
                    this.interval = null;
                }
                this.showSuccessScreen = false;
                this.accountData.OTP_Verification_Completed__c = false;
                this.otpValue = '';
                this.code = '';
                this.refreshCounter = 0;
                this.showResendOtp = false;
                this.disabled = false;
                this.otpInputDisabled = true;
                this.otpButtonLabel = 'Send CCN';
            }
        }
        else if(fieldName === 'Secondary_Customer_Type__c')
        {
            this.searchedBeats = [];
            this.accountData.Beat__c = '';
            this.isReadOnly = false;
            this.selectedBeat = '';
            if(fieldValue != 'Sub Stockiest')
            {
                this.showBeat = true;
                // Clear sub stockist fields for all items
                let productMappingList = [...this.productMappingList];
                productMappingList.forEach(item => {
                    item.isSubStockiestReadOnly = item.Sub_Stockiest__c ? true : false;
                    item.isSubstockiestDisabled = item.Primary_Customer__c ? false : true;
                });

                this.productMappingList = productMappingList;
                this.isSubstockiest = false;
            }
            else
            {
                this.showBeat = false;
                let productMappingList = [...this.productMappingList];

                // Keep only the first item and reset its Sub Stockist fields
                if (productMappingList.length > 0) {
                    let firstItem = { ...productMappingList[0] }; // Clone to avoid mutation
                    firstItem.Sub_Stockiest__c = '';
                    firstItem.Sub_Stockiest_Name__c = '';

                    // Reset the entire list to just this item
                    productMappingList = [firstItem];
                }

                this.productMappingList = productMappingList;
                this.isSubstockiest = true;

            }
            this.resetProudctMappingFields();
          
        }
        else if(fieldName == 'Customer_Group__c')
        {
           // console.log(JSON.stringify(fieldValue));
            if (fieldValue) {
                const actualValue = Array.isArray(fieldValue) ? fieldValue[0] : fieldValue;
                this.accountData.Customer_Group__c = actualValue;
            } else {
                this.accountData.Customer_Group__c = '';
            }
          
        }
    
    }
    handleCustomerChange(event)
    {
        const fieldName = event.target.name;
        console.log('fieldName'+fieldName);
        const fieldValue  = event.detail.value;
        console.log('fieldValue'+fieldValue);
        // Dynamically update the field in accountData
        const recordType = this.allRecordTypes.find(rt => rt.Name === fieldValue);
        if (recordType) {
            this.accountData.RecordTypeId = recordType.Id;
        }
        this.accountData = { ...this.accountData, [fieldName]: fieldValue };
        
        if (fieldName === 'Customer_Type__c') {
            this.searchedBeats = [];
            this.accountData.Beat__c = '';
            this.isReadOnly = false;
            this.selectedBeat = '';
            // Reset both fields
            this.showPrimaryfields = false;
            this.showSecoundaryfields = false;
            // Update visibility based on selection
            if (fieldValue === 'Primary Customer') {
                this.showPrimaryfields = true;
                this.showBeat = true;
                this.accountData.Secondary_Customer_Type__c = '';
                this.accountData.Secondary_Customer_Business_Type__c = '';
                this.accountData.Secondary_Customer_Category__c = '';
                this.accountData.High_Margin__c = '';

            } else if (fieldValue === 'Secondary Customer') {
                this.accountData.Primary_Customer_Business_Type__c = '';
                this.accountData.Primary_Customer_Type__c = '';
                this.accountData.Payment_Type__c = '';
                this.accountData.Credit_Limit__c = '';
                this.accountData.Expected_Turn_over_PA__c = '';
                this.showSecoundaryfields = true;
                if(this.isAdmin)
                {
                    this.showHighMargin = true;
                }
                
            }
            this.resetProudctMappingFields();
            this.accountData.Beat__c = '';
            this.selectedBeat = '';
        }
    }
    //Distbutor Search
    handleDistributorSearch(event){
        const index = event.target.dataset.index;
        let searchValueName = event.target.value;
        if(searchValueName){
            let objData = this.primaryCustomerList;
            let searchedData = [];
            for (let i = 0; i < objData.length; i++) {
                const objName = objData[i];
                if ((objName.Name && objName.Name.toLowerCase().indexOf(searchValueName.toLowerCase()) !== -1)) {
                    searchedData.push(objName);
                }
            }
            this.isShowPrimaruCustomers = searchedData != 0 ? true : false;
            this.searchedPrimaryCustomers = searchedData;
        }
        else
        {
            this.isShowPrimaruCustomers = false;
            this.accountData.Distributor_Name__c = '';
            this.accountData.Distributor__c = '';
        }

    }
    selectDistributor(event)
    {
        console.log('Name'+event.currentTarget.dataset.name);
        console.log('index'+event.currentTarget.dataset.index);
        this.accountData.Distributor_Name__c = event.currentTarget.dataset.name;
        this.accountData.Distributor__c = event.currentTarget.dataset.id; 
        this.isShowPrimaruCustomers = false;
    }

    // Beat Search 
    handleBeatSearch(event) {
        let searchValueName = event.target.value;
        const customerType = this.accountData.Customer_Type__c;
        const secoundaryCustomerType = this.accountData.Secondary_Customer_Type__c;

        if (searchValueName) {
            let objData = this.beatList;
            let searchedData = [];

            for (let i = 0; i < objData.length; i++) {
                const objName = objData[i];
                const isPrimaryCustomer = customerType === 'Primary Customer';

                let beatTypeMatch = false;

                if (isPrimaryCustomer) {
                    beatTypeMatch = objName.Beat_Type__c === 'Primary';
                } else {
                    // If Secondary Customer Type is Sub Stockiest, apply specific logic
                    if (secoundaryCustomerType === 'Sub Stockiest') {
                        console.log('   objName.Beat_Type__c '+   objName.Beat_Type__c );
                         console.log('objName.Primary_Customer_Type__c '+objName.Primary_Customer_Type__c );
                          console.log(objName.Sub_Stockist__c);
                           console.log(objName.Name);
                        beatTypeMatch =
                            objName.Beat_Type__c === 'Secondary' &&
                            objName.Primary_Customer_Type__c === 'Superstockiest' &&
                            (!objName.Sub_Stockist__c || objName.Sub_Stockist__c === '');
                    } else {
                        // Generic secondary customer logic
                        beatTypeMatch = objName.Beat_Type__c === 'Secondary';
                    }
                }

                if (
                    beatTypeMatch &&
                    objName.Name &&
                    objName.Name.toLowerCase().includes(searchValueName.toLowerCase())
                ) {
                    searchedData.push(objName);
                    if (searchedData.length >= 50) break;
                }
            }

            this.isShowBeats = searchedData.length > 0;
            this.searchedBeats = searchedData;
        } else {
            this.isShowBeats = false;
            this.searchedBeats = [];
            this.accountData.Beat__c = '';
            this.selectedBeat = '';
            this.isReadOnly = false;
        }
    }

    selectBeat(event) {
        this.isShowBeats = false;
        this.isReadOnly = true;
        this.searchedBeats = [];

        const dataset = event.currentTarget.dataset;
        const firstItem = this.productMappingList[0];

        this.accountData.Beat__c = dataset.id;
        this.selectedBeat = dataset.name;
        const customerType = this.accountData.Customer_Type__c;
        //Only For Secoundary Customer We need to auto select the Primary customer and Substockies
        if(customerType == 'Secondary Customer')
        {
            const primaryCustomer = dataset.primarycustomer;
            const primaryCustomerName = dataset.primarycustomername;
            const primaryCustomerType = dataset.primarycustomertype;
            const subStockiest = dataset.substockiest;
            const subStockiestName = dataset.substockiestname;
            const ownerName = dataset.ownername;
            const OwnerId = dataset.ownerid;

            if (primaryCustomer) {
                firstItem.Primary_Customer__c = primaryCustomer;
                firstItem.Primary_Customer_Name__c = primaryCustomerName || '';
                firstItem.isShowPrimaryCustomerValues = false;
                firstItem.isDistributorReadOnly = true;

                if(ownerName && OwnerId)
                {
                    firstItem.Executive_Name__c = ownerName;
                    firstItem.Exectuive__c = OwnerId;
                }

                if (primaryCustomerType === 'Superstockiest') {
                    firstItem.isSubstockiestDisabled = false;
                   // firstItem.relatedSubStockiest = this.primaryToSubStockiestMap[primaryCustomer] || [];

                    const subStockists = this.primaryToSubStockiestMap[primaryCustomer] || [];
                    const assignedSubstociestIds  = this.executiveToSubStockiestIds[OwnerId] || [];

                    // Filter subStockists based on assignedSubstociestId
                    const filteredSubStockists = subStockists.filter(acc => assignedSubstociestIds.includes(acc.Id));
                    firstItem.relatedSubStockiest = filteredSubStockists || [];

                } else {
                    firstItem.isSubstockiestDisabled = true;
                    firstItem.relatedSubStockiest = [];
                    firstItem.Sub_Stockiest__c = '';
                    firstItem.Sub_Stockiest_Name__c = '';
                }
            } else {
                firstItem.isDistributorReadOnly = false;
                firstItem.isSubstockiestDisabled = true;
                firstItem.Primary_Customer__c = '';
                firstItem.Primary_Customer_Name__c = '';
                firstItem.Sub_Stockiest__c = '';
                firstItem.Sub_Stockiest_Name__c = '';
            }

            if (subStockiest && primaryCustomer) {
                firstItem.Sub_Stockiest__c = subStockiest;
                firstItem.Sub_Stockiest_Name__c = subStockiestName || '';
                firstItem.isShowSubstockistValues = false;
                firstItem.isSubStockiestReadOnly = true;
            } else {
                firstItem.Sub_Stockiest__c = '';
                firstItem.Sub_Stockiest_Name__c = '';
            }
        
        }
    }



    /**--------Product Mapping Screeen--------**/
    //Executive Search
    handleExectieSearch(event){
        const index = event.target.dataset.index;
        let searchValueName = event.target.value;
        const customerType = this.accountData.Customer_Type__c;
        let isPrimaryCustomer = customerType === 'Primary Customer';
        if(searchValueName){
            let objData = this.executives;
            let searchedData = [];
            for (let i = 0; i < objData.length; i++) {
                const objName = objData[i];
                // Skip if customer is Primary and executive is SSA/DSM
                if ( isPrimaryCustomer && objName.Is_SSA_DSM__c === true) {
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
            this.productMappingList[index].isExecutiveReadOnly = false;
            this.productMappingList[index].Primary_Customer__c = '';
            this.productMappingList[index].Primary_Customer_Name__c = '';
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
        this.primaryCustomerList = [];
        const index = event.currentTarget.dataset.index;
        const userid = event.currentTarget.dataset.id;
        
        
        this.productMappingList[index].Exectuive__c = userid
        this.productMappingList[index].Executive_Name__c = event.currentTarget.dataset.name;
        this.productMappingList[index].isShowExecutiveValues = false;
        this.productMappingList[index].productMappingchannelOptions = this.getPicklistValueFromList(
            this.userIdToSalesChannelsMap[userid] || []
        );
        this.productMappingList[index].isExecutiveReadOnly = true;
        this.productMappingList[index].isDistributorReadOnly = false;
        this.primaryCustomerList = this.executiveWiseAccounts[userid];

        

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

        let accountData = this.accountData; 
        // If no duplicate, proceed to set the values
        this.productMappingList[index].Primary_Customer__c = selectedCustomerId;
        this.productMappingList[index].Primary_Customer_Name__c = event.currentTarget.dataset.name;
        this.productMappingList[index].isShowPrimaryCustomerValues = false;
        this.productMappingList[index].isDistributorReadOnly = true;
    
        this.searchedSubStockiests = [];
        this.productMappingList[index].isShowSubstockistValues = false;
        if( primarycustomerType == 'Superstockiest' && accountData.Customer_Type__c === 'Secondary Customer'
            && accountData.Secondary_Customer_Type__c != 'Sub Stockiest')
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
                    if( this.editCreditInformation)
                    {
                    
                        updatedItem.mandateCreditField = value === 'Credit';
                    }
                } 
                else if (field === 'Payment_Term__c') {
                    const creditDescriptionMap = this.paymentTermCreditDescriptionMap[value] || {};
                    updatedItem.creditDescriptions = this.getOptionsList(creditDescriptionMap);
                    const firstValue = Object.values(creditDescriptionMap)[0]; // Set first value
                    updatedItem.Credit_Description__c = firstValue || '';
                }
                else if (field === 'Chanel__c') {
                    updatedItem.Area__c = '';
                    updatedItem.Area_Name__c = '';
                    updatedItem.isShowAreaValues = false;
                    updatedItem.isTerritoryReadOnly = false;
                    // Get Executive Id from current row
                    const executiveId = item.Exectuive__c;
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
                            }
                        }
                    }

                    updatedItem.Order_Type__c = this.getOrderTypeFromDependency(
                        updatedItem.Chanel__c,
                        updatedItem.Division__c,
                        this.accountData?.Payment_Type__c,
                        this.orderTypeDependencyList
                    );


                }
                else if(field === 'Division__c')
                {
                    updatedItem.Order_Type__c = this.getOrderTypeFromDependency(
                        updatedItem.Chanel__c,
                        updatedItem.Division__c,
                        this.accountData?.Payment_Type__c,
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
        
        const newRow = {
            Id: null,
            Customer__c: null,
            index: newIndex,
            Area__c: null,
            Area_Name__c: null,
            Exectuive__c: null,
            Executive_Name__c: null,
            Parent_Depot__c: '',
            Child_Depot__c: '',
            Chanel__c: '',
            PDP_Name__c: '',
            PDP_Day__c: '',
            Payment_Type__c: '',
            Payment_Term__c: '',
            Credit_Description__c: '',
            Inco_Terms__c: '',
            Credit_Limit__c: '',
            creditDescriptions: [],
            childDeportOptions: [],
            disableChildDepot: true,
            isShowExecutiveValues: false,
            isShowAreaValues: false,
            isShowPDPDayValues: false,
            disablePDPDay: true,
            mandateCreditField: false,
            Primary_Customer_Name__c: '',
            Primary_Customer__c: '',
            isShowPrimaryCustomerValues: false,
            productMappingchannelOptions: [],
            Order_Type__c: '',
            Distribution_Channel__c: '',
            Sales_Office__c: '',
            Division__c: '',
            isExecutiveReadOnly:false,
            isTerritoryReadOnly:false,
            isDistributorReadOnly:false,
            isSubstockiestDisabled:true,
            relatedSubStockiest:[],
            Sub_Stockiest__c:'',
            Sub_Stockiest_Name__c:'',
            isShowSubstockistValues:false,
            isSubStockiestReadOnly:false,
        };
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
            this.resetProudctMappingFields();


        } else {
            // Create a copy of productMappingList to ensure reactivity
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

    resetProudctMappingFields()
    {
        // Reset the only row instead of deleting it
        this.productMappingList = [{
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
            productMappingchannelOptions:[],
            Order_Type__c:'',
            Distribution_Channel__c:'',
            Sales_Office__c:'',
            Division__c:'',
            isExecutiveReadOnly:false,
            isTerritoryReadOnly:false,
            isDistributorReadOnly:false,
            isSubstockiestDisabled:true,
            relatedSubStockiest:[],
            Sub_Stockiest__c:'',
            Sub_Stockiest_Name__c:'',
            isShowSubstockistValues:false,
            isSubStockiestReadOnly:false,
        }];
        if( this.mapfirstExecutive ){
            this.productMappingList[0].Executive_Name__c = this.currentUserName ;
            this.productMappingList[0].Exectuive__c = this.currentUserId;
            this.productMappingList[0].isExecutiveReadOnly = true;
            this.productMappingList[0].productMappingchannelOptions = this.getPicklistValueFromList(
                this.userIdToSalesChannelsMap[this.currentUserId] || []
            );
        }
    }

    /**----------OTP Screen----------**/
    handleOtpOptionChange(event) {
        this.selectedOtpOption = event.detail.value;
    }
    handleOtpChange(event) {
        this.otpValue = event.target.value;
    }
    handleOtpButtonClick() {
        if (this.otpButtonLabel === 'Send CCN') {
            this.generateOTP();
        } else {
            this.verifyOTP();
        }
    }
    generateOTP() {
        if (!navigator.onLine) {
            this.showToast('Error', 'No internet connection. Please check your network and try again.', 'error');
            return;
        }
        if (!this.selectedOtpOption) {
            this.showToast('Error', 'Please select an CCN send option.', 'error');
            return;
        }

        this.code = new jsOTP.totp().getOtp(this.secret);
      
        this.isLoading = true;
        sendOTP({ mobileNo: this.selectedOtpOption, OTP: this.code })
            .then((result) => {
                if(result)
                {
                    this.showToast('Success', 'CCN has been sent successfully.', 'success');
                    this.otpButtonLabel = 'Verify CCN';
                    this.disabled = true;
                    this.otpInputDisabled = false;
                  
                    this.startResendTimer();
                }
                else
                {
                    this.showToast('Error', 'Failed to send CCN. Try again later.', 'error');
                }
                this.isLoading = false;
            
            })
            .catch(() => {
                this.showToast('Error', 'Failed to send CCN. Try again later.', 'error');
            });
    }
    startResendTimer() {
        this.refreshCounter = 30;
        this.showResendOtp = false;
        
        this.interval = setInterval(() => {
            this.refreshCounter--;
            if (this.refreshCounter === 0) {
                this.disabled = false;
                this.showResendOtp = true;
                clearInterval(this.interval);
            }
        }, 1000);
    }
    verifyOTP() {
        if(!this.otpValue){
            this.showFieldError('otpField'); 
            this.showToast('Error', 'Please enter the CCN', 'error');
        }
        else if(!this.code)
        {
            this.showToast('Error', 'Please resend the CCN again.', 'error');
        }
        else if (this.otpValue.trim() === this.code) {
            this.accountData.OTP_Verification_Completed__c = true;
            this.verifiedPhoneNumber =  this.accountData.Primary_Phone_Number__c;
            this.showSuccessScreen = true;
            this.showToast('Success', 'Verification complete! Proceed with saving', 'success');
        } else if(this.otpValue != this.code){
            this.showToast('Error', 'Incorrect CCN. Please try again.', 'error');
        }
    }
    
    /**---------Buttons Section----------*/
    handleProceed() {
        if (!navigator.onLine) {
            this.showToast('Error', 'No internet connection. Please check your network and try again.', 'error');
            return;
        }
        this.resetScreens();

        const { currentStep, accountData } = this;
        const isPrimary = accountData.Customer_Type__c === 'Primary Customer';
        const isSecondary = accountData.Customer_Type__c === 'Secondary Customer';
        const isPremises = accountData.On_Customer_Premises__c === true;

        if (currentStep === 'Customer Details') {
            if (this.validateAccountFields()) {
                if (!this.duplicationChecked) {
                    this.duplicationCheck();
                } else if (this.duplicateErrorFound) {
                    this.accountData.Is_Customer_Duplicate__c = true;
                    // On second click after error → just move forward
                    this.proceedToProductMapping();
                }
                else
                {
                    this.accountData.Is_Customer_Duplicate__c = false;
                    // On second click after error → just move forward
                    this.proceedToProductMapping();
                }
            } else {
                this.showAccountScreen = true;
            }
        }

        else if (currentStep === 'Product Mapping') {
            if (isPrimary || (isSecondary && isPremises)) {
                if (!this.ValidateProductMappingFields()) {
                    this.showProductScreen = true;
                    return;
                }

                this.isLoading = true;

                if (isPremises) {
                    this.getUserLocation()
                        .then(() => {
                            this.navigateToPhotoUpload();
                        })
                        .catch((locationError) => {
                            this.isLoading = false;
                            this.showProductScreen = true;
                            this.showToast('Error', locationError, 'error');
                        });
                } else {
                  
                    this.navigateToPhotoUpload();
                }
            }

            else if (isSecondary && !isPremises) {
                if (!this.ValidateProductMappingFields()) {
                    this.showProductScreen = true;
                    return;
                }

                const otpSkipSalesChannels =  this.otpSkipSalesChannels.split(',').map(s => s.trim());
                const executiveSalesChannel =  this.userSalesChannel.split(';').map(s => s.trim());
                
                // Check if Sales Channel condition matches
                const skipBySalesChannel = executiveSalesChannel.some(sc => otpSkipSalesChannels.includes(sc));

                if (skipBySalesChannel) {
                    this.handleSave();
                }else 
                {
                    this.currentStep = 'CCN Verification';
                    this.showVerificationScreen = true;
                    this.proceedbuttonlabel = 'Save';
                    this.backbuttonlabel = 'Previous';

                    // Set OTP option from phoe number
                    const phonenumber = accountData.Primary_Phone_Number__c;
                    if (phonenumber) {
                        this.otpSendOptions = [{ label: phonenumber, value: phonenumber }];
                        this.selectedOtpOption = phonenumber;
                    }
                }

            }
        }

        else if (currentStep === 'Photo Upload') {
            this.validateFileUpload();
        }

        else if (currentStep === 'CCN Verification') {
            if (accountData.OTP_Verification_Completed__c) {
                this.handleSave();
            } else {
                this.showVerificationScreen = true;
                this.showToast('Error', 'Please enter the CCN to complete customer verification', 'error');
            }
        }
    }
    handlePrevious() {
        this.resetScreens();
        this.isLoading = false;
        if (this.currentStep === 'CCN Verification' &&(this.accountData.Customer_Type__c === 'Primary Customer' 
            || (this.accountData.On_Customer_Premises__c == true && this.accountData.Customer_Type__c === 'Secondary Customer'))){
            this.currentStep = 'Photo Upload';
            this.showCameraScreen = true;
            this.proceedbuttonlabel='Proceed';
            this.backbuttonlabel='Previous';
        }
        else if ((this.currentStep === 'CCN Verification' && this.accountData.On_Customer_Premises__c == false && this.accountData.Customer_Type__c === 'Secondary Customer' )
                 ||this.currentStep === 'Photo Upload') {
            this.currentStep = 'Product Mapping';
            this.showProductScreen = true;
            this.proceedbuttonlabel='Proceed';
            this.backbuttonlabel='Previous';
        } 
        else if(this.currentStep === 'Product Mapping' ) {
            this.currentStep = 'Customer Details';
            this.showAccountScreen = true;
            this.proceedbuttonlabel='Proceed';
            this.backbuttonlabel='Cancel';
        }
        else if(this.currentStep === 'Customer Details') {
            this.dispatchToAura('Cancel',null);
        }
        
    }

    /** Helper to navigate to Photo Upload screen */
    navigateToPhotoUpload() {
        this.isLoading = false;
        this.currentStep = 'Photo Upload';
        this.showCameraScreen = true;

        const otpSkipTypes =  this.OTPVerificationSkipCustomerTypes.split(',').map(s => s.trim());
        const otpSkipSalesChannels =  this.otpSkipSalesChannels.split(',').map(s => s.trim());
        const executiveSalesChannel =  this.userSalesChannel.split(';').map(s => s.trim());
        const primaryType = this.accountData.Primary_Customer_Type__c;

        // Check if Customer Type condition matches
        const skipByType = (this.accountData.Customer_Type__c === 'Primary Customer' 
                            && otpSkipTypes.includes(primaryType));
        const isPremises = this.accountData.On_Customer_Premises__c === true;
        // Check if Sales Channel condition matches
        const skipBySalesChannel = executiveSalesChannel.some(sc => otpSkipSalesChannels.includes(sc));

        if (skipByType || (skipBySalesChannel && this.isAdmin)) {
            this.proceedbuttonlabel = 'Save';
        } 
        else if(skipBySalesChannel && this.accountData.Customer_Type__c !='Primary Customer')
        {
            this.proceedbuttonlabel = 'Save';
        }
        else {
            this.proceedbuttonlabel = 'Proceed';
        }

        this.backbuttonlabel = 'Previous';
    }
    
    //Get Location
    getUserLocation() {
        return new Promise((resolve, reject) => {
            const timeoutMs = 16000; // 16 seconds
            let didRespond = false;
    
            const timeout = setTimeout(() => {
                if (!didRespond) {
                    didRespond = true;
                    reject('Please enable location permission to continue.');
                }
            }, timeoutMs);
    
            if (this.isMobilePublisher) {
                this.myLocationService = getLocationService();
                if (this.myLocationService && this.myLocationService.isAvailable()) {
                    this.myLocationService.getCurrentPosition({ enableHighAccuracy: true })
                        .then((result) => {
                            if (!didRespond) {
                                clearTimeout(timeout);
                                this.updateGeoLocation(result.coords.latitude, result.coords.longitude);
                                didRespond = true;
                                resolve(true);
                            }
                        })
                        .catch((error) => {
                            if (!didRespond) {
                                clearTimeout(timeout);
                                console.error('Error fetching location (Mobile Publisher):', JSON.stringify(error));
                                didRespond = true;
                                reject('Please enable location permission to continue.');
                            }
                        });
                } else {
                    clearTimeout(timeout);
                    reject('Location service is unavailable. Please enable permissions.');
                }
            } else if (navigator.geolocation) {
                navigator.geolocation.getCurrentPosition(
                    (r) => {
                        if (!didRespond) {
                            clearTimeout(timeout);
                            if (r && r.coords) {
                                this.updateGeoLocation(r.coords.latitude, r.coords.longitude);
                                didRespond = true;
                                resolve(true);
                            } else {
                                didRespond = true;
                                reject('Unable to fetch location. Please enable location services.');
                            }
                        }
                    },
                    (err) => {
                        if (!didRespond) {
                            clearTimeout(timeout);
                            console.error('Error fetching location (Browser):', JSON.stringify(err));
                            didRespond = true;
                            reject('Please enable location permission to continue.');
                        }
                    }
                );
            } else {
                clearTimeout(timeout);
                reject('Geolocation not supported by your device or browser.');
            }
        });
    }    
    updateGeoLocation(lat, lon) {
        this.accountData = {
            ...this.accountData,
            GeoLocation__Latitude__s: lat,
            GeoLocation__Longitude__s: lon
        };
        console.log('Updated Location:', this.accountData.GeoLocation__Latitude__s, this.accountData.GeoLocation__Longitude__s);
    }

    validateAccountFields() {
        let isAllValid = true;
        let accountData = this.accountData; 
    
        // both secoundary customer and primary customer fields
        if (!accountData.Name?.trim() || !accountData.Customer_Type__c || !accountData.Primary_Phone_Number__c ||
             !accountData.State__c || !accountData.District__c || !accountData.Pincode__c ||
           !accountData.City_Town__c ||  !accountData.Street__c ) {
            isAllValid = false;
            this.showFieldError('accountFields'); 
            this.showToast('Error', 'Please fill in all the mandatory fields', 'error');
            return isAllValid;
        }
    
        // Check Customer Type conditions
        if (accountData.Customer_Type__c) {

    
            if (accountData.Customer_Type__c === 'Primary Customer' && 
                (!accountData.Primary_Customer_Type__c || !accountData.Primary_Customer_Business_Type__c ||
                !accountData.Account_Holder_Name__c || !accountData.Branch_Name__c || 
                !accountData.Account_No__c ||   !accountData.Bank_Name__c ||  !accountData.IFSC_Code__c ||
                !accountData.Expected_Turn_over_PA__c ||  !accountData.GST_Number__c ||
                 !accountData.Company_Name__c ||  !accountData.Owner_Name__c ||  !accountData.Security_Cheque_Status__c 
                )) 
                {

                isAllValid = false;
                this.showFieldError('accountFields'); 
                this.showToast('Error', 'Please fill in all the mandatory fields', 'error');
                return isAllValid;
            } 
            else if( this.editCreditInformation  && accountData.Customer_Type__c === 'Primary Customer'  )
            {
                if(!accountData.Payment_Type__c )
                {
                    isAllValid = false;
                    this.showFieldError('accountFields'); 
                    this.showToast('Error', 'Please fill in all the mandatory fields', 'error');
                    return isAllValid;
                }
                else if(accountData.Payment_Type__c && accountData.Payment_Type__c == 'Credit' && !accountData.Credit_Limit__c)
                {
                    isAllValid = false;
                    this.showFieldError('accountFields'); 
                    this.showToast('Error', 'Please fill in all the mandatory fields', 'error');
                    return isAllValid;
                }
              
            }
           
            else if (accountData.Customer_Type__c === 'Secondary Customer' && (!accountData.Secondary_Customer_Type__c ||
                !accountData.Secondary_Customer_Business_Type__c || !accountData.Secondary_Customer_Category__c )) {
            
                this.showFieldError('accountFields'); 
            
                isAllValid = false;
               
                this.showToast('Error', 'Please fill in all the mandatory fields', 'error');
                return isAllValid;
            }
            else if( this.showHighMargin && accountData.Customer_Type__c === 'Secondary Customer' && !accountData.High_Margin__c )
            {
                isAllValid = false;
                this.showFieldError('accountFields'); 
                this.showToast('Error', 'Please fill in all the mandatory fields', 'error');
                return isAllValid;
            }
           /* else if(accountData.Customer_Type__c === 'Secondary Customer' && accountData.Secondary_Customer_Type__c != 'Sub Stockiest' &&
                !accountData.Beat__c
            )
            {
                isAllValid = false;
                this.showFieldError('accountFields'); 
                this.showToast('Error', 'Please fill in all the mandatory fields', 'error');
                return isAllValid;
            }*/
        }
    
        // Validate Phone Number (10 digits)
        if (accountData.Primary_Phone_Number__c && !/^\d{10}$/.test(accountData.Primary_Phone_Number__c)) {
            isAllValid = false;
            this.showFieldError('accountFields'); 
            this.showToast('Error', 'Please enter a valid Primary Phone Number', 'error');
            return isAllValid;
        }
    
        // Validate Aadhaar Number (12 digits)
        if (accountData.Aadhaar_No__c && !/^\d{12}$/.test(accountData.Aadhaar_No__c)) {
            isAllValid = false;
            this.showFieldError('accountFields'); 
            this.showToast('Error', 'Please enter a valid Aadhaar Number', 'error');
            return isAllValid;
        }

        // Validate GST Number (15-character alphanumeric in uppercase)
        if (
            accountData.GST_Number__c &&
            !/^[0-9a-zA-Z]{15}$/.test(accountData.GST_Number__c)
        ) {
            isAllValid = false;
            this.showFieldError('accountFields'); 
            this.showToast('Error', 'Please enter a valid GST Number', 'error');
            return isAllValid;
        }

        // Validate PAN_Number__c (10-character alphanumeric in uppercase)
        if (
            accountData.PAN_Number__c &&
            !/^[0-9a-zA-Z]{10}$/.test(accountData.PAN_Number__c)
        ) {
            isAllValid = false;
            this.showFieldError('accountFields'); 
            this.showToast('Error', 'Please enter a valid PAN Number', 'error');
            return isAllValid;
        }

        // Validate Phone Number (10 digits)
        if (accountData.Secondary_Phone_Number__c && !/^\d{10}$/.test(accountData.Secondary_Phone_Number__c)) {
            isAllValid = false;
            this.showFieldError('accountFields'); 
            this.showToast('Error', 'Please enter a valid alternate phone number', 'error');
            return isAllValid;
        }

        // Validate Phone Number (10 digits)
        if (accountData.Reference_Contact_Mobile__c && !/^\d{10}$/.test(accountData.Reference_Contact_Mobile__c)) {
            isAllValid = false;
            this.showFieldError('accountFields'); 
            this.showToast('Error', 'Please enter a valid reference phone number', 'error');
            return isAllValid;
        }
        // Validate Phone Number (10 digits)
        if (accountData.Contact_Person_Phone__c && !/^\d{10}$/.test(accountData.Contact_Person_Phone__c)) {
            isAllValid = false;
            this.showFieldError('accountFields'); 
            this.showToast('Error', 'Please enter a valid contact person phone', 'error');
            return isAllValid;
        }

        

    
        // Validate Email Format
        if (accountData.Email_ID__c && !this.validateEmail(accountData.Email_ID__c)) {
            isAllValid = false;
            this.showFieldError('accountFields'); 
            this.showToast('Error', 'Please enter a valid email address', 'error');
            return isAllValid;
        }

        
        // Validate Email Format
        if (accountData.Reference_Email__c && !this.validateEmail(accountData.Reference_Email__c)) {
            isAllValid = false;
            this.showFieldError('accountFields'); 
            this.showToast('Error', 'Please enter a valid reference email address', 'error');
            return isAllValid;
        }
    
        // Validate Pincode (6 digits)
        if (accountData.Pincode__c && !/^\d{6}$/.test(accountData.Pincode__c)) {
            isAllValid = false;
            this.showFieldError('accountFields'); 
            this.showToast('Error', 'Please enter a valid Pincode', 'error');
            return isAllValid;
        }
    
        return isAllValid;
    }
    duplicationCheck()
    {
        if (!navigator.onLine) {
            this.showToast('Error', 'No internet connection. Please check your network and try again.', 'error');
            this.isLoading = false;
            return;
        }
        this.isLoading = true;
        DUPLICATOION_CHECK({accountData: this.accountData
        })
        .then(data => {
            this.isLoading = false;
            this.duplicationChecked = true;
          
            if(data.duplicateFound)
            {
                this.duplicateErrorFound = true;
                this.proceedbuttonlabel='Continue';
                this.showAccountScreen = true;
                let msg = 'A customer with the same primary phone number is found. Customer Name : ' + data.accountName;
                this.showToast('Error', msg, 'Error');
             
            }
            else
            {
                this.duplicateErrorFound = false;
                this.proceedToProductMapping();
            }
  
        })
        .catch(error => {
            console.error(error);
            this.isLoading = false;
        });
    }

    proceedToProductMapping() {
        let customerType = this.accountData.Customer_Type__c;
        this.customClass = this.isDesktop ? customerType =='Primary Customer' ?  
                        'slds-size_1-of-7 inputcustompadding' : 
                        this.isSubstockiest ? 'slds-size_3-of-7 inputcustompadding':'slds-size_2-of-7 inputcustompadding' : 
                        'slds-size_1-of-1 slds-p-horizontal_xx-small';
            this.buttoncustomClass = this.isDesktop ? customerType =='Primary Customer' ?  
                        'slds-size_1-of-7 inputcustompadding' :
                            this.isSubstockiest ? 'slds-size_1-of-7 inputcustompadding':'slds-size_1-of-7 inputcustompadding' 
                        : 'slds-size_1-of-1 slds-p-horizontal_xx-small';            
        this.currentStep = 'Product Mapping';
        this.showProductScreen = true;

        
        const otpSkipSalesChannels =  this.otpSkipSalesChannels.split(',').map(s => s.trim());
        const executiveSalesChannel =  this.userSalesChannel.split(';').map(s => s.trim());
        
        // Check if Sales Channel condition matches
        const skipBySalesChannel = executiveSalesChannel.some(sc => otpSkipSalesChannels.includes(sc));
        const isPremises = this.accountData.On_Customer_Premises__c === true;

        if (skipBySalesChannel && !isPremises && customerType !='Primary Customer' ) {
            this.proceedbuttonlabel='Save';
        }
        else
        {
            this.proceedbuttonlabel='Proceed'; 
        }
        this.backbuttonlabel='Previous';    
    }

    ValidateProductMappingFields() {
        let isAllValid = true;
        let productMappingList = [...this.productMappingList];
        let customerType = this.accountData.Customer_Type__c;

        for (let index = 0; index < productMappingList.length; index++) {
            let item = productMappingList[index];

            if (customerType === 'Primary Customer') {
                if (!item.Exectuive__c || !item.Area__c || 
                    !item.Chanel__c || !item.Parent_Depot__c || !item.Child_Depot__c ||
                    !item.Sales_Office__c || !item.Order_Type__c || !item.Distribution_Channel__c || !item.Division__c
                ) {

                    isAllValid = false;
                    this.showFieldError('productMapping');
                    this.showToast('Error', `Please fill in all the mandatory fields for product mapping item ${index + 1}`, 'error');
                    return isAllValid;
                }

                if (this.accountData.Payment_Type__c === 'Credit' &&
                    this.editCreditInformation && (!item.Payment_Term__c || !item.Credit_Description__c)) {

                    isAllValid = false;
                    this.showFieldError('productMapping');
                    this.showToast('Error', `Please fill in all the mandatory fields for product mapping item ${index + 1}`, 'error');
                    return isAllValid;
                }

                if ( this.editCreditInformation && !item.Inco_Terms__c) {

                    isAllValid = false;
                    this.showFieldError('productMapping');
                    this.showToast('Error', `Please fill in all the mandatory fields for product mapping item ${index + 1}`, 'error');
                    return isAllValid;
                }

            } else if (customerType === 'Secondary Customer') {
                if (!item.Exectuive__c) {
                    isAllValid = false;
                    this.showFieldError('productMapping');
                    this.showToast('Error', `Please fill in all the mandatory fields for product mapping item ${index + 1}`, 'error');
                    return isAllValid;
                }

                if (!item.Primary_Customer__c) {
                    isAllValid = false;
                    this.showFieldError('Primary_Customer_Name');
                    this.showToast('Error', `Please fill in all the mandatory fields for product mapping item ${index + 1}`, 'error');
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
                    this.showToast('Error', `Duplicate product mapping found at product mapping item ${i + 1} with product mapping item ${j + 1}`, 'error');
                      isAllValid = false;
                    return isAllValid;
                }
            }
        }

        //Step 3: Mistch need to restict for Substockiet Primary Customers
        if (this.isSubstockiest) {
            const firstPrimaryCustomer = productMappingList[0].Primary_Customer__c || '';

            for (let i = 1; i < productMappingList.length; i++) {
                const currentPrimaryCustomer = productMappingList[i].Primary_Customer__c || '';

                if (String(currentPrimaryCustomer) !== String(firstPrimaryCustomer)) {
                    this.showToast('Error', `All mappings must have the same Primary Customer. Mismatch found at item ${i + 1}.`, 'error');
                    isAllValid = false;
                    return isAllValid;
                }
            }
        }


        return isAllValid;
    }

    //Validate File Upload
    validateFileUpload()
    {
        if (!navigator.onLine) {
            this.showToast('Error', 'No internet connection. Please check your network and try again.', 'error');
            this.isLoading = false;
            this.showCameraScreen = true;
            return;
        }
        
       this.isLoading = true;
        VALIDATE_FILE({
        uniqueFileId : this.accountData.UniqueFileId__c,
        customerType:this.accountData.Customer_Type__c,
        customerPremises :  this.accountData.On_Customer_Premises__c
        })
        .then(result => {
            if(result =='Success')
            {
                this.isLoading = false;
                const otpSkipTypes = this.OTPVerificationSkipCustomerTypes.split(',').map(s => s.trim());
                const primaryType = this.accountData.Primary_Customer_Type__c;


                const otpSkipSalesChannels =  this.otpSkipSalesChannels.split(',').map(s => s.trim());
                const executiveSalesChannel =  this.userSalesChannel.split(';').map(s => s.trim());

                // Check if Customer Type condition matches
                const skipByType = (this.accountData.Customer_Type__c === 'Primary Customer' 
                                    && otpSkipTypes.includes(primaryType));
                
                // Check if Sales Channel condition matches
                const skipBySalesChannel = executiveSalesChannel.some(sc => otpSkipSalesChannels.includes(sc));

                if (skipByType || (skipBySalesChannel && this.isAdmin)) {
                    // Skip OTP and save directly
                    this.handleSave();
                }
                else if(skipBySalesChannel && this.accountData.Customer_Type__c !='Primary Customer')
                {
                    this.handleSave();
                }
                else
                {
                    this.currentStep = 'CCN Verification';
                    this.showVerificationScreen = true;
                    this.proceedbuttonlabel='Save';
                    this.backbuttonlabel='Previous';
                   
    
                    // Set OTP option from phoe number
                    const phonenumber = this.accountData.Primary_Phone_Number__c;
                    if (phonenumber) {
                        this.otpSendOptions = [{ label: phonenumber, value: phonenumber }];
                        this.selectedOtpOption = phonenumber;
                    }
                }
              
            
            }
            else
            {
                this.isLoading = false;
                this.showCameraScreen = true;
                let msg = `Please upload the required documents: ${result}`;
                this.showToast('Error', msg, 'error');
            }
           
        })
        .catch(error => {
            console.error(error);
            this.isLoading = false;
            this.showCameraScreen = true;
        });
    }

    handleSave() {
        this.isLoading = true;
        saveData({ accountData: this.accountData, productMappingList: this.productMappingList })
        .then((accountId) => {
                let msg = this.accountData.Customer_Type__c +' saved successfully';
                this.showToast('Success', msg, 'success');
                this.showPopup = false;
                this.accountIdReturned =accountId;
                this.dispatchToAura('Done',accountId);
        })
        .catch(error => {
            this.showToast('Error', 'Something went wrong! Please try again', 'error');
            this.isLoading = false;
            // Navigate back to the previous screen
            if (this.currentStep === 'Customer Details') {
                this.showAccountScreen = true;
            } else if (this.currentStep === 'Product Mapping') {
                this.showProductScreen = true;
            } else if (this.currentStep === 'Photo Upload') {
                this.showCameraScreen = true;
            } else if (this.currentStep === 'CCN Verification') {
                this.showVerificationScreen = true;
            }
        });
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
    resetScreens()
    {
        this.showAccountScreen = false;
        this.showProductScreen = false;
        this.showCameraScreen = false;
        this.showVerificationScreen = false;
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
    getOptionValuesWithNone(optionsArray)
    {
        const selectOption = { label: 'Select option', value: '' };
        return [selectOption, ...optionsArray];
    }
    // Email validation helper function
    validateEmail(email) {
        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        return emailRegex.test(email);
    }
    
    getOptionsList(optionsMap) {
        return Object.keys(optionsMap).map(label => ({
            label: label, 
            value: optionsMap[label] // Use API value instead of label
        }));
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