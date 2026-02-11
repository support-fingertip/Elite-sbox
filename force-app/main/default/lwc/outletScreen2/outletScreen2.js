import { LightningElement,track ,api} from 'lwc';
import PLANNER_ICON from '@salesforce/resourceUrl/planner';
import SORTING_ICON from '@salesforce/resourceUrl/sorting';
import getApexData from '@salesforce/apex/beatPlannerlwc.getVisitData';
import { getLocationService } from 'lightning/mobileCapabilities';
import { updateRecord,createRecord  } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import GOOGLE_ICONS from '@salesforce/resourceUrl/googleIcons';
import { NavigationMixin } from 'lightning/navigation';
import LightningConfirm from 'lightning/confirm';
import getFiles from '@salesforce/apex/beatPlannerlwc.getVisitFiles';
import deleteFile from '@salesforce/apex/beatPlannerlwc.deleteFile';
import VALIDATE_FILE from '@salesforce/apex/beatPlannerlwc.validateVisitFileUpload';
import VALIDATE_GEO_FENCING from '@salesforce/apex/beatPlannerlwc.getGeoFencing';
import COMPLETE_Visit from '@salesforce/apex/beatPlannerlwc.completeVisit';
import FORM_FACTOR from '@salesforce/client/formFactor';
import Id from '@salesforce/user/Id';
import updateDocument from '@salesforce/apex/beatPlannerlwc.updateDocument';


export default class OutletScreen2 extends NavigationMixin(LightningElement) {

    userId = Id;
    googleIcons = {
        account : GOOGLE_ICONS + "/googleIcons/apartment.png",
        sort : GOOGLE_ICONS + "/googleIcons/sort.png",
        progress : GOOGLE_ICONS + "/googleIcons/progress.png",
        play : GOOGLE_ICONS + "/googleIcons/play.png",
        forward : GOOGLE_ICONS + "/googleIcons/forward.png"
    }
    @api currentBeatId;
    @api screenHeight;
    hrs = PLANNER_ICON + "/planner/screen-1-24.png";
    week = PLANNER_ICON + "/planner/screen-1-week.png";
    year = PLANNER_ICON + "/planner/screen-1-year.png";  
    sortingIcon = SORTING_ICON ;
    @track buttonSelectedIcon =this. hrs;
    @track buttonSelected = 'Day';
    @api isParentComp;
    @track isDropdownfilterOpen = false;
    @api isDesktop;
    searchVisit = '';
    @track originalVisitData = [];
    fromDate = this.formatDate(new Date());
    toDate = this.formatDate(new Date());
    @track VisitData = [];
    isDesktopCheckoutPage = true;
    completeVisit = false;
    sortingTitle = 'Ascending'
    currentVisitId;
    selectedDropdownId = '';
    isOutletScreen = true; newVisit = false;
    selectedDropdownIndex = '';
    isOneDay = true; openVisit = false; Reshedule = false;
    isPageLoaded = false;
    StartCallHeader = 'Start Call';
    isProgressVisit;
    comment; 
    routeDropdown;
    confirmationBody ='';
    confimationheader = '';
    confirmationMessage = {};
    isShowStartVisit = false;
    showUploadedFiles = false; 
    @track uploadedFiles = [];
    @track showCameraModal = false;
    isLoading = false;
    containerClass;
    isDisabled = false;
    checkInAnyway = false;
    currentVisitBeatId = '';
    currentvisitCustomerType =false;
    isDesktop = false;
    isPhone = false;
    loadingScreenSize = 2;
    get startVisitButtonLabel() {
        return this.checkInAnyway ? 'Proceed' : 'Save';
    }
    isCameraOpen = true;
    uniqueId =''
    currentVisitData ={};
    isDayStarted = false;
    isPlaybuttonClicked = true;
    
    //detect if LWC is running in mobile publisher
    isMobilePublisher = window.navigator.userAgent.indexOf('CommunityHybridContainer') > 0;


    @api handleUpdateChange(){
        this.getTheDateBackend();
    }
    
