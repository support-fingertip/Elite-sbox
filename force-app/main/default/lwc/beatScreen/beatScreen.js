import { LightningElement,track,api} from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import GOOGLE_ICONS from '@salesforce/resourceUrl/googleIcons';
import { NavigationMixin } from 'lightning/navigation';
import FORM_FACTOR from '@salesforce/client/formFactor';
import Id from '@salesforce/user/Id';
import GET_APEX_DATA from '@salesforce/apex/beatPlannerlwc.getBeatData';
import UPDATE_CURRENTBEAT_SWITCH_HISTORY from '@salesforce/apex/beatPlannerlwc.updateCurrentBeatAndSwitchHistory';
import GET_PREVIEW_BEAT from '@salesforce/apex/beatPlannerlwc.getPreviewBeatCustomers';
import getTodayVisitForms from '@salesforce/apex/VisitFormController.getTodayVisitForms';


export default class BeatScreen extends NavigationMixin(LightningElement) {
    userId = Id;
    @api activeTab;
    googleIcons = {
        beat : GOOGLE_ICONS + "/googleIcons/bike.png",
        forward : GOOGLE_ICONS + "/googleIcons/forward.png",
        switch: GOOGLE_ICONS + "/googleIcons/swap.png",
        play: GOOGLE_ICONS + "/googleIcons/play.png",
        account : GOOGLE_ICONS + "/googleIcons/apartment.png",
    }
    @track visitForms = [];
    @track allVisitForms = [];
    @track visitSearchTerm = '';

    isPageLoaded = false;
    searchedbeatVale = '';
    isDesktop = false;
    isPhone = false;
    @track beatData = [];
    @track originalBeatData = [];
    isDayStarted;
    isLeaveExisted = false;

    //Switch Beat Fields
    loadingScreenSize = 1;
    isLoading = false;
    isDisabled = false;
    isShowSwitchBeat = false;
    containerClass;
    beatSwitchReason = '';
    currentBeat = {};
    confirmationMessage = {};
    isShowConfirmation = false;
    isCurrentBeatExisted = false;
    isShowPreview = false;
    previewBeatList = [];
    previewClass = 'slds-col slds-size_1-of-2';
    isShowBeatData = true;
    isTodayBeatExisted = false;
 
  
    showReporteeView = false;
    @track selectedVisitFormId = null;

    handleVisitFormSelect(event) {
        this.selectedVisitFormId = event.detail.id;
    }
    // Getters for tab active state
    get myBeatsTabActive()   { return this.activeTab === 'myBeats'; }
    get visitFormTabActive() { return this.activeTab === 'visitForm'; }
    get reportTabActive()    { return this.activeTab === 'report'; }

    // Getters for tab CSS classes
    get myBeatsTabClass()   { return this.activeTab === 'myBeats'   ? 'tab-item tab-item-active' : 'tab-item'; }
    get visitFormTabClass() { return this.activeTab === 'visitForm' ? 'tab-item tab-item-active' : 'tab-item'; }
    get reportTabClass()    { return this.activeTab === 'report'    ? 'tab-item tab-item-active' : 'tab-item'; }



