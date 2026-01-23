import { LightningElement,track ,api} from 'lwc';
import PLANNER_ICON from '@salesforce/resourceUrl/planner';
import getApexData from '@salesforce/apex/beatPlannerlwc.getData';
// import { getLocationService } from 'lightning/mobileCapabilities';
// import { updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import FORM_FACTOR from '@salesforce/client/formFactor';
import GOOGLE_ICONS from '@salesforce/resourceUrl/googleIcons';

 
export default class AllVisitType extends LightningElement {

    hrs = PLANNER_ICON + "/planner/screen-1-24.png";
    week = PLANNER_ICON + "/planner/screen-1-week.png";
    year = PLANNER_ICON + "/planner/screen-1-year.png"; 
    googleIcons = {
        account : GOOGLE_ICONS + "/googleIcons/apartment.png",
    };
    
    @track buttonSelectedIcon =this. hrs;
    @track buttonSelected = 'Week';
    @api isParentComp;
    @track isDropdownfilterOpen = false;
    isDesktop;
    fromDate = this.formatDate(new Date());
    toDate = this.formatDate(new Date());
    @track VisitData = [];
    isDesktopCheckoutPage = true;
    completeVisit = false;
    currentVisitId;
    selectedDropdownId = '';
    isOutletScreen = true; newVisit = false;
    selectedDropdownIndex = '';
    openVisit = false; Reshedule = false;
    isPageLoaded = false;
    StartCallHeader = 'Start Call';
    isProgressVisit;
    comment; 
    routeDropdown;
    
    //detect if LWC is running in mobile publisher
    isMobilePublisher = window.navigator.userAgent.indexOf('CommunityHybridContainer') > 0;

    @api screenHeight;

    @api handleUpdateChange(){
        //alert('here');
        if(this.buttonSelected == 'Day'){
            this.getTheDateBackend('BeatPlan','This_Day',null);
        }
    }