    @api validateInprogressVisit() {
        if (this.isProgressVisit) {
             this.genericDispatchToastEvent('Error','Please complete the in-progress visit before switching the beat.','Error');
            // Notify parent that switching is not allowed
            this.dispatchEvent(new CustomEvent('beatcheck', { detail: { canSwitch: false } }));
        } else {
            // Notify parent that switching is allowed
            this.dispatchEvent(new CustomEvent('beatcheck', { detail: { canSwitch: true } }));
        }
    }

    connectedCallback(){
        this.isParentComp = this.isParentComp ? true : false;
        this.containerClass = this.isDesktop ? 'slds-modal__container ' : '';
        this.loadingScreenSize = this.isDesktop ? 2 : 3;
        this.isDesktop = FORM_FACTOR === 'Large'? true : false;
        this.isPhone = FORM_FACTOR === 'Small'? true : false;
        if (FORM_FACTOR === 'Medium') this.isDesktop = true;
        this.getTheDateBackend();
    }
    getTheDateBackend() {
        if (!navigator.onLine) {
            this.genericDispatchToastEvent('Error', 'No internet connection. Please check your network and try again.', 'error');
            return;
        }
        this.isPageLoaded = true;
        getApexData({currentBeatId:this.currentBeatId})
        .then(result => {
            //alert('hello');
            this.isDayStarted = result.isDayStarted;
            this.forOneDayData(result);
            const pop = this.template.querySelector(".popup");
            if(pop){
                pop.style.display =  "";
            }
            this.isPageLoaded = false;
        })
        .catch(error => {
            this.isPageLoaded = false;
            console.error(error);
        });
    }
    forOneDayData(result){
        const today = new Date().toISOString().split('T')[0]; // Get today's date in 'YYYY-MM-DD' format
        
        let todayDay = new Date(); // Get the current date
        let day = String(todayDay.getDate()).padStart(2, '0'); // Get day and add leading zero if necessary
        let month = String(todayDay.getMonth() + 1).padStart(2, '0'); // Get month (January is 0!) and add leading zero
        let year = todayDay.getFullYear(); // Get the full year
        let inProgressStatus = false;
        // Format today's date as 'DD/MM/YYYY'
        let formattedDate = `${day}/${month}/${year}`;
        //alert(JSON.stringify(result));
        result.visit.forEach(itm => {
            const visitDate = itm.VisitDate ? new Date(itm.VisitDate).toISOString().split('T')[0] : null;
            itm.showMenu = (itm.status != 'In Progress' || itm.status != 'Planned') ? true : false;
            itm.showMenuPlanned = itm.status == 'Planned' ? true : false;
            itm.showMenuInProgress = itm.status == 'In Progress' ? true : false;
            itm.showMenuCompleted = itm.status == 'Completed' ? true : false;
            itm.showMenuMissed = itm.status == 'Missed' ? true : false;
            if (itm.status === 'In Progress') {
                inProgressStatus = true;
            } 
            itm.isAcc = (itm.visitTypes == 'Primary Customer' || itm.visitTypes == 'Secondary Customer') ? true : false;
            itm.isPrimaryCustomer = itm.visitTypes == 'Primary Customer' ? true: false;
            itm.isSecoundaryCustomer = itm.visitTypes == 'Primary Customer' ? true: false;
            itm.isMoreLoad = true;
            itm.isShowAllData = itm.formattedVisitDate == formattedDate ? false : true;
            itm.execute = visitDate === today ? true : false;
            itm.openPopup = false;
        });
        const statusOrder = ['In Progress', 'Planned', 'Completed', 'Missed'];
        // Sort based on defined status order
        result.visit.sort((a, b) => {
            return statusOrder.indexOf(a.status) - statusOrder.indexOf(b.status);
        });
        this.isProgressVisit = inProgressStatus;
        this.VisitData = result.visit;
        this.originalVisitData = result.visit;
    }
    handleOnclickMenu(event) {
        if (!navigator.onLine) {
            this.genericDispatchToastEvent('Error', 'No internet connection. Please check your network and try again.', 'error');
            return;
        }
        const itemId = event.currentTarget.dataset.id;
        const index = parseInt(event.currentTarget.dataset.index, 10);
        this.currentVisitId = itemId;
        this.currentVisitBeatId = this.VisitData[index].visitPlanId ?  this.VisitData[index].visitPlanId : '';
        this.currentvisitCustomerType = this.VisitData[index].visitTypes == 'Primary Customer' ? true : false;
        const itemName = event.currentTarget.dataset.name;
        if(itemName == 'Execute_StartCall'){
           
            this.uniqueId = 'FILE-' + Date.now()+'Checkin'+ '-' +this.userId + '-' + Math.random().toString(36).substring(2, 10);
            const  message = { 
                message: 'executeScreen' ,
                startCall:true,
                recordID : itemId,
                index : index,
                screen : 2.2,
                isAcc : this.VisitData[index].isAcc,
                isPrimaryCustomer: this.VisitData[index].isPrimaryCustomer,
                isSecoundaryCustomer: this.VisitData[index].isSecoundaryCustomer,
                isInProgress : this.VisitData[index].showMenuInProgress,
                isProgressVisit : this.isProgressVisit,
                isCompleted : this.VisitData[index].showMenuCompleted,
                accId : this.VisitData[index].acccountId ? this.VisitData[index].acccountId : '',
                VisitListName : this.VisitData[index].accountName,
                visitData : this.VisitData[index],
                isplayButtonClicked : true,
                locationType: '',
                latitude:'',
                longitude:'',
                uniqueId:this.uniqueId
            };
            this.confirmationMessage = message;
            this.isShowStartVisit = true;
           
            this.loadAllFiles();
        }
        else if(itemName == 'Execute'){
           const  message = { 
            message: 'executeScreen' ,
            recordID : itemId,
            startCall:false,
            index : index,
            screen : 2.2,
            isAcc : this.VisitData[index].isAcc,
            isInProgress : this.VisitData[index].showMenuInProgress,
            isPrimaryCustomer: this.VisitData[index].isPrimaryCustomer,
            accId : this.VisitData[index].acccountId ? this.VisitData[index].acccountId : '',
            isProgressVisit : this.isProgressVisit,
            isCompleted : this.VisitData[index].showMenuCompleted,
            VisitListName : this.VisitData[index].accountName,
            visitData : this.VisitData[index],
            isplayButtonClicked : false
            };
            this.genericDispatchEvent(message);
            this.isOutletScreen = false;
        }
        else if(itemName == 'EndCall'){
            this.isDesktopCheckoutPage = this.isDesktop ? true : false;
            this.completeVisit = true;
            this.Reshedule = false;
            this.openVisit = true;
        }
        else if(itemName == 'Reshedule'){
            this.isDesktopCheckoutPage = this.isDesktop ? true : false;
            this.currentVisitData =  this.VisitData[index];
            this.completeVisit = false;
            this.Reshedule = true;
            this.openVisit = true;
        }
        else if(itemName == 'cancel'){
            const index1 = parseInt(event.currentTarget.dataset.index, 10); // Convert index from string to number
            this.VisitData = this.VisitData.map((item, i) => {
                return {
                    ...item,
                    openPopup: i === index1 ? !item.openPopup : false
                }; 
            });
            this.VisitData = [...this.VisitData];
        }
        else if(itemName == 'OpenStore'){
            const index1 = parseInt(event.currentTarget.dataset.index, 10);
            const ids = this.VisitData[index1].acccountId;
            if(ids != undefined ){
                this[NavigationMixin.GenerateUrl]({
                    type: "standard__recordPage",
                    attributes: {
                        recordId: ids,
                        actionName: 'view'
                    }
                }).then(url => {
                    if(this.isDesktop){
                        //window.location.href = url;
                        window.open(url, "_blank");
                    }else{
                        window.location.href = url;
                    }
                    
                });
            }else{
                this.genericDispatchToastEvent('','Cannot open page','info');
            }
            
        }
        else if(itemName == 'NavigateToMap'){
            const lattitudCordinate = event.currentTarget.dataset.latitude;
            const longitudeCordinate = event.currentTarget.dataset.longitude;

            if (lattitudCordinate && longitudeCordinate) {
                var url = 'https://www.google.com/maps?q=' + lattitudCordinate + ',' + longitudeCordinate;
                window.open(url, '_blank');
            } else {
                this.genericDispatchToastEvent('Error','Latitude and Longitude not found for Customer','error');
            }

        }
    }