    connectedCallback(){
        this.isDesktop = FORM_FACTOR === 'Large'? true : false;
        this.isPhone = FORM_FACTOR === 'Small'? true : false;
        if (FORM_FACTOR === 'Medium') this.isDesktop = true;
        this.loadingScreenSize = this.isDesktop ? 1 : 3;
        this.containerClass = this.isDesktop ? 'slds-modal__container ' : '';
        this.previewClass = this.isDesktop ? 'slds-col slds-size_1-of-2' : 'slds-col slds-size_1-of-1';
       
        if(this.activeTab == 'visitForm')
        {
            this.fetchVisitForms();
            this.selectedVisitFormId = null;
        }
        else if(this.activeTab == 'myBeats')
        {
            this.getBeatData();
        }
    }
    @api handleDailyLogChange(){
        this.getBeatData();
    }
    getBeatData() {
        if (!navigator.onLine) {
            this.genericDispatchToastEvent('Error', 'No internet connection. Please check your network and try again.', 'error');
            return;
        }
        this.isPageLoaded = true;
        GET_APEX_DATA({})
        .then(result => {
            console.log('result.beatDataList'+JSON.stringify(result.beatDataList));
            this.beatData = result.beatDataList.map((item, index) => {
                return {
                    ...item,
                    uiKey: item.beatId + '-' + index  // unique key for UI
                };
            });

            this.sortBeatData();
            this.isDayStarted = result.isDayStarted;
            this.isLeaveExisted =  result.isLeaveExisted;
            // Set currentBeat using isCurrentBeat or fallback to istodayBeat
            this.currentBeat = this.beatData.find(b => b.isCurrentBeat) || this.beatData.find(b => b.istodayBeat) || {};
            this.originalBeatData = this.beatData;
            this.isCurrentBeatExisted = result.currentBeatExisted;
            this.isTodayBeatExisted = this.beatData.some(b => b.istodayBeat);
            this.isPageLoaded = false;
        })
        .catch(error => {
            this.isPageLoaded = false;
            console.error(error);
        });
    }
        // Tab switch handler
    handleTabSwitch(event) {
        this.activeTab = event.currentTarget.dataset.tab;
        if (this.activeTab === 'visitForm') {
            this.fetchVisitForms();
            this.selectedVisitFormId = null;
        }
        else if(this.activeTab === 'myBeats')
        {
            this.getBeatData();
        }
    }
    openMenu(event) {
        const index1 = parseInt(event.currentTarget.dataset.index, 10); 
        this.beatData = this.beatData.map((item, i) => {
            return {
                ...item,
                openPopup: i === index1 ? !item.openPopup : false
            };
        });
    }
    handleOnclickMenu(event) {
        if (!navigator.onLine) {
            this.genericDispatchToastEvent('Error', 'No internet connection. Please check your network and try again.', 'error');
            return;
        }
        const itemId = event.currentTarget.dataset.id;
        const itemName = event.currentTarget.dataset.name;
        const beatname = event.currentTarget.dataset.beatname;
        const pjpId =  event.currentTarget.dataset.pjpid;
        if(itemName == 'Start_Beat')
        {
            const  message = { 
                message: 'Start_Beat',
                beatId : itemId,
                beatName:beatname,
                pjpId:pjpId
            };
            this.confirmationMessage = message;
            this.isShowConfirmation = true;
            if(!this.isDesktop)
            {
                this.isShowBeatData = false;
            }
        }
        else if(itemName == 'Execute_Beat')
        {
            const  message = { 
                message: 'Execute_Beat',
                beatId : itemId,
                beatName:beatname,
                pjpId:pjpId
            };
            this.isPageLoaded = true;
            this.genericDispatchEvent(message);
        }
        else if(itemName == 'Switch_Beat'){
            const  message = { 
                message: 'Switch_Beat',
                beatId : itemId,
                beatName:beatname,
                pjpId:pjpId
            };
            this.confirmationMessage = message;
         
           this.isShowSwitchBeat = true;
        }
        else if(itemName == 'Preview'){
            this.openBeatPreview(itemId);
        }
    }
    //beat Switch Popup
    handleInputChange(event)
    {
      this.beatSwitchReason = event.target.value;
    }

