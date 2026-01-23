import { LightningElement,wire,api,track } from 'lwc';
import getApexData from '@salesforce/apex/beatPlannerlwc.getData';
import getAllVisitData from '@salesforce/apex/beatPlannerlwc.getAllVisitData';
import { getLocationService } from 'lightning/mobileCapabilities';
import { updateRecord,createRecord,deleteRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import LightningConfirm from 'lightning/confirm';
import { NavigationMixin } from 'lightning/navigation';
import GOOGLE_ICONS from '@salesforce/resourceUrl/googleIcons';
import COMPLETE_Visit from '@salesforce/apex/beatPlannerlwc.completeVisit';
import OrgDomain from '@salesforce/label/c.orgUrl'; 
import Visit_OBJECT from '@salesforce/schema/Visit__c'; 
  

export default class ExecuteScreen3 extends NavigationMixin(LightningElement) {

    summeryIcons = {
        stock : GOOGLE_ICONS + "/googleIcons/stock.png",
        payment :  GOOGLE_ICONS + "/googleIcons/payment.png",
        camera :  GOOGLE_ICONS + "/googleIcons/camera.png",
        order :  GOOGLE_ICONS + "/googleIcons/order.png",
        task :  GOOGLE_ICONS + "/googleIcons/task.png",
        Competitor :  GOOGLE_ICONS + "/googleIcons/Competitor.png",
        summery :  GOOGLE_ICONS + "/googleIcons/summery.png",
        visitform :  GOOGLE_ICONS + "/googleIcons/visit.png",
        returns:GOOGLE_ICONS + "/googleIcons/returns.png",
        display:GOOGLE_ICONS + "/googleIcons/displayformat.png",
        orderfulfilment:GOOGLE_ICONS + "/googleIcons/Productivity.png",
    };

    openBusinessSummary = false;
    businessSummery = {
        totalOutStanding : 0,
        totalOrderAmt : 0,
        totalSalesAmt : 0,
        AllVisit : 0,
        totalReturnAmount : 0,
        totalReturnQty : 0,
    };
    @api isPromoter;
    @api recordId;
    @api checkinData;
    @api index;
    @api accId;
    @api accountId;
    @api objName; 
    @api isProgressVisit;
    @api isInProgress;
    @api isAcc;
    @api isPrimaryCustomer;
    @api isCompleted;
    @api isDesktop;
    @api visitParentData;
    @api isplayButtonClicked = false;
    @track visitData = [];
    @track orderData = [];
    completeVisit = false;
    comment = null;
    isDesktopCheckoutPage = true;

    //visit forms
    @track orders =[];
    @track name = '';
    @track phone = '';
    @track location = '';
    @track photo = '';
    @track uploadedFileId;
    @track showModal = false;
    @track localLeads = [];
    @track isVisitFormDropdownOpen = false;
    @track isdisplayDropdownOpen = false;
    @track isOrderFuldropdownOpen = false;
    @track isShelfStockDropdownOpen = false;
    newvisitFormPoup =false;
    isvisitDesktop = true;
    leadsWireResult;
    acceptedFormats = ['.jpg', '.jpeg', '.png'];
    showExecuteScreen3 = true;
    isstockCreated = true;
    //ended here visit forms 

    @track visActionData = {
        VisitPhoto : [],
        outletTask : [],
        paymentFollowUp:[],
        Competition : [],
        Stock : [],
        visitForm :[],
        displayFormat:[],
        photoData : [],
        returns:[],
        orderfulfillments:[],
        ShelfStocks:[]
    };
    isImageDropdownOpen = false;
    dropdown = {
        camera : false,
        task : false,
        payment : false,
        stock : false,
        photo : false,
        competition : false,
        visitform : false,
        DisFormat : false,
        ordful : false,
        order : false,
        summery : false,
        returns:false,
        shelfstock :false,
    }
    tableHeading ={
        order:['Order No','Total Qty','Total Amt'],
        stock:['SKU','Qty','UOM'],
        payment : ['Name','Expected amt','Exp. Pay Date','Comments'],
        task:['Name','Desc.','Status'],
        comptitor:['SKU','Comp. Name','Disp. board','Spl offer','Remarks'],
        visitForm:['Name','Phone','Location'],
        displayFormat : ['SKU ','Display Value'],
        orderfulfillments : ['Order No','Status','Order Type'],
        returns : ['Return No.','Total Qty','Total Amt'],
        collections:['Pay Mode','Amt. Recvd.','UTR No.','Remarks'],
        ShelfStocks:['Shelf Stock','Sku','Stock Level', 'Sales Quantity'],
        primaryCollections :['Invoice No.','Pay Mode','Amt. Recvd.','UTR No.','Remarks']
    } ;

    @api handleCheckOutVisit(){
        this.isDesktopCheckoutPage = this.isDesktop ? true : false;
        this.completeVisit = true;
    }

    visitHeading = ['Visit','Account Name','Status','Actual Start date/time','Actual End date/time'];
    isPageLoaded = false;
    
    //detect if LWC is running in mobile publisher
    isMobilePublisher = window.navigator.userAgent.indexOf('CommunityHybridContainer') > 0;


    connectedCallback(){
        if(this.isProgressVisit != undefined && !this.isProgressVisit){
            if(this.visitParentData.status == 'Planned' && this.isplayButtonClicked){
                this.isPageLoaded = true;
                this.visActionData = {
                    VisitPhoto : null,
                    outletTask : null,
                    paymentFollowUp: null,
                    Competition : null,
                    visitForm :null,
                    displayFormat:null,
                    Stock : null,
                    photoData : null,
                    returns:null,
                    collections:null,
                    ShelfStocks:null,
                    orderfulfillments:null,
                    orderData:null,
                }
                this.orderData = null;
                console.log('checkinData'+JSON.stringify(this.checkinData));
                this.handleGetLatLon('checkin');
            }else{
                this.isPageLoaded = true;
                this.GetOrderDetailsData();
            }
        }
        else{
            this.isPageLoaded = true;
            this.GetOrderDetailsData();
        }
    }
    GetOrderDetailsData(){
        console.log('this.recordId'+this.recordId);
        getAllVisitData({
            recordId: this.recordId,
        })
        .then(result => {
            console.log(result);
            console.log('thois is visitform ====>',result.visitForm);
            this.visActionData.orderData  =  (result.orderList && result.orderList.length != 0) ? result.orderList : null;
           // this.visActionData.VisitPhoto = (result.VisitPhoto && result.VisitPhoto.length != 0) ? result.VisitPhoto : null;
            //this.visActionData.outletTask = (result.outletTask && result.outletTask.length != 0 ) ? result.outletTask : null;
            this.visActionData.collections = (result.collectionItems && result.collectionItems.length != 0) ? result.collectionItems : null;
            this.visActionData.returns = (result.returnList && result.returnList.length != 0) ? result.returnList : null;
            this.visActionData.Competition = (result.Competition && result.Competition.length != 0) ? result.Competition : null;
            this.visActionData.Stock =( result.Stock && result.Stock.length != 0) ? result.Stock : null;
            this.visActionData.visitForm =( result.visitForm && result.visitForm.length != 0) ? result.visitForm : null;
            this.visActionData.displayFormat =( result.displayFormat && result.displayFormat.length != 0) ? result.displayFormat : null;
           // this.visActionData.photoData = (result.VisitPhoto && result.VisitPhoto.length != 0 )? result.VisitPhoto : null;
            this.visActionData.ShelfStocks =( result.ShelfStocks && result.ShelfStocks.length != 0) ? result.ShelfStocks : null;
            this.visActionData.orderfulfillments = (result.orderfulfillments && result.orderfulfillments.length != 0 )? result.orderfulfillments : null;
            this.isPageLoaded = false;
            this.isstockCreated = result.currentMonthStockExisted;
            this.businessSummery = {
                totalOutStanding : result.totalOutStanding,
                totalOrderAmt : result.totalOrderAmt,
                totalSalesAmt : result.totalSalesAmt,
                AllVisit : result.AllVisit,
                totalReturnQty : result.totalReturnQty,
                totalReturnAmount : result.totalReturnAmount
            };
  
        })
        .catch(error => {
            console.error(error);
            this.isPageLoaded = false;
        });
    }
    /*Getting geoLocation*/
    handleGetLatLon(checkOutIn) {
        console.log('this.isMobilePublisher: ' + this.isMobilePublisher);
       // If checkin and lat/lon already exists in checkinData, use that
        if (checkOutIn === 'checkin' && this.checkinData && this.checkinData.latitude && this.checkinData.longitude) {
            const newEvent = new CustomEvent('locationPharmacySearch:getLatLonResponse', { detail: {} });
            newEvent.detail.lat = this.checkinData.latitude;
            newEvent.detail.lon = this.checkinData.longitude;
            newEvent.detail.latlonsource = 'checkinData';
            newEvent.detail.status = 'success';

            console.log('Using checkinData for coordinates: ', newEvent.detail);
            this.handleSaveVisitData(newEvent, checkOutIn);
            return;
        }



        if(this.isMobilePublisher)
        {
            //invoke Location Service native mobile capability feature
            //to get current position
            getLocationService().getCurrentPosition({
            enableHighAccuracy: true
                }).then((result) => {

                    var newEvent = new CustomEvent('locationPharmacySearch:getLatLonResponse',{detail:{}});
                    newEvent.detail.lat = result.coords.latitude;
                    newEvent.detail.lon = result.coords.longitude; 
                    newEvent.detail.latlonsource = 'nimbus';
                    newEvent.detail.status = 'success';

                    console.log('newEvent: ' + JSON.stringify(newEvent));
                    this.handleSaveVisitData(newEvent,checkOutIn);

                }).catch((error) => {
                    console.log(JSON.stringify(error));
                    this.isPageLoaded = false;
                }).finally(() => {

                });

        }
        else if(window.navigator && window.navigator.geolocation)
        {
            //invoke browser native capability to get current position
            window.navigator.geolocation.getCurrentPosition((r,err) => {
                var newEvent = new CustomEvent('locationPharmacySearch:getLatLonResponse',{detail:{}});
                if(r && r.coords)
                {
                    
                    newEvent.detail.lat = r.coords.latitude;
                    newEvent.detail.lon = r.coords.longitude; 
                    newEvent.detail.latlonsource = 'browser';
                    newEvent.detail.status = 'success';
                    this.handleSaveVisitData(newEvent,checkOutIn);

                }
                else if(err)
                {
                  console.log(JSON.stringify(err));
                  this.isPageLoaded = false;
                }
            });
        
        }
        else 
        {
            console.log('Unable to get user location.');
            this.isPageLoaded = false;
        }
    }
    /**Start visit and complete visit */
    handleSaveVisitData(event,checkOutIn){
        if (!navigator.onLine) {
            this.genericDispatchToastEvent('Error', 'No internet connection. Please check your network and try again.', 'error');
            return;
        }
        let details = JSON.parse(JSON.stringify(event.detail));
        const now = new Date();
        if(checkOutIn == 'checkin')
        {
            console.log('this.visitParentData.beatItemId'+this.visitParentData.beatItemId);
            let visitParentData = this.visitParentData;

            let data = {
                Clockin_Longitude__c: details.lon,
                ClockIn_Latitude__c: details.lat,
                Account1__c:this.accountId,
                Actual_Start_Time__c: now.toISOString(),
                Planned_Start_Time__c: now.toISOString(),
                Beat_Item__c:visitParentData.beatItemId,
                PJP_Item__c: visitParentData.pjpItemId ?  visitParentData.pjpItemId  : '',
                Visit_for__c:visitParentData.visitTypes,
                Daily_Log__c:visitParentData.dailyLogId,
                Approval_Status__c : 'Approved',
                Status__c: 'In Progress',
                Child_beat__c:visitParentData.visitPlanId,
                UniqueFileId__c: this.checkinData.uniqueId,
                Location_Type__c : this.checkinData.locationType
            };
            const recordInput= {
                apiName: Visit_OBJECT.objectApiName, fields : data
            };
            this.saveUpdateRecord(recordInput,checkOutIn,createRecord);
             
        }
        else if(checkOutIn == 'checkout')
        {
            let data = {
                sObjectType: 'Visit__c',
                Id: this.recordId,
                Comments__c: this.comment,
                Clockout_Longitude__c: details.lon,
                Clockout_Latitude__c: details.lat,
                Actual_End_Time__c: now.toISOString(),
                Status__c: 'Completed'
            };
            COMPLETE_Visit({visitData: data,beatId:this.visitParentData.visitPlanId })
            .then(result => {
                this.visitData = [result];
                this.genericDispatchToastEvent('Success','Visit Completed successfully', 'Success');
                this.isPageLoaded = false;
                this.completeVisit = false;
      
                this.isDesktopCheckoutPage = true;
                const event = new CustomEvent('screen3', {
                    detail: {message:'checkout'}
                });
                this.dispatchEvent(event);
            })
            .catch(error => {
                console.error(error);
                this.genericDispatchToastEvent('Error', 'Failed to complete visit', 'error');
            });
        }
    }
    saveUpdateRecord(recordInput,checkOutIn,actionToPerform){
        if (!navigator.onLine) {
            this.genericDispatchToastEvent('Error', 'No internet connection. Please check your network and try again.', 'error');
            return;
        }
        actionToPerform(recordInput)
            .then((result) => {
                this.completeVisit = false;
                this.recordId = result.id;
                this.visitData = [result];
                var msg = checkOutIn === 'checkout' ? 'Visit Completed Successfully' : 'Visit Started Successfully';
                this.genericDispatchToastEvent('Success',msg,'success');
                this.isPageLoaded = false;
                if(checkOutIn == 'checkin'){
                    this.isPageLoaded = true;
                    this.GetOrderDetailsData();
                }                  
            })
            .catch((error) => {
                // Handle error in record creation
                this.isDailyLog = false;
                this.isPageLoaded = false;
                console.error('Error creating record:', error);
            });
    }

    /**Download Return Pdf */
    downloadReturnPdf(event)
    {
        if (!navigator.onLine) {
            this.genericDispatchToastEvent('Error', 'No internet connection. Please check your network and try again.', 'error');
            return;
        }
        const returnId = event.target.dataset.id;
        if (!this.isDesktop) {
            const url = `${OrgDomain}/ReturnPdf?Id=${returnId}`;
            window.location.href = url;
        } else {
            const url = `/apex/ReturnPdf?id=${returnId}`;
            window.open(url, '_blank');
        }
    }
    /**Download Order Pdf */
    downloadOrderPdf(event)
    {
        if (!navigator.onLine) {
            this.genericDispatchToastEvent('Error', 'No internet connection. Please check your network and try again.', 'error');
            return;
        }
        const orderId = event.target.dataset.id;
        if (!this.isDesktop) {
            const url = `${OrgDomain}/OrderPdf?Id=${orderId}`;
            window.location.href = url;
        } else {
            const url = `/apex/OrderPdf?id=${orderId}`;
            window.open(url, '_blank');
        }
    }

 
    /**on click on Forward Icon */
    openCamerScreen() {
        if (!navigator.onLine) {
            this.genericDispatchToastEvent('Error', 'No internet connection. Please check your network and try again.', 'error');
            return;
        }
        const  message = { 
            message: 'cameraScreen' ,
            recordID : this.recordId,
            index : this.index,
            screen : 3.2,
            isProgressVisit : true
        };
        this.genericDispatchEvent(message);
    }
    openProductScreen() {
        if (!navigator.onLine) {
            this.genericDispatchToastEvent('Error', 'No internet connection. Please check your network and try again.', 'error');
            return;
        }
        const  message = { 
            message: 'productScreen' ,
            recordID : this.recordId,
            index : this.index,
            screen : 3.2,
            isProgressVisit : true
        };
        this.genericDispatchEvent(message);
    }
    openStockScreen() {
        if (!navigator.onLine) {
            this.genericDispatchToastEvent('Error', 'No internet connection. Please check your network and try again.', 'error');
            return;
        }
        const  message = { 
            message: 'StockSCreen' ,
            recordID : this.recordId,
            index : this.index,
            screen : 3.2,
            isProgressVisit : true
        };
        this.genericDispatchEvent(message);
    }
    openTaskScreen(){
        if (!navigator.onLine) {
            this.genericDispatchToastEvent('Error', 'No internet connection. Please check your network and try again.', 'error');
            return;
        }
        const  message = { 
            message: 'taskScreen' ,
            recordID : this.recordId,
            index : this.index,
            screen : 3.4,
            accId : this.accID,
            objName : this.objName,
            isProgressVisit : true
        };
        this.genericDispatchEvent(message);
    }
    openCompetitorcreen(){
        if (!navigator.onLine) {
            this.genericDispatchToastEvent('Error', 'No internet connection. Please check your network and try again.', 'error');
            return;
        }
        const  message = { 
            message: 'CompetitorScreen' ,
            recordID : this.recordId,
            index : this.index,
            screen : 3.5,
            accId : this.accId,
            isProgressVisit : true
        };
        this.genericDispatchEvent(message);
    }
    openPaymentScreen() {
        if (!navigator.onLine) {
            this.genericDispatchToastEvent('Error', 'No internet connection. Please check your network and try again.', 'error');
            return;
        }
        const  message = { 
            message: 'paymentScreen' ,
            recordID : this.recordId,
            screen : 3.3,
            isProgressVisit : true
        };
        this.genericDispatchEvent(message);
    }
    openCollectionScreen() {
        if (!navigator.onLine) {
            this.genericDispatchToastEvent('Error', 'No internet connection. Please check your network and try again.', 'error');
            return;
        }
        const  message = { 
            message: 'collectionScreen' ,
            recordID : this.recordId,
            screen : 3.3,
            isProgressVisit : true
        };
        this.genericDispatchEvent(message);
    }
    openReturnScreen() {
        if (!navigator.onLine) {
            this.genericDispatchToastEvent('Error', 'No internet connection. Please check your network and try again.', 'error');
            return;
        }
        const  message = { 
            message: 'returnScreen' ,
            recordID : this.recordId,
            screen : 3.3,
            visitData:this.visitParentData,
            isProgressVisit : true
        };
        this.genericDispatchEvent(message);
    }
    openDisplayFormatScreen() {
        if (!navigator.onLine) {
            this.genericDispatchToastEvent('Error', 'No internet connection. Please check your network and try again.', 'error');
            return;
        }
        const  message = { 
            message: 'DisplayScreen' ,
            recordID : this.recordId,
            screen : 3.3,
            isProgressVisit : true
        };
        this.genericDispatchEvent(message);
    }
    openOrderFulfillmentsScreen() {
        if (!navigator.onLine) {
            this.genericDispatchToastEvent('Error', 'No internet connection. Please check your network and try again.', 'error');
            return;
        }
        const  message = { 
            message: 'OrderFulfillments' ,
            recordID : this.recordId,
            screen : 3.3,
            isProgressVisit : true
        };
        this.genericDispatchEvent(message);
    }
    openShelfStockScreen() {
        if (!navigator.onLine) {
            this.genericDispatchToastEvent('Error', 'No internet connection. Please check your network and try again.', 'error');
            return;
        }
        const  message = { 
            message: 'ShelfStockScreen' ,
            recordID : this.recordId,
            screen : 3.3,
            visitData:this.visitParentData,
            isProgressVisit : true
        };
        this.genericDispatchEvent(message);
    }
    
    

    // Toggle dropdowns 
    toggleImageDropdown(){
        this.dropdown.photo  = !this.dropdown.photo ;
        const dropdownBody = this.template.querySelector('.dropdown-body-image');
        const chevronIcon = this.template.querySelector('.chevron-icon-image');
        if (dropdownBody) {
            if (this.dropdown.photo ) {
  
                dropdownBody.classList.add('active');
                chevronIcon.iconName = 'utility:chevronup'; // Switch to chevron up
            } else {
                dropdownBody.classList.remove('active');
                chevronIcon.iconName = 'utility:chevrondown'; // Switch back to chevron down
            }
        }
    }
    toggleSummeryDropdown(){
        this.dropdown.summery  = !this.dropdown.summery ;
        const dropdownBody = this.template.querySelector('.dropdown-body-sum');
        const chevronIcon = this.template.querySelector('.chevron-icon-sum');
        if (dropdownBody) {
            if (this.dropdown.summery ) {
  
                dropdownBody.classList.add('active');
                chevronIcon.iconName = 'utility:chevronup'; // Switch to chevron up
            } else {
                dropdownBody.classList.remove('active');
                chevronIcon.iconName = 'utility:chevrondown'; // Switch back to chevron down
            }
        }
    }
    toggleOrderDropdown(){
        this.dropdown.order  = !this.dropdown.order ;
        const dropdownBody = this.template.querySelector('.dropdown-body-ord');
        const chevronIcon = this.template.querySelector('.chevron-icon-ord');
        if (dropdownBody) {
            if (this.dropdown.order ) {
  
                dropdownBody.classList.add('active');
                chevronIcon.iconName = 'utility:chevronup'; // Switch to chevron up
              
            } else {
                dropdownBody.classList.remove('active');
                chevronIcon.iconName = 'utility:chevrondown'; // Switch back to chevron down
            }
        }
    }
    toggleStockDropdown(){
        this.dropdown.stock  = !this.dropdown.stock ;
        const dropdownBody = this.template.querySelector('.dropdown-body-stk');
        const chevronIcon = this.template.querySelector('.chevron-icon-stk');
        if (dropdownBody) {
            if (this.dropdown.stock ) {
  
                dropdownBody.classList.add('active');
                chevronIcon.iconName = 'utility:chevronup'; // Switch to chevron up
              
            } else {
                dropdownBody.classList.remove('active');
                chevronIcon.iconName = 'utility:chevrondown'; // Switch back to chevron down
            }
        }
    }
    toggleCollectionsDropdown(){
        this.dropdown.payment  = !this.dropdown.payment ;
        const dropdownBody = this.template.querySelector('.dropdown-body-pyt');
        const chevronIcon = this.template.querySelector('.chevron-icon-pyt');
        if (dropdownBody) {
            if (this.dropdown.payment ) {
  
                dropdownBody.classList.add('active');
                chevronIcon.iconName = 'utility:chevronup'; // Switch to chevron up
               
            } else {
                dropdownBody.classList.remove('active');
                chevronIcon.iconName = 'utility:chevrondown'; // Switch back to chevron down
            }
        }
    }
    toggleReturnDropdown(){
        this.dropdown.returns  = !this.dropdown.returns ;
        const dropdownBody = this.template.querySelector('.dropdown-body-retuns');
        const chevronIcon = this.template.querySelector('.chevron-icon-return');
        if (dropdownBody) {
            if (this.dropdown.returns ) {
  
                dropdownBody.classList.add('active');
                chevronIcon.iconName = 'utility:chevronup'; // Switch to chevron up
                
            } else {
                dropdownBody.classList.remove('active');
                chevronIcon.iconName = 'utility:chevrondown'; // Switch back to chevron down
            }
        }
    }

    toggleTaskDropdown(){
        this.dropdown.task  = !this.dropdown.task ;
        const dropdownBody = this.template.querySelector('.dropdown-body-tsk');
        const chevronIcon = this.template.querySelector('.chevron-icon-tsk');
        if (dropdownBody) {
            if (this.dropdown.task ) {
  
                dropdownBody.classList.add('active');
                chevronIcon.iconName = 'utility:chevronup'; // Switch to chevron up
              
            } else {
                dropdownBody.classList.remove('active');
                chevronIcon.iconName = 'utility:chevrondown'; // Switch back to chevron down
            }
        }
    }
    toggleCompDropdown(){
        this.dropdown.competition = !this.dropdown.competition ;
        const dropdownBody = this.template.querySelector('.dropdown-body-cmp');
        const chevronIcon = this.template.querySelector('.chevron-icon-comp');
        if (dropdownBody) {
            if (this.dropdown.competition ) {
  
                dropdownBody.classList.add('active');
                chevronIcon.iconName = 'utility:chevronup'; // Switch to chevron up
                
            } else {
                dropdownBody.classList.remove('active');
                chevronIcon.iconName = 'utility:chevrondown'; // Switch back to chevron down
            }
        }
    }
    toggleVisitFormsDropdown(){
        this.dropdown.visitform = !this.dropdown.visitform ;
        this.isVisitFormDropdownOpen = this.dropdown.visitform;
        console.log('isVisitFormDropdownOpen',this.isVisitFormDropdownOpen);
        const dropdownBody = this.template.querySelector('.dropdown-body-Vform');
        const chevronIcon = this.template.querySelector('.chevron-icon-vform');
        if (dropdownBody) {
            if (this.dropdown.visitform) {
  
                dropdownBody.classList.add('active');
                chevronIcon.iconName = 'utility:chevronup'; // Switch to chevron up
              
            } else {
                dropdownBody.classList.remove('active');
                chevronIcon.iconName = 'utility:chevrondown'; // Switch back to chevron down
            }
        }
    }
    toggleShelfStockDropdown(){
        this.dropdown.shelfstock  = !this.dropdown.shelfstock ;
        this.isShelfStockDropdownOpen = this.dropdown.shelfstock;
        const dropdownBody = this.template.querySelector('.dropdown-body-shelfstock');
        const chevronIcon = this.template.querySelector('.chevron-icon-shelfstock');
        if (dropdownBody) {
            if (this.dropdown.shelfstock ) {
  
                dropdownBody.classList.add('active');
                chevronIcon.iconName = 'utility:chevronup'; // Switch to chevron up
                
            } else {
                dropdownBody.classList.remove('active');
                chevronIcon.iconName = 'utility:chevrondown'; // Switch back to chevron down
            }
        }
    }
    toggleDisplayFormatDropdown(){
        this.dropdown.DisFormat  = !this.dropdown.DisFormat ;
        this.isdisplayDropdownOpen = this.dropdown.DisFormat;
        const dropdownBody = this.template.querySelector('.dropdown-body-Dis');
        const chevronIcon = this.template.querySelector('.chevron-icon-Dis');
        if (dropdownBody) {
            if (this.dropdown.DisFormat ) {
  
                dropdownBody.classList.add('active');
                chevronIcon.iconName = 'utility:chevronup'; // Switch to chevron up
                
            } else {
                dropdownBody.classList.remove('active');
                chevronIcon.iconName = 'utility:chevrondown'; // Switch back to chevron down
            }
        }

    }
    toggleOrderFulfillmentsDropdown(){
        this.dropdown.ordful  = !this.dropdown.ordful ;
        this.isOrderFuldropdownOpen = this.dropdown.ordful;
        console.log('isOrderFuldropdownOpen',this.isOrderFuldropdownOpen);
        const dropdownBody = this.template.querySelector('.dropdown-body-ordFul');
        const chevronIcon = this.template.querySelector('.chevron-icon-ordFul');
        if (dropdownBody) {
            if (this.dropdown.ordful ) {
  
                dropdownBody.classList.add('active');
                chevronIcon.iconName = 'utility:chevronup'; // Switch to chevron up
                
            } else {
                dropdownBody.classList.remove('active');
                chevronIcon.iconName = 'utility:chevrondown'; // Switch back to chevron down
            }
        }

    }

    /**File Upload */
    deleteSelectedFile(event){
        if (!navigator.onLine) {
            this.genericDispatchToastEvent('Error', 'No internet connection. Please check your network and try again.', 'error');
            return;
        }
        const id = event.currentTarget.dataset.id;
        const fileName = event.currentTarget.dataset.name;
        const msg =  "Are you sure you want to delete "+fileName +"?";
        const label =  "warning";
        const variant = "Delete Photo";
        var getConfirmation = false;
        this.handleConfirmClick(msg,label,variant,id,fileName);
        
    }
    async handleConfirmClick(msg,variant,label,id,fileName) {
        const result = await LightningConfirm.open({
            message:msg,
            variant: variant, // headerless
            label: label
        });
    
        //Confirm has been closed
    
        //result is true if OK was clicked
        if (result) {
            this.deletePhoto(id,fileName);
        } else { 
            return result ; 
        } 
    }
    async deletePhoto(recordId,fileName) {
        if (!navigator.onLine) {
            this.genericDispatchToastEvent('Error', 'No internet connection. Please check your network and try again.', 'error');
            return;
        }
        const msg = fileName + " deleted successfully";
        try {
            await deleteRecord(recordId);
            this.genericDispatchToastEvent('success',msg,'Success');
            this.GetOrderDetailsData();
        } catch (error) {
            //const message = 
            this.genericDispatchToastEvent('error','Connect delete photo','Error');
           
        }
    }
    previewFile(event) {
        if (!navigator.onLine) {
            this.genericDispatchToastEvent('Error', 'No internet connection. Please check your network and try again.', 'error');
            return;
        }
        const recordId = event.currentTarget.dataset.id;
      //  const filetype = event.currentTarget.id
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
    
 
    createNewVisit(event){
        if (!navigator.onLine) {
            this.genericDispatchToastEvent('Error', 'No internet connection. Please check your network and try again.', 'error');
            return;
        }
        const msg = event.detail;
        if(msg.message == 'createNewVisit'){
            this.comment = msg.Comment;
            this.handleGetLatLon('checkout');
        }
        else if(msg.message == 'Close'){
            this.completeVisit = false;
            this.isDesktopCheckoutPage = true;
        }
    }
    openBusinesSummary(event){
        if (!navigator.onLine) {
            this.genericDispatchToastEvent('Error', 'No internet connection. Please check your network and try again.', 'error');
            return;
        }
        const name = event.currentTarget.dataset.name;
        if(name == 'outstanding' && this.businessSummery.totalOutStanding == 0){
            this.genericDispatchToastEvent('','No outstanding amount','info');
            return;
        }
        else if(name == 'order' && this.businessSummery.totalOrderAmt == 0){
            this.genericDispatchToastEvent('','No order found','info');
            return;
        }
        else if(name == 'sales' && this.businessSummery.totalSalesAmt == 0){
            this.genericDispatchToastEvent('','No sales amount','info');
            return;
        }
        else if(name == 'visit' && this.businessSummery.AllVisit == 0){
            this.genericDispatchToastEvent('','No ovisit data','info');
            return;
        }
        else if(name == 'return' && this.businessSummery.totalReturnQty == 0){
            this.genericDispatchToastEvent('','No return data','info');
            return;
        }
        
        const  message = { 
            message: name ,
            recordID : this.recordId,
            index : this.index,
            screen : 3.3,
            isProgressVisit : true
        };
        this.genericDispatchEvent(message);
    }

    //for visit forms
    openCreateVisitcreen() {
        if (!navigator.onLine) {
            this.genericDispatchToastEvent('Error', 'No internet connection. Please check your network and try again.', 'error');
            return;
        }
        this.isvisitDesktop = this.isDesktop ? true : false;
        this.showExecuteScreen3 = false;
        this.newvisitFormPoup = true;
    }
    handleCreateVisitFormPopup(event) {
        if (!navigator.onLine) {
            this.genericDispatchToastEvent('Error', 'No internet connection. Please check your network and try again.', 'error');
            return;
        }
        // Refresh leads based on visit ID (recordId)
        //refreshApex(this.leadsWireResult);
        this.showExecuteScreen3 = true;
        // Optional: show toast
        const leadName = event.detail.LastName;
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Success',
                message: `Lead ${leadName} created and linked to Visit.`,
                variant: 'success'
            })
        );
        this.isPageLoaded = true;
        this.GetOrderDetailsData();

        this.newvisitFormPoup = false;
    }
    handleCloseVisitFormPopup() {
        console.log('Modal closed without saving');
        this.showExecuteScreen3 = true;
        this.newvisitFormPoup = false;
    }
    



    /**Helper methods */
    genericDispatchEvent(message) {
        // Creating a custom event with a payload (optional)
        const event = new CustomEvent('screen3', {
            detail: message
        });

        // Dispatching the event
        this.dispatchEvent(event);
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


    /**Not in Use */
    formatDate(date) {
        const year = date.getFullYear();
        const month = (date.getMonth() + 1).toString().padStart(2, '0'); // Month starts from 0
        const day = date.getDate().toString().padStart(2, '0');
        return `${year}-${month}-${day}`;
    }
    getTheDateBackend(obj,dateValue,selectedDate) {
        
        let todayDate =this.formatDate(new Date());
        
        //this.isSpinner = true;
        getApexData({ 
            isoffSet: null,
            isLimit: null,
            objName : 'BeatPlan',
            fromDate : todayDate,
            toDate : todayDate
        })
        .then(result => {
            console.log(result);

            this.visitData = result.visit;
   
        })
        .catch(error => {
            console.error(error);
            //this.isSpinner = false;
        });
    }
    onClickVisitPopup(event){
        const msg = event.detail;
        if(msg.message == 'Close'){
            this.completeVisit = false;
            this.isDesktopCheckoutPage = true;
        }
    }

    
    
}