    /**Start Visit Popup*/
    openCamera(){
        this.showCameraModal = true;
    }
    handleCameraStopped()
    {
        this.showCameraModal = false;
        this.loadAllFiles();
    }
    
    async handleUploadFinished(event) {
        if (!navigator.onLine) {
            this.genericDispatchToastEvent('Error', 'No internet connection. Please check your network and try again.', 'error');
            return;
        }
        const files = event.detail.files;
        const fileIds = files.map(file => file.documentId);
        try {
            await updateDocument({ idList: fileIds, uniqueId: this.uniqueId });
            this.genericDispatchToastEvent('Success', 'Files uploaded successfully!', 'success');
            this.loadAllFiles();
        } catch (err) {
            console.error('Upload error', err);
            this.genericDispatchToastEvent('Error', 'Upload Failed !!', 'Error');
        }
    }
    loadAllFiles() {
        if (!navigator.onLine) {
            this.genericDispatchToastEvent('Error', 'No internet connection. Please check your network and try again.', 'error');
            return;
        }
        this.isLoading = true;
        getFiles({uniqueId:this.uniqueId })
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
            this.genericDispatchToastEvent('Error', 'No internet connection. Please check your network and try again.', 'error');
            return;
        }
        if (confirm('Confirm deleting this file?')) {
            const fileId = event.currentTarget.dataset.id;
            this.isLoading = true;
            try {
                await deleteFile({ contentDocumentId: fileId });
                this.genericDispatchToastEvent('Success','File has been deleted successfully!', 'Success');
                this.loadAllFiles();
            } catch (err) {
                console.error('Delete error', err);
                this.genericDispatchToastEvent('Error','Deletion failed', 'error');
            }
            this.isLoading = false;
        }
    }
    previewFile(event) {
        if (!navigator.onLine) {
            this.genericDispatchToastEvent('Error', 'No internet connection. Please check your network and try again.', 'error');
            return;
        }
        let recordId = event.currentTarget.dataset.id;
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

    //Search Visits
    onChangeVisit(event){
        const searchTerm = event.target.value.toLowerCase();
        this.searchVisit = event.target.value;
        if (!searchTerm) {
            this.VisitData = [...this.originalVisitData];
            //this.filteredVisitData = [...this.VisitData]; // Reset if search is empty
            return;
        }
        this.VisitData = this.originalVisitData.filter(product => product.accountName.toLowerCase().includes(searchTerm));
    }
    
    /**---------- Start visit And Complete Visit (from the 3 dot icon)-----------**/
    closeVisitpopup(){
        
        if (this.isPhone) {
            const cameraCmp = this.template.querySelector('c-capture-image-lwc');
            if (cameraCmp) {
                cameraCmp.stopCamerafromParent();
            }
        }
        this.isShowStartVisit = false;
        this.showCameraModal = false;
        this.isLoading = false;
        this.checkInAnyway = false; 
        
    }
    startVisit()
    {
        if (this.isPhone) {
            const cameraCmp = this.template.querySelector('c-capture-image-lwc');
            if (cameraCmp) {
                cameraCmp.stopCamerafromParent();
            }
        }
        if (!navigator.onLine) {
            this.genericDispatchToastEvent('Error', 'No internet connection. Please check your network and try again.', 'error');
            return;
        }
        this.isLoading = true;
        VALIDATE_FILE({uniqueId : this.uniqueId})
        .then(result => {
            if(result =='Success')
            {
                this.handleGetLatLon(this.currentVisitId,'Start Visit');
            }
            else
            {
                this.isLoading = false;
                this.genericDispatchToastEvent('Error', 'Please upload an image to start your visit', 'error');
            }
        })
        .catch(error => {
            console.error(error);
            this.isLoading = false;
        });
    }
    createNewVisit(event){
        const msg = event.detail;
        if(msg.message == 'createNewVisit'){
            this.comment = msg.Comment;
            this.handleGetLatLon(this.currentVisitId,'Complete Visit');
        }
        else if(msg.message == 'Close'){
            this.completeVisit = false;
            this.Reshedule = false;
            this.openVisit = false;
            this.isDesktopCheckoutPage = true;
        }
        else if(msg.message == 'missedReason'){
            this.missedReason = msg.missedReason;
            this.missedDate = msg.missedDate;
            let fields  = {
                PostPoned_Start_Time__c : msg.missedDate,
                Missed_PostPone_Reason__c : msg.missedReason,
                Account1__c:msg.accountId,
                Planned_Start_Time__c: msg.plannedDate,
                Child_beat__c:msg.beatId,
                Beat_Item__c:msg.beatItem,
                Visit_for__c:msg.visitfor,
                Daily_Log__c:msg.dailyLogId,
                Approval_Status__c : 'Approved',
                Status__c : 'Missed'
            };
            const recordInput = {
                apiName: 'Visit__c',
                fields
            };

            this.createNewRecord(recordInput, 'Visit Missed Sccessfully');
        }
    }
    handleGetLatLon(itemId,operation) {
        this.isLoading = true;
        let isResolved = false;
        // Timeout fallback (applies to both mobile and browser)
        const timeoutTimer = setTimeout(() => {
            if (!isResolved) {
                this.isLoading = false;
                this.isDisabled = false;
                this.genericDispatchToastEvent('Error', 'Please enable location permission to start your visit', 'error');
            }
        }, 30000);
        if(this.isMobilePublisher)
        {
            //invoke Location Service native mobile capability feature
            getLocationService().getCurrentPosition({
            enableHighAccuracy: true
                }).then((result) => {
                    isResolved = true;
                    clearTimeout(timeoutTimer);

                    var newEvent = new CustomEvent('locationPharmacySearch:getLatLonResponse',{detail:{}});
                    newEvent.detail.lat = result.coords.latitude;
                    newEvent.detail.lon = result.coords.longitude; 
                    newEvent.detail.latlonsource = 'nimbus';
                    newEvent.detail.status = 'success';

                    console.log('newEvent: ' + JSON.stringify(newEvent));
                    this.handleSaveVisitData(newEvent,itemId,operation);

                }).catch((error) => {
                    isResolved = true;
                    clearTimeout(timeoutTimer);
                    console.error('Mobile location error:', error);
                    this.isLoading = false;
                    this.genericDispatchToastEvent('Error', 'Unable to fetch location. Please ensure location is enabled.', 'error');
                });

        }
        else if (window.navigator && window.navigator.geolocation) {
            // Browser: use native geolocation
            window.navigator.geolocation.getCurrentPosition(
                (r) => {
                    isResolved = true;
                    clearTimeout(timeoutTimer);
    
                    const newEvent = new CustomEvent('locationPharmacySearch:getLatLonResponse', { detail: {} });
                    newEvent.detail.lat = r.coords.latitude;
                    newEvent.detail.lon = r.coords.longitude;
                    newEvent.detail.latlonsource = 'browser';
                    newEvent.detail.status = 'success';
    
                    this.handleSaveVisitData(newEvent,itemId,operation);
                },
                (err) => {
                    isResolved = true;
                    this.isDisabled = false;
                    clearTimeout(timeoutTimer);
                    console.error('Browser location error:', err);
                    this.isLoading = false;
                    this.genericDispatchToastEvent('Error', 'Please enable location permission to start your visit', 'error');
                },
                { enableHighAccuracy: true }
            );
    
        } else {
            isResolved = true;
            clearTimeout(timeoutTimer);
            console.log('Location not supported');
            this.isDisabled = false;
            this.isLoading = false;
            this.genericDispatchToastEvent('Error', 'Location not supported on this device.', 'error');
        }
    }
    handleSaveVisitData(event,itemId,operation){
        let details = JSON.parse(JSON.stringify(event.detail));
        if (operation == 'Complete Visit') {

            const now = new Date();
            let data = {
                sObjectType: 'Visit__c',
                Id: itemId,
                Comments__c: this.comment,
                Clockout_Longitude__c: details.lon,
                Clockout_Latitude__c: details.lat,
                Actual_End_Time__c: now.toISOString(),
                Status__c: 'Completed'
            };
            this.isLoading = true;
            COMPLETE_Visit({visitData: data,beatId:this.currentVisitBeatId })
            .then(result => {
                this.genericDispatchToastEvent('Success','Visit Completed successfully', 'Success');
                this.isLoading = false;
                this.isProgressVisit = true;
                this.isPageLoaded = false;
                this.completeVisit = false;
                this.Reshedule = false;
                this.openVisit = false;
                this.isDesktopCheckoutPage = true;
                this.getTheDateBackend();  
            })
            .catch(error => {
                console.error(error);
                this.genericDispatchToastEvent('Error', 'Failed to complete visit', 'error');
            });
        }        
        else if(operation == 'Start Visit')
        {
             // If checkInAnyway is already true, skip validation
            if (this.checkInAnyway) {
                this.isOutletScreen = false;
                this.isShowStartVisit = false;
                this.isLoading = false;
                this.confirmationMessage.latitude = details.lat;
                this.confirmationMessage.longitude = details.lon;
                this.confirmationMessage.locationType = 'Out Location';
                this.genericDispatchEvent(this.confirmationMessage);
                return;
            }

            this.isLoading = true;
            let visitData = this.confirmationMessage;
            VALIDATE_GEO_FENCING({
                accountId:visitData.accId,
                visitLat : details.lat,
                visitLon : details.lon
            })
            .then(result => {
                if(result)
                {
                    this.isOutletScreen = false;
                    this.isShowStartVisit = false;
                    this.isLoading = false;
                    this.confirmationMessage.locationType = 'In Location';
                    this.genericDispatchEvent(this.confirmationMessage); 
                 
                }
                else
                {
                    this.isLoading = false;
                    this.checkInAnyway = true; 
                    this.genericDispatchToastEvent('Error', 'Your current location is far from the customer location', 'error');
                }
                
            })
            .catch(error => {
                console.error(error);
                this.isLoading = false;
            });
        }
      
    }
    createNewRecord(recordInput,msg){
        if (!navigator.onLine) {
            this.genericDispatchToastEvent('Error', 'No internet connection. Please check your network and try again.', 'error');
            return;
        }
        createRecord(recordInput)
        .then((result) => {
            this.genericDispatchToastEvent('Success',msg,'success');
            this.isProgressVisit = true;
            this.isPageLoaded = false;
            this.completeVisit = false;
            this.Reshedule = false;
            this.openVisit = false;
            this.isDesktopCheckoutPage = true;
            this.getTheDateBackend();                  
        })
        .catch((error) => {
            // Handle error in record creation
            this.isDailyLog = false;
            this.isPageLoaded = false;
            console.error('Error creating record:', error);
        });
    }
    genericDispatchEvent(message) {
        // Creating a custom event with a payload (optional)
        const event = new CustomEvent('mycustomevent', {
            detail: message
        });

        // Dispatching the event
        this.dispatchEvent(event);
    }
    openMenu(event) {
       // const itemId = event.currentTarget.dataset.id;
        const index1 = parseInt(event.currentTarget.dataset.index, 10); 
        this.VisitData = this.VisitData.map((item, i) => {
            return {
                ...item,
                openPopup: i === index1 ? !item.openPopup : false
            };
        });
    }



    /**Helper Methods */
    sortingVisit() {
        if (this.sortingTitle === 'Ascending') {
            this.sortingTitle = 'Descending';
            this.VisitData = [...this.VisitData].sort((a, b) => 
                a.accountName > b.accountName ? -1 : 1
            ); // Sorting in Descending Order
        } else {
            this.sortingTitle = 'Ascending';
            this.VisitData = [...this.VisitData].sort((a, b) => 
                a.accountName > b.accountName ? 1 : -1
            ); // Sorting in Ascending Order
        }
    }
    async handleConfirmClick(msg,variant,label,message,theme) {
        const result = await LightningConfirm.open({
            message:msg,
            variant: variant,
            theme:theme,
            label: label
        });
    
        if (result) {
            this.genericDispatchEvent(message); 
             this.isOutletScreen = false;
        } else { 
            return result ; 
        } 
    }
    handleBlur(event){
        //const index = parseInt(event.currentTarget.dataset.index, 10);
        setTimeout(() => {
            this.closeAllMenus();
        },1000);
    }
    closeAllMenus() {
        this.VisitData = this.VisitData.map(item => {
            //item.showMenu = false;
            return item;
        });
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
    formatDate(date) {
        const year = date.getFullYear();
        const month = (date.getMonth() + 1).toString().padStart(2, '0'); // Month starts from 0
        const day = date.getDate().toString().padStart(2, '0');
        return `${year}-${month}-${day}`;
    }
 
}