    /**Switch Beat**/
    closePopup()
    {
        if(!this.isDesktop)
        {
            this.isShowBeatData = true;
        }
        this.beatSwitchReason = '';
        this.isShowSwitchBeat = false;
        this.isLoading = false;
        this.isDisabled = false;
    }
    switchBeat()
    {
        if (!navigator.onLine){
            this.genericDispatchToastEvent('Error', 'No internet connection. Please check your network and try again.', 'error');
            return;
        }
        if(!this.isDesktop)
        {
            this.isShowBeatData = false;
        }
        if(!this.beatSwitchReason || this.beatSwitchReason.trim() == '')
        {
            this.genericDispatchToastEvent('Error', 'Please enter reason for switching beat.', 'error');
            return;
        }
        let currentBeatName = this.currentBeat.beatName;
        let switchBeatName = this.confirmationMessage.beatName;
        let currentbeatId =  this.confirmationMessage.beatId;
        let currentPJPId = this.confirmationMessage.pjpId;
        let reason = this.beatSwitchReason;
        let message = 'Beat swithced successfully';
        this.isLoading = true;
        this.isDisabled = true;
        this.updateBeat(currentbeatId,message,currentBeatName,switchBeatName,reason,currentPJPId);
    }

    /**Confirmation Popup */
    handleConfirmationYes() {
        if (!navigator.onLine){
            this.genericDispatchToastEvent('Error', 'No internet connection. Please check your network and try again.', 'error');
            return;
        }
       
        this.isShowConfirmation = false;
        if(!this.isDesktop)
        {
            this.isShowBeatData = true;
        }
        let currentbeatId =  this.confirmationMessage.beatId;
        let currentPJPId = this.confirmationMessage.pjpId;
        let message = 'Beat started successfully';
        this.isPageLoaded = true;
        this.updateBeat(currentbeatId,message,'','','',currentPJPId);
    }
    handleConfirmationNo() {
        this.isShowConfirmation = false;
        if(!this.isDesktop)
        {
            this.isShowBeatData = true;
        }
    }

    /**Update Beat**/
    updateBeat(beatId,message,currentBeatName,switchBeatName,reason,currentPJPId)
    {
        if (!navigator.onLine){
            this.genericDispatchToastEvent('Error', 'No internet connection. Please check your network and try again.', 'error');
            return;
        }

        UPDATE_CURRENTBEAT_SWITCH_HISTORY({beatId:beatId,currentBeatName:currentBeatName,switchBeatName:switchBeatName,reason:reason,currentPJPId:currentPJPId})
        .then(result => {
            this.isLoading = false;
            this.isDisabled = false;
            this.isPageLoaded = false;
            this.isShowConfirmation = false;
            this.isShowSwitchBeat = false;
            this.genericDispatchToastEvent('Success ',message,'Success '); 
            this.genericDispatchEvent(this.confirmationMessage);
        })
        .catch(error => {
            this.isLoading = false;
            console.error(error);
        });
    }

    
    /**Search Beat */
    searchBeats(event) {
        const value = event.target.value || '';
        const searchTerm = value.toLowerCase().trim();
        this.searchedbeatVale = value;

        let filteredList = [];

        if (!searchTerm) {
            filteredList = [...this.originalBeatData];
        } else {
            filteredList = this.originalBeatData.filter(bt =>
                bt &&
                bt.beatId &&
                bt.beatName &&
                bt.beatName.toLowerCase().includes(searchTerm)
            );
        }

        //  Assign filtered list
        this.beatData = [...filteredList];

        // Sort directly here
        this.beatData = [...this.beatData].sort((a, b) => {

            // Priority 1: isCurrentBeat
            if (a.isCurrentBeat && !b.isCurrentBeat) return -1;
            if (!a.isCurrentBeat && b.isCurrentBeat) return 1;

            // Priority 2: istodayBeat
            if (a.istodayBeat && !b.istodayBeat) return -1;
            if (!a.istodayBeat && b.istodayBeat) return 1;

            // Priority 3: Sort by pjpDate (dd/MM/yyyy)
            const parseDate = (str) => {
                if (!str) return new Date(0);
                const parts = str.split('/');
                if (parts.length !== 3) return new Date(0);

                const day = Number(parts[0]);
                const month = Number(parts[1]) - 1;
                const year = Number(parts[2]);

                return new Date(year, month, day);
            };

            const dateA = parseDate(a.pjpDate);
            const dateB = parseDate(b.pjpDate);

            return dateA - dateB;
        });

        console.log(
            this.beatData.map(b => b.beatId)
        );
    }