    connectedCallback(){
        this.isDesktop = FORM_FACTOR === 'Large'? true : false;
        this.isPhone = FORM_FACTOR === 'Small'? true : false;
        if(FORM_FACTOR === 'Medium')
            this.isDesktop = true;

        this.isPageLoaded = true;
        this.disablePullToRefresh();
        // this.isParentComp = this.isParentComp ? true : false;
        let startDate,endDate;
        this.buttonSelectedIcon = this.week;
        const today = new Date();
        const dayOfWeek = today.getDay();
        const diff = today.getDate() - dayOfWeek + (dayOfWeek === 0 ? -6 : 1);
        startDate = new Date(today.setDate(diff)); // Set start of week (Monday)
        endDate = new Date(today.setDate(startDate.getDate() + 6)); // End of week is 6 days later
        this.fromDate = this.formatDate(startDate);
        this.toDate = this.formatDate(endDate);
        this.getTheDateBackend('BeatPlan','This_Week',null);
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
    toggleFilterDropdown() {

        const dropdown = this.template.querySelector('.custom-dropdown-content');
        if (dropdown) {
            dropdown.style.display = dropdown.style.display === 'none' || dropdown.style.display === '' ? 'block' : 'none';
        }
    }
    
    formatDate(date) {
        const year = date.getFullYear();
        const month = (date.getMonth() + 1).toString().padStart(2, '0'); // Month starts from 0
        const day = date.getDate().toString().padStart(2, '0');
        return `${year}-${month}-${day}`;
    }
    selectItem(event){
        const button = event.currentTarget.dataset.id;
        let dateValue = '';
        let startDate,endDate;
        const today = new Date();
        if(button == 'hrs'){
            this.fromDate = this.formatDate(today);
            this.toDate = this.formatDate(today);
            this.buttonSelected = 'Day';
            this.buttonSelectedIcon = this.hrs;
            dateValue = 'This_Day';
        }
        else if(button == 'week'){
            this.buttonSelected = 'Week';
            this.buttonSelectedIcon = this.week;
            const dayOfWeek = today.getDay();
            const diff = today.getDate() - dayOfWeek + (dayOfWeek === 0 ? -6 : 1);
            startDate = new Date(today.setDate(diff)); // Set start of week (Monday)
            endDate = new Date(today.setDate(startDate.getDate() + 6)); // End of week is 6 days later
            this.fromDate = this.formatDate(startDate);
            this.toDate = this.formatDate(endDate);
            dateValue = 'This_Week';
        }
        else if(button == 'month'){
            this.buttonSelected = 'Month';
            this.buttonSelectedIcon = this.year;
            startDate = new Date(today.getFullYear(), today.getMonth(), 1); // First day of the current month
            endDate = new Date(today.getFullYear(), today.getMonth() + 1, 0); // Last day of the current month
            this.fromDate = this.formatDate(startDate);
            this.toDate = this.formatDate(endDate);
            dateValue = 'This_Month';
        }
        this.toggleFilterDropdown();
        this.getTheDateBackend('BeatPlan',dateValue,null);
    }

    dateChange(event){
        const selectedDate = event.target.value;
        const Name = event.target.name;
        if(Name == 'fromDate'){
            this.fromDate = selectedDate;
            this.toDate = selectedDate;
        }
        else if(Name == 'toDate'){
            //this.toDate = selectedDate;
        }
        if(this.toDate  && this.toDate ){
            this.buttonSelected = null;
           this.getTheDateBackend('BeatPlan',null,null);
        }
    }
    getTheDateBackend(obj,dateValue,selectedDate) {

        //this.isSpinner = true;
        getApexData({ 
            isoffSet: 0,
            isLimit: 0,
            objName : obj,
            fromDate : this.fromDate,
            toDate : this.toDate
        })
        .then(result => {
            this.routeDropdown = result.routeDropdown;
            this.forMoreThanOneDayData(result);
            
            const pop = this.template.querySelector(".popup");
            if(pop){
                pop.style.display =  "";
            }
            this.isPageLoaded = false;
        })
        .catch(error => {
            this.isPageLoaded = false;
            console.error(error);
            //this.isSpinner = false;
        });
    }

    forMoreThanOneDayData(result){
        let todayDay = new Date(); // Get the current date
        let day = String(todayDay.getDate()).padStart(2, '0'); // Get day and add leading zero if necessary
        let month = String(todayDay.getMonth() + 1).padStart(2, '0'); // Get month (January is 0!) and add leading zero
        let year = todayDay.getFullYear(); // Get the full year
        let formattedDate = `${day}/${month}/${year}`;
        const today = new Date().toISOString().split('T')[0]; // Get today's date in 'YYYY-MM-DD' format
        let groupedVisitData = {};
        result.visit.forEach(itm => {
            const visitDate = itm.VisitDate ? new Date(itm.VisitDate).toISOString().split('T')[0] : null;
            itm.showMenu = false;
            //itm.isMoreLoad = true;
            //itm.isShowAllData = itm.formattedVisitDate == formattedDate ? false : true;
            itm.execute = visitDate === today ? true : false;
                // Group the visit data by formattedVisitDate
            if (groupedVisitData[itm.formattedVisitDate]) {
                groupedVisitData[itm.formattedVisitDate].push(itm);
            } else {
                groupedVisitData[itm.formattedVisitDate] = [itm];
            }
        });
        this.VisitData = Object.keys(groupedVisitData).map(key => {
            const visits = groupedVisitData[key];
            return {
                date: key,
                isMoreLoad: visits.length > 3 ,
                isShowAllData: visits.length > 3,
                visits: visits.slice(0, 3), // Initially only show up to 3 visits
                allVisits: visits,          // Store all visits for that date
                showMore: visits.length > 3 // Only show the "more" option if there are more than 3 visits
            };
        });
    }
    closeAllMenus() {
        this.VisitData = this.VisitData.map(item => {
            //item.showMenu = false;
            return item;
        });
    }


    handleBlur(event){
        //const index = parseInt(event.currentTarget.dataset.index, 10);
        setTimeout(() => {
            this.closeAllMenus();
        },1000);
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
    
    genericDispatchEvent(message) {
        // Creating a custom event with a payload (optional)
        const event = new CustomEvent('mycustomevent', {
            detail: message
        });

        // Dispatching the event
        this.dispatchEvent(event);
    }
    handleRouteChange(event) {
        const routId = event.target.value;
        const routName = event.target.name;
        console.log(routId + " "+routName);
    }
    showLessMoreVisit(event){
        const index = parseInt(event.currentTarget.dataset.index, 10);
        //this.VisitData[index].isMoreLoad = !this.VisitData[index].isMoreLoad;
        this.VisitData[index].isMoreLoad =  !this.VisitData[index].isMoreLoad ;
        const isMoreLoad = this.VisitData[index].isMoreLoad; 
        this.VisitData[index].visits = isMoreLoad 
        ? this.VisitData[index].allVisits.slice(0, 3) // If "Less", show only 3 visits
        : this.VisitData[index].allVisits;   
        
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