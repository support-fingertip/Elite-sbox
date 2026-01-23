import { LightningElement, track } from 'lwc';
import LightningConfirm from 'lightning/confirm';
import { getLocationService } from 'lightning/mobileCapabilities';
import DAILY_LOG_OBJECT from '@salesforce/schema/Daily_Log__c'; 
import { createRecord,updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import DailyLogData from '@salesforce/apex/beatPlannerlwc.getDailyLog';
import FORM_FACTOR from '@salesforce/client/formFactor';
import Id from '@salesforce/user/Id';
import updateDocument from '@salesforce/apex/beatPlannerlwc.updateDocument';
import getFiles from '@salesforce/apex/beatPlannerlwc.getFiles';
import { NavigationMixin } from 'lightning/navigation';
import deleteFile from '@salesforce/apex/beatPlannerlwc.deleteFile';
import VALIDATE_FILE from '@salesforce/apex/beatPlannerlwc.validateFileUpload';
import upsertDailyLog from '@salesforce/apex/beatPlannerlwc.upsertDailyLog';

export default class BeatPlannerLWC extends NavigationMixin(LightningElement){

    userId = Id;
    @track isMenuOpen = false; // Track the menu state
    isEndDayPopup = false;
    Outlet = true;
    isBeatViewScreen = false;
    isHomePage = false;
    header = 'Visit Plan';
    isRenderDataLoaded = true; objName;
    acccountId = '';
    visitfor ='';
    isplayButtonClicked = false;
    index;
    recordId;
    visitId;
    isPromoter;
    navBarClass = 'navbar';
    containerClass;
    screen = 0;
    VisitListName = '';
    productCatDropdown = [];
    proCatVal = 'All';
    searchPro = '';
    objName;
    screenHeight;
    buttonName = 'Start Day'; 
    //createDailyLog = false; 
    isDisabled = false;
    isPageLoaded = false; isVisitCreate = true; newVisitPoup = false; isvisitDesktop = true;
    @track placeholders = [];
    isDailyLog = true; outletPage = false; isCameraScreen = false;
    isDailyLogPopup = false;
    isProductScreen = false; isTaskScreen = false; isStockScreen = false;
    isExecuteScreen = false;  isCollectionsScreen = false; 
    isDisplayScreen = false;  isVisitHeader = false; isOrderFulfillment = false;isOrderLineItemFulfillment=false;
    isReturnScreen = false;
    isShelfStockScreen = false;
    isPhone = false; isDesktop = false; 
    isCometitionScreen = false;
    currentLogId ;
    visitData;
    isStartDay = true;
    executeScreenData = {
        isProgressVisit : false,
        isAcc : false,
        isCompleted : false,
        isInProgress : false
    };
    @track dailylogData = {
        Id: null,
        Purpose_of_Visit__c: 'Customer Visit',
        Travel_Type__c: '',
        Vehicle_Used__c :'Personal/own',
        Start_Day_Odometer_Reading_KM__c: '',
        UniqueFileId__c: '',
        Day_ended_time__c: null,
        Day_started_time__c: null,
        End_Day_Odometer_Reading_KM__c:'',
        Comments__c:''
    };
    kmTravelled = 0;
    purposeofVisitOptions = [];
    vehicleUsedOptions = [];
    travelTypeOptions = [];
    uniqueId = '';
    @track isCameraOpen = true;
    showUploadedFiles = false; 
    @track uploadedFiles = [];
    @track showCameraModal = false;
    isLoading = false;
    isShowOtherTravelType = false;
    checkinData = {locationType:'',
                    latitude:'',
                    longitude:'',
                    uniqueId:'',
                }
    confirmationBody ='';
    confimationheader = '';
    isShowConfirmation = false;
    get beatPlannercontainerClass() {
        return this.isStockScreen || this.isReturnScreen || this.isProductScreen || this.isOrderLineItemFulfillment || this.isCollectionsScreen ||
        this.isShelfStockScreen
        ? 'screen-1' : 'screenWithOutHeight';
    }
    loadingScreenSize = 2;
    @track visitDataFromChild  = [];
    currentOrderId = '';
    isShowBackButton = false;
    currentBeatId = '';
    isSSA_DSM = false;
    isstartodometermandatory = false;
    isEndOdomterMandatory = false;
    currentUser = {};
    isAllowedDevice = false;
    deviceRestictionMessage = '';
    currentLocationRequestId= '';

    //detect if LWC is running in mobile publisher
    isMobilePublisher = window.navigator.userAgent.indexOf('CommunityHybridContainer') > 0;

    //On Loading this method Will be called
    connectedCallback() {
        this.isPageLoaded = true;
        this.isDesktop = FORM_FACTOR === 'Large'? true : false;
        this.isPhone = FORM_FACTOR === 'Small'? true : false;
        this.loadingScreenSize =   this.isDesktop ? 2 : 3;
        if (FORM_FACTOR === 'Medium') this.isDesktop = true;
        this.disablePullToRefresh();
        this.getDailyLogDetails();
        this.containerClass = this.isDesktop ? 'slds-modal__container ' : '';
        this.uniqueId = 'FILE-' + Date.now()+ '-' +this.userId + '-' + Math.random().toString(36).substring(2, 10);
    }

    /**Start Day Popup */
    getDailyLogDetails() {
        if (!navigator.onLine) {
            this.isPageLoaded = false;
            this.showToast('Error', 'No internet connection. Please check your network and try again.', 'error');
            return;
        }
        DailyLogData({})
        .then(result => {
            console.log(result);
            //Checking device Access
            if ((this.isDesktop && result.isDesktopAllowed) || (this.isPhone && result.isMobileAllowed)) {
                this.isAllowedDevice = true;
            } else {
                if (this.isDesktop) {
                    this.deviceRestictionMessage = "You are not allowed to use Today's Visit tab on Desktop. Please contact your administrator.";
                } else if (this.isPhone) {
                    this.deviceRestictionMessage = "You are not allowed to use Today's Visit tab on Mobile. Please contact your administrator.";
                } else {
                    this.deviceRestictionMessage = "Your device is not supported for accessing Today's Visit tab. Please contact your administrator.";
                }

                
                this.isAllowedDevice = false;
            }


            this.Outlet = false;
            this.isBeatViewScreen = false;
            this.currentUser = result.currentUser;
            this.isPromoter= this.currentUser.Is_Promoter__c;
            this.isSSA_DSM = this.currentUser.Is_SSA_DSM__c;
            if (result.dailyLog) {
                // Assign each field to ensure reactivity
                this.dailylogData = {
                    Id: result.dailyLog.Id || null,
                    Purpose_of_Visit__c: result.dailyLog.Purpose_of_Visit__c || '',
                    Travel_Type__c: result.dailyLog.Travel_Type__c || '',
                    Start_Day_Odometer_Reading_KM__c: result.dailyLog.Start_Day_Odometer_Reading_KM__c || '',
                    Vehicle_Used__c : result.dailyLog.Vehicle_Used__c || '',
                    Comments__c:result.Comments__c,
                    Day_ended_time__c: result.dailyLog.Day_ended_time__c || null,
                    Day_started_time__c: result.dailyLog.Day_started_time__c || null
                };
                if(this.dailylogData.Vehicle_Used__c && this.dailylogData.Vehicle_Used__c !='Public transport')
                {
                    this.isEndOdomterMandatory = true;
                }

                if (!this.dailylogData.Day_ended_time__c && this.dailylogData.Day_started_time__c) {
                    this.buttonName = 'End Day';
                    this.isVisitCreate = true;
                }
                this.isDailyLog = !(this.dailylogData.Day_ended_time__c && this.dailylogData.Day_started_time__c);
                if(result.dailyLog.Current_Beat__c)
                {
                    this.isVisitCreate = true;
                    this.currentBeatId = result.dailyLog.Current_Beat__c;
                    this.Outlet = true;
                    this.header = 'Visit Plan';
                             
                }
                else
                {
                    this.isVisitCreate = false;
                    this.isBeatViewScreen = true;
                    this.header = 'Beats';
                }

            } else {
                // No dailyLog found
                this.dailylogData = {
                    Id: null,
                    Purpose_of_Visit__c:  'Customer Visit',
                    Travel_Type__c:'',
                    Start_Day_Odometer_Reading_KM__c: '',
                    Comments__c:result.Comments__c,
                    Day_ended_time__c: null,
                    Day_started_time__c: null
                };
                this.isVisitCreate = false;
                this.buttonName = 'Start Day';
                this.isDailyLog = true;
                this.isBeatViewScreen = true;
            }
            this.purposeofVisitOptions = result.purposeofVisit || [];
            this.vehicleUsedOptions = result.vehicleUsed || [];
            this.travelTypeOptions = result.travelType || [];
            this.isPageLoaded = false;
        })
        .catch(error => {
            console.error(error);
            this.isPageLoaded = false;
        });
    }
    isStartEndDay(){
        this.isRenderDataLoaded = true;
        const headerName = this.buttonName;
        this.isDailyLogPopup = true;
        this.isvisitDesktop = this.isDesktop ? true : false;
        this.uploadedFiles = [];
        this.showUploadedFiles = false;
        this.isDisabled = false;
        this.uniqueId = 'FILE-' + Date.now()+ '-' +this.userId + '-' + Math.random().toString(36).substring(2, 10);
        if(headerName == 'Start Day'){
            this.isStartDay = true;
           
        }
        else if(headerName == 'End Day'){
            this.isStartDay = false;
        }
    }
    closeDailypopup(){
        
        if (this.isPhone) {
            const cameraCmp = this.template.querySelector('c-capture-image-lwc');
            if (cameraCmp) {
                cameraCmp.stopCamerafromParent();
            }
        }
        this.isDailyLogPopup = false;
       // this.createDailyLog = false;
        this.isvisitDesktop = true;
        this.showCameraModal = false;
        this.dailylogData.End_Day_Odometer_Reading_KM__c = '';
        if(this.buttonName == 'Start Day')
        {
            this.dailylogData.Start_Day_Odometer_Reading_KM__c = ''; 
        }
        
    }
    handleDailylogInputChange(event)
    {
        const fieldName = event.target.name;
        const fieldValue  = event.detail.value;
        // Dynamically update the field in dailylogData
        this.dailylogData = { ...this.dailylogData, [fieldName]: fieldValue };
        console.log('fielvalue'+fieldValue);
        if(fieldName =='Travel_Type__c' && fieldValue == 'Other')
        {
            this.isShowOtherTravelType = true;
        }
        else if(fieldName =='Travel_Type__c' && fieldValue != 'Other')
        {
            this.isShowOtherTravelType = false;
        }
        else if(fieldName =='Vehicle_Used__c')
        {
            if(fieldValue == 'Public transport')
            {
                this.isstartodometermandatory = false;
            }
            else
            {
                this.isstartodometermandatory = true;
            }
          
        }
    }
    //File Uploads
    openCamera()
    {
        this.showCameraModal = true;
    }
    handleCameraStopped()
    {
        this.showCameraModal = false;
        this.loadAllFiles();
    }
    handleUploadFinished(event) {
        if (!navigator.onLine) {
            this.showToast('Error', 'No internet connection. Please check your network and try again.', 'error');
            return;
        }

        const files = event.detail.files;
        const fileIds = files.map(file => file.documentId);
        this.isLoading = true;
        updateDocument({ idList: fileIds, uniqueId: this.uniqueId })
            .then(() => {
                this.showToast('Success','Files uploaded successfully!', 'success');
                this.loadAllFiles();
            })
            .catch(err => {
                console.error('Upload error:', err);
                this.showToast('Upload failed', 'error');
                this.isLoading = false; // stop loader if upload fails
            });
    }  
    loadAllFiles() {
        if (!navigator.onLine) {
            this.showToast('Error', 'No internet connection. Please check your network and try again.', 'error');
            return;
        }
        this.isLoading = true;
        getFiles({ uniqueId: this.uniqueId })
        .then(result => {
            this.uploadedFiles = result || [];
            this.showUploadedFiles = this.uploadedFiles.length > 0;
        })
        .catch(error => {
            console.error('Error loading files:', error);
        })
        .finally(() => {
            this.isLoading = false;
        });
    }
    async deleteFile(event) {
        if (!navigator.onLine) {
            this.showToast('Error', 'No internet connection. Please check your network and try again.', 'error');
            return;
        }
        if (confirm('Confirm deleting this file?')) {
            const fileId = event.currentTarget.dataset.id;
            this.isLoading = true;
            try {
                await deleteFile({ contentDocumentId: fileId });
                this.showToast('Success','File has been deleted successfully!', 'Success');
                this.loadAllFiles();
            } catch (err) {
                console.error('Delete error', err);
                this.showToast('Error','Deletion failed', 'error');
            }
            this.isLoading = false;
        }
    }
    previewFile(event) {
        let recordId = event.currentTarget.dataset.id;
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

    /*Daily Log save Data*/
    saveDailyLogLocation(){
        if (!navigator.onLine) {
            this.showToast('Error', 'No internet connection. Please check your network and try again.', 'error');
            return;
        }
        if (this.validatestartDayFields()) {
            //Closing the Camera Popup
            if (this.isPhone) {
                const cameraCmp = this.template.querySelector('c-capture-image-lwc');
                if (cameraCmp) {
                    cameraCmp.stopCamerafromParent();
                }
            }
            this.isDisabled = true;
            if(this.buttonName == 'Start Day')
            {
                
                this.validateFileUpload();
            }
            else
            {
                this.handleGetLatLon('EndDay');
            }
            
        }
    }
    validatestartDayFields() {
        let isAllValid = true;
        let dailylogData = this.dailylogData; 
        if(this.buttonName == 'Start Day')
        {
            // both secoundary customer and primary customer fields
            if (!dailylogData.Purpose_of_Visit__c || !dailylogData.Vehicle_Used__c ||
            (!this.isSSA_DSM && !dailylogData.Travel_Type__c) ) {
                isAllValid = false;
                this.showFieldError('dailylogFields'); 
                this.showToast('Error', 'Please fill in all the mandatory fields', 'error');
                return isAllValid;
            }

            if(dailylogData.Vehicle_Used__c !='Public transport' && !dailylogData.Start_Day_Odometer_Reading_KM__c?.trim())
            {
                isAllValid = false;
                this.showFieldError('dailylogFields'); 
                this.showToast('Error', 'Please fill in all the mandatory fields', 'error');
                return isAllValid;
            }
            if(dailylogData.Travel_Type__c =='Other' && !dailylogData.Comments__c)
            {
                isAllValid = false;
                this.showFieldError('dailylogFields'); 
                this.showToast('Error', 'Please fill in all the mandatory fields', 'error');
                return isAllValid;
            }
        }
        else
        {
            const endOdo = dailylogData.End_Day_Odometer_Reading_KM__c;
            const startOdo = dailylogData.Start_Day_Odometer_Reading_KM__c;
            if (!endOdo?.toString().trim() && this.isEndOdomterMandatory) 
            {
                isAllValid = false;
                this.showFieldError('dailylogFields'); 
                this.showToast('Error', 'Please fill in all the mandatory fields', 'error');
                return isAllValid;
            }
            else if (endOdo <= startOdo && this.isEndOdomterMandatory) 
            {
                this.showToast('Error',  `End odometer reading must be greater than the start day odometer reading. Start reading: ${startOdo} KM`, 'error');
                isAllValid = false;
                return isAllValid;
            }
            
        }
      
        return isAllValid;
    }
    validateFileUpload()
    {
        if (!navigator.onLine) {
            this.isDisabled = false;
            this.showToast('Error', 'No internet connection. Please check your network and try again.', 'error');
            return;
        }
        this.isLoading = true;
        VALIDATE_FILE({
        uniqueFileId : this.uniqueId
        })
        .then(result => {
            if(result =='Success')
            {
                this.isLoading = false;
                this.isDisabled = true;
                
                this.handleGetLatLon('Startday');
            
            }
            else
            {
                this.isDisabled = false;
                this.isLoading = false;
                this.buttonName = 'Start Day';
                this.showToast('Error', 'Please upload an image to start your day', 'error');
            }
            
        })
        .catch(error => {
            console.error(error);
            this.isLoading = false;
        });
    }
    handleGetLatLon(locationProgress) {
        this.isLoading = true;
        let isResolved = false;
        this.currentLocationRequestId = null;

        const requestId = Math.random().toString(36).substring(2);
        this.currentLocationRequestId = requestId;
    
        // Timeout fallback (applies to both mobile and browser)
        const timeoutTimer = setTimeout(() => {
            if (!isResolved) {
                this.isLoading = false;
                this.isDisabled = false;
                this.currentLocationRequestId = null;
                this.showToast('Error', 'Please enable location permission to start your day', 'error');
                return;
            }
        }, 30000);
    
        if (this.isMobilePublisher) {
            // Mobile Publisher: use Nimbus Location Service
            getLocationService().getCurrentPosition({
                enableHighAccuracy: true
            }).then((result) => {
                // Only process if this is the latest request
                if (this.currentLocationRequestId !== requestId || isResolved) return;
                isResolved = true;
                clearTimeout(timeoutTimer);
                this.currentLocationRequestId = null;
    
                const newEvent = new CustomEvent('locationPharmacySearch:getLatLonResponse', { detail: {} });
                newEvent.detail.lat = result.coords.latitude;
                newEvent.detail.lon = result.coords.longitude;
                newEvent.detail.latlonsource = 'nimbus';
                newEvent.detail.status = 'success';
    
                console.log('newEvent: ' + JSON.stringify(newEvent));
                this.handleSaveDailyLog(newEvent, locationProgress);
    
            }).catch((error) => {
                // Only process if this is the latest request
                if (this.currentLocationRequestId !== requestId || isResolved) return;
                isResolved = true;
                clearTimeout(timeoutTimer);
                this.currentLocationRequestId = null; // Clear the request ID
                console.error('Mobile location error:', error);
                this.isLoading = false;
                this.showToast('Error', 'Unable to fetch location. Please ensure location is enabled.', 'error');
            });
    
        } else if (window.navigator && window.navigator.geolocation) {
            // Browser: use native geolocation
            window.navigator.geolocation.getCurrentPosition(
                (r) => {
                    // Only process if this is the latest request
                    if (this.currentLocationRequestId !== requestId || isResolved) return;
                    isResolved = true;
                    clearTimeout(timeoutTimer);
                    this.currentLocationRequestId = null; // Clear the request ID
    
                    const newEvent = new CustomEvent('locationPharmacySearch:getLatLonResponse', { detail: {} });
                    newEvent.detail.lat = r.coords.latitude;
                    newEvent.detail.lon = r.coords.longitude;
                    newEvent.detail.latlonsource = 'browser';
                    newEvent.detail.status = 'success';
    
                    this.handleSaveDailyLog(newEvent, locationProgress);
                },
                (err) => {
                    // Only process if this is the latest request
                    if (this.currentLocationRequestId !== requestId || isResolved) return;
                    isResolved = true;
                    this.isDisabled = false;
                    clearTimeout(timeoutTimer);
                    this.currentLocationRequestId = null;
                    console.error('Browser location error:', err);
                    this.isLoading = false;
                    this.showToast('Error', 'Please enable location permission to start your day', 'error');
                },
                { enableHighAccuracy: true }
            );
    
        } else {
            isResolved = true;
            clearTimeout(timeoutTimer);
            this.currentLocationRequestId = null; // Clear the request ID
            console.log('Location not supported');
            this.isDisabled = false;
            this.isLoading = false;
            this.showToast('Error', 'Location not supported on this device.', 'error');
        }
    }
    handleSaveDailyLog(event,locationProgress){
        let dailylogData = this.dailylogData;
        let details = JSON.parse(JSON.stringify(event.detail));
        if(locationProgress == 'Startday'){
            let data = {
                sobjectType: 'Daily_Log__c',
                Clock_In_Location__Longitude__s : details.lon,
                Clock_In_Location__Latitude__s : details.lat,
                Travel_Type__c:dailylogData.Travel_Type__c,
                Purpose_of_Visit__c:dailylogData.Purpose_of_Visit__c,
                UniqueFileId__c: this.uniqueId,
                Comments__c:this.Comments__c,
                Start_Day_Odometer_Reading_KM__c:dailylogData.Start_Day_Odometer_Reading_KM__c,
                Vehicle_Used__c:dailylogData.Vehicle_Used__c,               
                Day_started_time__c : new Date()
            };
            this.buttonName = 'End Day';
            this.saveUpdateRecord(locationProgress,data)
        }
        else if(locationProgress == 'EndDay'){
            let data = {
                sobjectType: 'Daily_Log__c',
                Id: dailylogData.Id,
                Day_started_time__c:dailylogData.Day_started_time__c,
                End_Day_Odometer_Reading_KM__c:dailylogData.End_Day_Odometer_Reading_KM__c,
                Clock_Out_Location__Latitude__s : details.lat,
                UniqueFileId__c: this.uniqueId,
                Clock_Out_Location__Longitude__s : details.lon,
                Day_ended_time__c : new Date()
            };
            this.saveUpdateRecord(locationProgress,data)
        }

    }
    saveUpdateRecord(operation, data) {
        if (!navigator.onLine) {
            this.isPageLoaded = false;
            this.isLoading = false;
            this.showToast('Error', 'No internet connection. Please check your network and try again.', 'error');
            return;
        }
        upsertDailyLog({ dailylog: data, operation: operation })
            .then(result => {
                this.isDailyLogPopup = false;
                this.isLoading = false;
                this.isvisitDesktop = true;
                this.dailylogData = result.Dailylog;
                this.isDisabled = false;
                this.isPageLoaded = false;
                const status = result.IsSuccess;
    
                if (status === 'true') {
                    const message = operation === 'Startday' ? 'Day Started Successfully' : 'Day Ended Successfully';
                    this.genericDispatchEvent('Success', message, 'success');
                    
                    if( operation === 'Startday')
                    {
                        this.isDailyLog = true;
                    }
                    else
                    {
                        this.isDailyLog = false;
                    }
                
                } else if (status === 'daystarted') {
                    this.isDailyLog = true;
                    this.genericDispatchEvent('Info', 'Day already started. Please refresh and check again', 'Info');
                } else if (status === 'endstarted') {
                    this.isDailyLog = false;
                    this.genericDispatchEvent('Info', 'Day already ended. Please refresh and check again', 'Info');
                } else {
                    this.isDailyLog = true;
                    this.genericDispatchEvent('Info', 'Please refresh and try again to perform action', 'Info');
                }
                
                if(this.dailylogData.Current_Beat__c)
                {
                    this.isVisitCreate = true;
                    this.currentBeatId = this.dailylogData.Current_Beat__c;
                    this.header = 'Visit Plan';
                    
                    if(this.isBeatViewScreen == true)
                    {
                        this.refrshBeatScreen();
                    }
                    else
                    {
                        this.refreshOutletScreen2();
                    }
                }
                else
                {
                    this.header = 'Beats';
                    this.isVisitCreate = false;
                    this.refrshBeatScreen();
                    
                }

                if(this.dailylogData.Vehicle_Used__c && this.dailylogData.Vehicle_Used__c !='Public transport')
                {
                    this.isEndOdomterMandatory = true;
                }
                else
                {
                    this.isEndOdomterMandatory = false;
                }
          
            })
            .catch(error => {
                this.isDailyLog = false;
                this.isPageLoaded = false;
                this.isLoading = false;
                this.isDisabled = false;
                console.error('Error creating record:', error);
            });
    }

    /**Switch Beat**/
    switchBeat() {
        if (!navigator.onLine) {
            this.showToast('Error', 'No internet connection. Please check your network and try again.', 'error');
            return;
        }
        setTimeout(() => {
            const childComp = this.template.querySelector('c-outlet-screen2');
            if (childComp) {
                // Wait for child to emit event
                childComp.validateInprogressVisit();
            } else {
                console.error('Child component not found');
            }
        }, 0);
    }
    
    /**Visit Data */
    visitCreate(){
        this.isvisitDesktop = this.isDesktop ? true : false;
        this.currentLogId = this.dailylogData.Id == undefined ? this.dailylogData.id : this.dailylogData.Id;
        this.newVisitPoup = true;
    }
    onClickVisitPopup(event){ 
        const msg = event.detail;
        console.log(msg);
        if(msg.message == 'Close'){
            this.newVisitPoup = false;
            this.isvisitDesktop = true;
        }
        if(msg.message == 'Save'){
            this.genericDispatchEvent('Success','Visit Saved successfully','success');
            this.newVisitPoup = false;
            this.isvisitDesktop = true;
            if(this.Outlet){
               this.refreshOutletScreen2();
            }
        }
    }
    completeVisit(){
        if (!navigator.onLine) {
            this.showToast('Error', 'No internet connection. Please check your network and try again.', 'error');
            return;
        }
        setTimeout(() => {
            const childComp = this.template.querySelector('c-execute-screen3');
            if (childComp) {
                childComp.handleCheckOutVisit();
            } else {
                console.error('Child component not found');
            }
        }, 0);
    }


    /**------Dispatch Methods-----------*/
    //when beat start,switch,execute from Beat Screen
    handleBeatCustomEvent(event){
        this.resetAllScreen();
        this.isShowBackButton = false;
        this.header = 'Visit Plan';
        const msg = event.detail;
        this.currentBeatId = msg.beatId;
        this.Outlet = true;//Making the Outlet Screen 2 show 
        this.isVisitCreate = true
    }
    /**When beat Switch button clicked */
    handleBeatCheck(event) {
        this.resetAllScreen();
        this.isShowBackButton = false;
        if (event.detail.canSwitch) {
            this.isBeatViewScreen = true;
            this.header = 'Beats';
        } else {
            this.isBeatViewScreen = false;
            this.Outlet = true;
            this.isVisitCreate = true;
            
        }
    }

    //When Outlet screen Play button or arrow button clicked
    handleCustomEvent(event){
        this.isShowBackButton = true;
        console.log('Beatplanner Entered inside');
        const msg = event.detail;
        if(msg.message == 'executeScreen'){
            this.checkinData.locationType =  msg.locationType;
            this.checkinData.latitude =  msg.latitude;
            this.checkinData.longitude =  msg.longitude;
            this.checkinData.uniqueId =  msg.uniqueId;
            this.VisitListName = msg.VisitListName;
            this.header = this.VisitListName;
            this.Outlet = false;
            this.recordId = msg.recordID;
            this.index = msg.index;
            this.isExecuteScreen = true;
            this.screen = msg.screen;
            this.executeScreenData.isProgressVisit = msg.isProgressVisit;
            this.executeScreenData.isAcc = msg.isAcc;
            this.executeScreenData.isPrimaryCustomer = msg.isPrimaryCustomer;
            this.executeScreenData.isSecoundaryCustomer = msg.isSecoundaryCustomer;           
            this.executeScreenData.isCompleted = msg.isCompleted;
            this.executeScreenData.isInProgress = msg.isInProgress;
            this.showVisitButton = msg.isInProgress
            this.outletPage = true;
            this.acccountId  = msg.accId;
            this.visitfor = msg.visitfor;
            this.objName = msg.objName;
            this.visitData = msg.visitData;
            this.isplayButtonClicked = msg.isplayButtonClicked;

            this.isVisitHeader = true;
            if(msg.startCall){
                this.executeScreenData.isInProgress = true;
            }
        }
        
    }
    /**When Arrow button Cliked on the Executive Scrren 3 */
    handleProductScreen(event){
        this.isShowBackButton = true;
        const msg = event.detail;
        this.resetAllScreen();
        this.outletPage = true;
        this.navBarClass = 'navbar';
        if(msg.message == 'productScreen'){
            this.header = 'Product';
            this.recordId = msg.recordID;
            this.index = msg.index;
            this.screen = msg.screen;
            this.isVisitHeader = true;
            this.isProductScreen = true;
            this.currentLogId = this.dailylogData.Id;
        }
        else if(msg.message == 'StockSCreen'){
            this.header = 'Stock';
            this.recordId = msg.recordID;
            this.index = msg.index;
            this.screen = msg.screen;
            this.isVisitHeader = true;
            this.isProductScreen = false;
            this.isStockScreen = true;
            this.currentLogId = this.dailylogData.Id;
        }
        else if(msg.message == 'collectionScreen'){
            this.header = 'Collections';
            this.recordId = msg.recordID;
            this.screen = msg.screen;
            this.isVisitHeader = true;
            this.isCollectionsScreen = true;
        }
        else if(msg.message == 'DisplayScreen'){
            this.header = 'Display Format';
            this.recordId = msg.recordID;
            this.screen = msg.screen;
            this.isVisitHeader = true;
            this.isDisplayScreen = true;
        }
        else if(msg.message == 'OrderFulfillments'){
            this.header = 'Order Fulfillments';
            this.recordId = msg.recordID;
            this.screen = msg.screen;
            this.isVisitHeader = true;
            this.isOrderFulfillment = true;
        }
        else if(msg.message == 'OrderLineItemscreen'){
            this.header = 'Order Line Item';
            this.visitId = msg.visitId;
            this.currentOrderId = msg.recordID //order id
            this.recordId = msg.visitId;//visit Id
            this.screen = msg.screen;
            this.isVisitHeader = true;
            this.isOrderLineItemFulfillment = true;
        }
        else if(msg.message == 'taskScreen'){
            this.header = 'Task';
            this.recordId = msg.recordID;
            this.screen = msg.screen;
            this.isTaskScreen = true;
            this.outletPage = true;
        }
        else if(msg.message == 'CompetitorScreen'){
            this.header = 'Competitor Analysis';
            this.recordId = msg.recordID;
            this.screen = msg.screen;
            this.isCometitionScreen = true;
            this.outletPage = true;
        }
        else if(msg.message == 'checkout'){
            this.isExecuteScreen = true;
            this.executeScreenData.isInProgress = false;
        }
        else if(msg.message == 'cameraScreen'){
            this.header = 'Capture Image';
            this.recordId = msg.recordID;
            this.screen = msg.screen;
            this.isCameraScreen = true;
            this.outletPage = true;
        }
        else if(msg.message == 'order' || msg.message == 'outstanding' || msg.message == 'sales' || msg.message == 'visit' ||  msg.message == 'return'){
            this.recordId = msg.recordID;
            this.screen = msg.screen;
            this.isBusinessSummaryScreen = true;
            this.objName = msg.message;
        }
        else if(msg.message=='returnScreen')
        {
            this.recordId = msg.recordID;
            this.header = 'Returns';
            this.screen = msg.screen;
            this.objName = msg.message;
            this.outletPage = true;
            this.isReturnScreen = true;
        }
        else if(msg.message=='ShelfStockScreen')
        {
            
            this.recordId = msg.recordID;
            this.header = 'Shelf Stock';
            this.screen = msg.screen;
            this.objName = msg.message;
            this.outletPage = true;
            this.isShelfStockScreen = true;
        }
    }
    //After saving of order or Stock or we will redirect to the execute screen 3
    handleOrderScreen(event){
        this.isShowBackButton = true;
        const msg = event.detail;
        if(msg.message == 'executeScreen'){
            this.resetAllScreen();
            if(msg.screen == 3.2){ 
                this.isplayButtonClicked = false;
                this.header = this.VisitListName;
                this.isExecuteScreen = true;
                this.screen = 3;
                this.isVisitHeader = true;
                this.outletPage = true;
                this.isVisitCreate = true;
                this.outletPage = true;
                
            }
        }
        else if(msg.message == 'comboBox'){
            this.navBarClass = 'navBarSpace';
            this.productCatDropdown = msg.productCatDropdown;
        }
    }

    
    /**Confirmation Popup */
    handleConfirmationYes() {
        if (!navigator.onLine) {
            this.isPageLoaded = false;
            this.showToast('Error', 'No internet connection. Please check your network and try again.', 'error');
            return;
        }
        this.isShowConfirmation = false;
        this.isDailyLog = false;
        this.isPageLoaded = true;
        this.handleGetLatLon('EndDay');
        this.isVisitCreate = false;
    }
    handleConfirmationNo() {
        this.isShowConfirmation = false;
    }

    /**-----Helper Methods-------**/
    refreshOutletScreen2()
    {
        setTimeout(() => {
            const childComp = this.template.querySelector('c-outlet-screen2');
            if (childComp) {
                childComp.handleUpdateChange();
            } else {
                console.error('Child component not found');
            }
        }, 0);
    }
    refrshBeatScreen()
    {
        setTimeout(() => {
            const childComp = this.template.querySelector('c-beat-screen');
            if (childComp) {
                childComp.handleDailyLogChange();
            } else {
                console.error('Child component not found');
            }
        }, 0);
    }
    async genericConfirmationPopup(message,label,theme){
        const result = await LightningConfirm.open({
            message: message,
            variant: 'header',
            label: label,
            theme: theme
            // setting theme would have no effect
        });
        if (result) {
            this.isDailyLog = false;
            this.isPageLoaded = true;
            this.handleGetLatLon('Checkout');
            this.isVisitCreate = false;
            //true
        } else {
            //false
        }
    }
    genericDispatchEvent(title,message,variant){
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant
            })
        );
    }
    goBackScreen(){
        this.isplayButtonClicked = false;
        const sc= this.screen;
        if(sc == 1){
            this.isShowBackButton = false;
            return;
        }
        this.resetAllScreen();
        if(sc == 0){
            this.Outlet = true;
            this.header = 'Visit Plan';
            this.isVisitCreate = true;
            this.isShowBackButton = false;
        }
        if(sc == 2){
            this.header = 'Visit Plan';
            this.Outlet = true;
            this.screen = 1;
            this.isShowBackButton = false;
            this.isVisitCreate = true;
        }
        else if(sc == 2.2){
            this.Outlet = true;
            this.header = 'Visit Plan';
            this.screen = 2;
            this.isShowBackButton = false;
            this.isVisitCreate = true;
        }
        else if(sc == 3){
            this.Outlet = true;
            this.header = 'Visit Plan';
            this.screen = 1;
            this.isShowBackButton = false;
            this.isVisitHeader = true;
            this.isVisitCreate = true;
        }
        else if(sc == 3.2){
            this.header = this.VisitListName;
            this.isExecuteScreen = true;
            this.screen = 3;
            this.isVisitHeader = true;
            this.outletPage = true;
            this.isVisitCreate = true;
            this.outletPage = true;
            this.executeScreenData.isProgressVisit = true;
        }
        else if(sc == 3.3){
            this.header = this.VisitListName;
            this.isExecuteScreen = true;
            this.screen = 3;
            this.isVisitHeader = true;
            this.outletPage = true;
        }
        else if(sc == 3.4){
            this.header = this.VisitListName;
            this.isExecuteScreen = true;
            this.screen = 3;
            this.isVisitHeader = true;
            this.outletPage = true;
        }
        else if(sc == 3.5){
            this.header = this.VisitListName;
            this.isExecuteScreen = true;
            this.screen = 3;
            this.isVisitHeader = true;
            this.outletPage = true;
            this.isCometitionScreen = false;
        }
        else if(sc == 3.6){
            this.header = 'Order Fulfillments';
            this.isOrderFulfillment = true;
            this.screen = 3.3;
            this.isVisitHeader = true;
        }
    }
    resetAllScreen(){
        this.isBeatViewScreen = false;
        this.isShowBackButton = true;
        this.isBusinessSummaryScreen = false;
        this.isExecuteScreen = false;
        this.isVisitHeader = false;
        this.isProductScreen = false;
        this.isStockScreen = false;
        this.isCollectionsScreen = false;
        this.Outlet = false;
        this.isTaskScreen = false;
        this.isDisplayScreen = false;
        this.isOrderFulfillment = false;
        this.isOrderLineItemFulfillment = false;
        this.isHomePage = false;
        this.isVisitHeader = false;
        this.isHomePage = false;
        this.isVisitCreate = false;
        this.outletPage = false;
        this.isCameraScreen = false;
        this.isReturnScreen = false;
        this.isShelfStockScreen = false;
    }
    refreshData(){
        if (!navigator.onLine) {
            this.showToast('Error', 'No internet connection. Please check your network and try again.', 'error');
            return;
        }
        this.resetAllScreen();
        this.isPageLoaded = true;
        this.isRenderDataLoaded = true;
        this.Outlet = true;
        this.isShowBackButton = false;
        this.getDailyLogDetails();
       // this.isPageLoaded = false;
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
    //Show Toast
    showToast(title, message, variant) {
    this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
    showFieldError(fieldPrefix) {
        const inputFields = this.template.querySelectorAll(`[data-id^="${fieldPrefix}"]`); 
        if (inputFields.length > 0) {
            inputFields.forEach(input => {
                input.reportValidity(); // Show validation error
            });
        }
    }

    /**Not in Use */
    handleChangeCategory(event) {
        const val = event.detail.value;
        setTimeout(() => {
           
            const childComp = this.isProductScreen ? this.template.querySelector('c-product-screen4') : this.template.querySelector('c-stock-screen4');
            if (childComp) {
                //childComp.category = val;
                childComp.handleChangeCategory(val);
            } else {
                console.error('Child component not found');
                //alert(('Child component not found'))
            }
        }, 0);
    }
    onChangeProducts(event){
        const val = event.target.value;
        setTimeout(() => {
            const childComp = this.isProductScreen ? this.template.querySelector('c-product-screen4') : this.template.querySelector('c-stock-screen4');
            //const childComp = this.template.querySelector('c-product-screen4');
            if (childComp) {
                //childComp.category = val;
                childComp.onChangeProducts(val);
            } else {
                console.error('Child component not found');
                //alert(('Child component not found'))
            }
        }, 0);
    }

}