    get hasBeatData() {
        return this.beatData && this.beatData.length > 0;
    }


    closePreview()
    {
        this.isShowPreview = false;
        if(!this.isDesktop)
        {
            this.isShowBeatData = true;
        }
    }
    openBeatPreview(beatId)
    {
        if (!navigator.onLine){
            this.genericDispatchToastEvent('Error', 'No internet connection. Please check your network and try again.', 'error');
            return;
        }
        if(!this.isDesktop)
        {
            this.isShowBeatData = false;
        }
        this.isShowPreview = true;
        this.isLoading = true;
        GET_PREVIEW_BEAT({beatId :beatId})
        .then(result => {
            console.log(JSON.stringify(result));
            this.previewBeatList = result;
            this.isLoading = false;
        })
        .catch(error => {
            this.isLoading = false;
            console.error(error);
        });

    }

    fetchVisitForms() {
        this.isPageLoaded = true;
        getTodayVisitForms({ searchTerm: this.visitSearchTerm })
            .then(result => {
                this.allVisitForms = result.map(vf => ({
                    Id: vf.Id,
                    AccountName: vf.Customer_Name__c ? vf.Customer_Name__c : '',
                    CustomerType: vf.Customer_Type__c ? vf.Customer_Type__c : '',
                    VisitType: vf.Visit_Type__c,
                    Status: 'Completed',
                    CreatedTime: vf.CreatedDate 
                        ? new Date(vf.CreatedDate).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }) 
                        : ''
                }));
                this.isPageLoaded = false;
                this.visitForms = [...this.allVisitForms];
            })
            .catch(error => {
                this.visitForms = [];
                this.allVisitForms = [];
            });
    }

    handleSearch(event) {
        this.searchTerm = event.target.value;
        const term = this.searchTerm ? this.searchTerm.toLowerCase() : '';
        if(term) {
            this.visitForms = this.allVisitForms.filter(form =>
                (form.AccountName && form.AccountName.toLowerCase().includes(term)) ||
                (form.VisitType && form.VisitType.toLowerCase().includes(term))
            );
        } else {
            this.visitForms = [...this.allVisitForms];
        }
    }


    handleOutsideVisitClick(event) {
        const visitformId = event.currentTarget.dataset.id;
        console.log('visitformId'+visitformId);
        const message = {
            message: 'visitformDetail',
            visitformid: visitformId
        };
        this.genericDispatchEvent(message);
    }
    

    /**Helper Methods */
    genericDispatchEvent(message) {
        // Creating a custom event with a payload (optional)
        const event = new CustomEvent('processbeatevent', {
            detail: message
        });

        // Dispatching the event
        this.dispatchEvent(event);
    }
    sortBeatData() {
        this.beatData = [...this.beatData].sort((a, b) => {
            // Priority 1: isCurrentBeat
            if (a.isCurrentBeat && !b.isCurrentBeat) return -1;
            if (!a.isCurrentBeat && b.isCurrentBeat) return 1;

            // Priority 2: istodayBeat
            if (a.istodayBeat && !b.istodayBeat) return -1;
            if (!a.istodayBeat && b.istodayBeat) return 1;

            // Priority 3: Sort by pjpDate (dd/MM/yyyy format)
            const parseDate = (str) => {
                if (!str) return new Date(0); // fallback for missing date
                const [day, month, year] = str.split('/').map(Number);
                return new Date(year, month - 1, day); // JS month is 0-based
            };

            const dateA = parseDate(a.pjpDate);
            const dateB = parseDate(b.pjpDate);

            return dateA - dateB;
        });
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
    genericDispatchToastEvent(title,message,variant){
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant
            })
        );
    }

}