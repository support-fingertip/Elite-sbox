import { LightningElement, track, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import FORM_FACTOR from '@salesforce/client/formFactor';
import ChartJs from '@salesforce/resourceUrl/ChartJS';
import { loadScript, loadStyle } from 'lightning/platformResourceLoader';
import { NavigationMixin } from 'lightning/navigation';
import { updateRecord, deleteRecord, createRecord } from 'lightning/uiRecordApi';

// import LEAFLET_CSS from "@salesforce/resourceUrl/leafletCss";
// import LEAFLET_JS from "@salesforce/resourceUrl/leafletJs";
// import LGMAP_JS from "@salesforce/resourceUrl/gmap";
import GOOGLE_CHARTS from "@salesforce/resourceUrl/GoogleCharts";


// import JUN_BEAT_OBJECT from '@salesforce/schema/Junction_Beat__c';
import CH_BEAT_OBJECT from '@salesforce/schema/Child_beat__c';
import CALENDER_OBJECT from '@salesforce/schema/Calendar_beat__c';

import USERS_DATA from '@salesforce/apex/userProfileLWC.getUserData';
import GRAPH_DATA_USER from '@salesforce/apex/userProfileLWC.graphDataDetails';
import BEAT_DATA from '@salesforce/apex/userProfileLWC.beatPlan';
import PJP_CREATE from '@salesforce/apex/userProfileLWC.createPJP';
import ROTATEBEATS from '@salesforce/apex/userProfileLWC.RotateBeats';
import savePjpItems from '@salesforce/apex/userProfileLWC.savePjpItems';
import VISIT_DATA from '@salesforce/apex/userProfileLWC.visitData';
import HOLIDAY_DATA from '@salesforce/apex/userProfileLWC.getHoliday';
import ORD_DATA from '@salesforce/apex/userProfileLWC.allOrderData';
import INV_DATA from '@salesforce/apex/userProfileLWC.allInvoiceData';
import EXP_DATA from '@salesforce/apex/userProfileLWC.allExpData';
import USER_DATA from '@salesforce/apex/userProfileLWC.getAllUserDatas';
import ATT_DATA from '@salesforce/apex/userProfileLWC.attendance';
import REPEAT_DAYS from '@salesforce/apex/userProfileLWC.repeatDays';
import INC_DATA from '@salesforce/apex/userProfileLWC.Incentive';
import submitApprovalProcess from '@salesforce/apex/userProfileLWC.submitApprovalProcess';
import deletePJPItem from '@salesforce/apex/userProfileLWC.deletePJPItem'; // Import the Apex method
import getVisits from '@salesforce/apex/mapController.getVisits';
import shareAccounts from '@salesforce/apex/userProfileLWC.shareAccountAccess';
import VISIT_SUMMARY from '@salesforce/apex/userProfileLWC.getBeatVisitSummaries';

export default class UserProfileLWC extends NavigationMixin(LightningElement) {
    @api recordId;
     @track fromDate;
    @track toDate;
    @track mapMarkers = [];
    isPageLoaded = false; isDesktop = false; isPhone = false;
    isSubPartLoad = false; isNewBeatCreate = true; isHoliday = false; isHolidayPopup = false; isCloneBeat = false; showSubmitBtn = false;
    showDataUpload = false; showCustomers = false;
    usersOptions = []; indexVal = 0;
    selectedName = ''; isAdmin = false; isDSM = false; isPJPSubmitted = false; isActiveUserDSM = false; isActiveUserNotDSM = false; newBeatBtn = true;
    selectedUserActive = true;
    salesChart; orderChart; expenseChart;
    nameSelected = {
        user: '',
        id: ''
    };
    userName;
    userUrl;
    chartInitialized = false;
    isTouching = false;
    isLongPressActive = false;
    longPressTimer;
    draggedElement = null;
    initialTouchX = 0;
    initialTouchY = 0;
    dropTargets = [];
    longPressFrame = null;
    draggedElementRect = null;

    selectedUser = {};

    usersDetail;
    LoggedInUserData;
    targetLineChart; selectedId; beatPlan = []; VisitData = []; masterBeatPlan = []; newPJPRecord = {};
    @track filteredBeatOptions = [];
    @track filterBeatData = {
        beatSearchKeyword: '',
        beatVal: ''
    };
    @track showDropdown = false;
    junctionBeats = []; beatCalenderPlan = [];
    originalcalendarDaysData = [];
    today = new Date();
    hoveredStoreId;
    currentTouchY;
    selectedTab = 'Details';
    map;
    calenderBeat;
    isAddVisit = false;
    isCalenderShow = false; isBeatPlanView = false; isButtonFunctions = true; todaydate; showPJPForm = false;
    chartData;
    vfWindow = null;
    vfPageUrl = "/apex/GoogleChart";
    isVfPage = true;
    isexpData = true; isAttanData = true;
    ind = 0; dayIndex = null;
    regions = [];

    @track isModalOpen = false;
    @track startDate = '';
    @track selectedBeatId = '';
    autoCreatePJP = false;
    modalBody = {};

    @track InceFilter = {
        fromDate: '',
        toDate: '',
        statusVal: [],
        allInvData: [],
        originalInvData: []
    };
    @track visFilter = {
        fromDate: '',
        srchVal: '',
        toDate: '',
        status: 'All',
        statusVal: [],
        allordData: [],
        originalVisData: [],
        duration: '',
        durationVal: []
    };
    @track attFilter = {
        fromDate: '',
        srchVal: '',
        toDate: '',
        status: 'All',
        statusVal: [],
        allAttData: [],
        originalAttData: []
    };
    @track ordFilter = {
        fromDate: '',
        srchVal: '',
        toDate: '',
        status: 'All',
        statusVal: [],
        allordData: [],
        originalOrdData: [],
        totalOrderAmount : 0,
        primaryOrderAmount : 0,
        secondaryOrderAmount : 0,
        totalNoOfOrders : 0
    };
    @track InvFilter = {
        fromDate: '',
        srchVal: '',
        toDate: '',
        status: 'All',
        statusVal: [],
        allInvData: [],
        originalInvData: [],
        totalAmount : 0,
        totalNoOfInvoices : 0
    };
    @track visitSummary = {
        fromDate: '',
        toDate: '',
        BeatSummary :[],
        DailyOutletSummary :[],
        OutletEntryWorked: [],
        OutletEntryNotWorked: [],
        showBeatSummary:false,
        showDailyOutletSummary:false,
        showOutletEntry:false,
        outletCount:0
    };
    @track expFilter = {
        fromDate: '',
        srchVal: '',
        toDate: '',
        status: 'All',
        statusVal: [],
        allExpData: [],
        originalExpData: []
    };

    @track calendarDays = [];
    @track calendarMonths = [];
    @track currentMonthIndex = 0;
    @track currentMonth; draggedStore = null; draggedBeat = null; holidayData = [];
    @track currentYear;
    @track showTooltip = false;
    @track tooltipData = { name: '' };
    @track tooltipStyle = '';
    @track isListView = true;
    @track HolidayList = [];
    @track getAllUserDatas;
    @track beats = [];
    @track filteredBeats = [];
    @track draggedAccountId = null;
    @track PJPStartDate; @track PJPNextStartDate;
    @track isListViewShow = true; isVisitData = true; isOrderData = true; isInvData = true; isIncenTtData = true;

    //Customer Assignment
    showHeader = true;
    customClass = 'custom1';
    customScrren = 'screen-1';
    employeeId;
    objectName = 'Employee';
    dataUploadObjectName = '';
    userSearchText ='';
    userList =[];
    searchedUserList =[];
    showUsers = false;
    isReadOnly = false;
    isSharing = false;
    ordercustomclass = 'slds-col slds-size_1-of-1 slds-medium-size_1-of-2 slds-text-align_right';


    connectedCallback() {
        this.isPageLoaded = true;
        this.isSubPartLoad = true;
        this.isDesktop = FORM_FACTOR === 'Large' ? true : false;
        this.isPhone = FORM_FACTOR === 'Small' ? true : false;
        if (FORM_FACTOR === 'Medium')
            this.isDesktop = true;
        this.showHeader = this.recordId ? false : true;
        this.customClass = this.recordId ? 'custom2' : 'custom1';
        this.customScrren = this.recordId ? 'screen-2' : 'screen-1';
        this.ordercustomclass = this.isDesktop ? 'slds-col slds-size_1-of-1 slds-medium-size_1-of-2 slds-text-align_right' : 'slds-col slds-size_1-of-1 slds-medium-size_1-of-2';

        this.disablePullToRefresh();
        this.getUsersData();
        // this.generateCalendar();
        // this.loadGoogleCharts();
    }

    getUsersData() {
        USERS_DATA({ empId: this.recordId })
            .then(result => {
                this.usersOptions = result.formattedUsersData;
                this.LoggedInUser = result.LoggedInUser;
                this.isActiveUserDSM = result.LoggedInUser.Profile.Name === 'DSM' || result.LoggedInUser.Profile.Name === 'SSA';
                this.isActiveUserNotDSM = !this.isActiveUserDSM;
                this.isAdmin = this.LoggedInUser.Profile.Name === 'System Administrator';
                this.userList = result.users;

                this.regions = result.regionPickList;
                this.loadGoogleChartLoad(result, false);
                console.log('result:' + JSON.stringify(result));
                if (this.recordId) {
                    this.employeeId = this.recordId;
                    this.objectName = 'Employee';
                    if (result.employeeRecord.User__c) {
                        this.nameSelected = {
                            user: result.SelectedUser.Name,
                            id: result.SelectedUser.Id,
                        };
                        this.selectedName = result.SelectedUser.Id;
                        this.userSearchText = result.SelectedUser.Name;
                        
                        this.selectedId = result.SelectedUser.Id;
                        if (result.SelectedUser.IsActive == false || !result.SelectedUser) {
                            this.selectedUserActive = result.SelectedUser.IsActive;
                            this.isButtonFunctions = false;
                        }
                        this.isDSM = result.SelectedUser.Profile.Name === 'DSM' || result.SelectedUser.Profile.Name === 'SSA';
                        this.selectedUser = result.SelectedUser;
                    }
                    else {
                        this.selectedUserActive = false;
                        this.isButtonFunctions = false;
                    }
                }
                else {
                    this.nameSelected = {
                        user: result.LoggedInUser.Name,
                        id: result.LoggedInUser.Id,
                    };
                    this.selectedName = result.LoggedInUser.Id;
                    this.userSearchText = result.LoggedInUser.Name;
                    this.selectedId = result.LoggedInUser.Id;
                    this.isDSM = this.LoggedInUser.Profile.Name === 'DSM' || this.LoggedInUser.Profile.Name === 'SSA';
                    this.employeeId = this.selectedId;
                    this.objectName = 'User';
                }
                this.newBeatBtn = this.isAdmin /* || this.LoggedInUser.Id != this.selectedId */;
                this.isReadOnly = true;
                //this.getUserDetails();
                this.isPageLoaded = false;
                this.isSubPartLoad = false;
            })
            .catch(error => {
                console.error(error);
                this.isPageLoaded = false;
                this.isSubPartLoad = false;
            });
    }

    getBeatPlanData(beatTab) {

        this.isSubPartLoad = true;
        BEAT_DATA({
            ids: this.selectedId,
            beatTab: beatTab
        })
            .then(result => {
                this.beatPlan = result.jDbeatList;
                this.junctionBeats = result.JunctionList;
                this.HolidayList = result.HolidayList;
                this.calenderBeat = result.calenderBeat;
                this.beatPlan.sort((a, b) => a.orderNumber - b.orderNumber);
                console.log('beatPlanssss:' + JSON.stringify(this.beatPlan))

                // alert(JSON.stringify(this.calenderBeat))

                /* if (result.calenderBeat != null && result.calenderBeat.Start_Month__c != null)
                     this.PJPStartDate = result.calenderBeat.Start_Month__c;
 
                 if (result.calenderBeat != null && result.calenderBeat.Next_Start_Date__c != null)
                     this.PJPNextStartDate = result.calenderBeat.Next_Start_Date__c;*/

                if (beatTab == 'pjp') {
                    // this.beats= result.beatVisitList;   
                    this.isBeatPlanView = true;
                    this.isCalenderShow = false;

                    this.masterBeatPlan = [...this.beatPlan];
                    this.filteredBeats = [...this.beatPlan];

                    console.log('masterBeatPlan1: ==== ' + JSON.stringify(this.masterBeatPlan));
                    this.isSubPartLoad = false;

                    // this.beatPlan = result.jDbeatList;
                    // this.junctionBeats = result.JunctionList;
                    // this.HolidayList = result.HolidayList;
                }
                else if (beatTab == 'CalendarView') {
                    this.isBeatPlanView = false;
                    this.mapBeatPlansToCalendar();
                    // this.beatCalenderPlan = result.junctionBeat;
                    // if(this.beatCalenderPlan && this.beatCalenderPlan.length != 0){
                    //     this.mapBeatPlansToCalendar(this.beatCalenderPlan);
                    // }else{
                    //     this.calendarDays = this.originalcalendarDaysData;
                    // }
                    this.isCalenderShow = true;
                    console.log('masterBeatPlan2: ==== ' + JSON.stringify(this.masterBeatPlan));
                }
                //For visit created
                /*else if(beatTab == 'CalendarView'){
                    this.isBeatPlanView = false;
                    this.beatPlan = result.Visit;
                    if(this.beatPlan && this.beatPlan.length != 0){
                        this.mapBeatPlansToCalendar(this.beatPlan);
                    }else{
                        this.calendarDays = this.originalcalendarDaysData;
                    }
                    this.isCalenderShow= true;
                }*/

                this.isSubPartLoad = false;
            })
            .catch(error => {
                console.error(error);
                this.isPageLoaded = false;
                this.isSubPartLoad = false;
            });
    }

    generateCalendar() {

        //  const year = this.today.getFullYear();
        // const month = this.today.getMonth();
        // console.log('filteredBeats: ' + JSON.stringify(this.filteredBeats));
        let noofdays = 30;


        if (this.LoggedInUser.Profile.Name === 'DSM' || this.LoggedInUser.Profile.Name === 'SSA') {
            noofdays = 15;
        }

        const firstDateofMonth = new Date(this.today.getFullYear(), this.today.getMonth(), 1);
        const firstDay = new Date(this.today);

        const diffInMillis = firstDay - firstDateofMonth;
        const diffInDays = Math.floor(diffInMillis / (1000 * 60 * 60 * 24));


        const lastDay = new Date();
        lastDay.setDate(firstDay.getDate() + noofdays);

        const dayNames = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];
        const monthNames = [
            'January', 'February', 'March', 'April', 'May', 'June',
            'July', 'August', 'September', 'October', 'November', 'December'
        ];



        let currentDate = new Date(firstDateofMonth);
        let calendarMonths = {}; // Will hold data grouped by month-year
        this.PJPStartDate = currentDate;

        noofdays = noofdays + diffInDays;

        for (let i = 0; i < noofdays; i++) {
            const year = currentDate.getFullYear();
            const month = currentDate.getMonth();
            const dayName = dayNames[currentDate.getDay()];
            const monthKey = `${year}-${String(month + 1).padStart(2, '0')}`;
            const formattedDate = `${year}-${String(month + 1).padStart(2, '0')}-${String(currentDate.getDate()).padStart(2, '0')}`;
            // console.log('monthKey:' + monthKey);

            if (!calendarMonths[monthKey]) {
                calendarMonths[monthKey] = {
                    label: `${monthNames[month]} ${year}`,
                    days: []
                };
            }
            //  console.log('currentDate---' + currentDate)
            //console.log('currentDate.getDay()---' + currentDate.getDate())
            //console.log('currentDate == this.today---' + currentDate === firstDay)

            if ((currentDate.getDate() === firstDateofMonth.getDate() &&
                month === firstDateofMonth.getMonth() &&
                year === firstDateofMonth.getFullYear()) || currentDate.getDate() === 1) {
                const startDayOfWeek = currentDate.getDay();
                // console.log('startDayOfWeek:---' + startDayOfWeek)
                for (let i = 0; i < startDayOfWeek; i++) {

                    calendarMonths[monthKey].days.push({
                        date: null,
                        formattedDate: '',
                        records: []

                    });

                }
            }



            calendarMonths[monthKey].days.push({
                date: new Date(currentDate),
                formattedDate,
                records: [],
                dayNumber: currentDate.getDate(),
                dayName: dayName

            });



            currentDate.setDate(currentDate.getDate() + 1);
            this.PJPNextStartDate = currentDate;
        }

        this.calendarMonths = Object.entries(calendarMonths).map(([key, value]) => ({
            monthKey: key,
            ...value
        }));

        //  console.log('calendarMonths: ' + JSON.stringify(this.calendarMonths));
        this.currentMonthIndex = 0;

        /*  let noofdays = 30;
         console.log(this.LoggedInUser);
         if(this.LoggedInUser.Profile.Name === 'DSM'){
             noofdays = 15;
         }
 
         //const firstDay = new Date(year, month, 1);
         //const lastDay = new Date(year, month + 1, 0);
         const firstDay = this.today;
         const lastDay = new Date();
         lastDay.setDate(this.today.getDate() + noofdays);
        
         const dayNames = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];
         const startDayOfWeek = firstDay.getDay();
 
         let daysArray = [];
 
         // Fill empty slots for days before the first day of the month
         for (let i = 0; i < startDayOfWeek; i++) {
             daysArray.push({ date: null, formattedDate: '', records: [] });
         }
  
         // Fill in the actual days of the month
         for (let i = 1; i <= noofdays; i++) {
            
            let day = firstDay;
 
             let fullDate = new Date(day.getFullYear(), day.getMonth(), day.getDate());
             let formattedDate = `${day.getFullYear()}-${String(day.getMonth() + 1).padStart(2, '0')}-${String(day.getDate()).padStart(2, '0')}`;
             //let formattedDate = fullDate.toISOString().split('T')[0]; // Format: YYYY-MM-DD
             let dayName = dayNames[fullDate.getDay()];
             daysArray.push({
                 date: fullDate,
                 formattedDate,
                 records: [],
                 dayNumber: day.getDate(),
                 dayName: dayName
             });
              day.setDate(day.getDate() + 1);
         }
 
         this.calendarDays = daysArray;
         this.originalcalendarDaysData = daysArray;
         const today = new Date();
         const monthNames = [
             'January', 'February', 'March', 'April', 'May', 'June',
             'July', 'August', 'September', 'October', 'November', 'December'
         ];
 
         this.currentMonth = monthNames[today.getMonth()]; // Get month name
         this.currentYear = today.getFullYear(); */
    }


    mapBeatPlansToCalendar() {
        let beatIndex = 0; // Track current beatPlan index
        /* let startDt = this.calenderBeat.Start_Month__c
             ? new Date(this.calenderBeat.Start_Month__c).toISOString().split('T')[0]
             : null;
         let nxtStartDt = this.calenderBeat.Next_Start_Date__c
             ? new Date(this.calenderBeat.Next_Start_Date__c).toISOString().split('T')[0]
             : null;*/

        // this.calendarDays = this.calendarDays.map(dayObj => {
        let ind = this.ind;

        this.calendarMonths[this.currentMonthIndex].days = this.calendarMonths[this.currentMonthIndex].days.map(dayObj => {
            if (!dayObj.date) return dayObj;

            let formattedDate = dayObj.formattedDate;
            let currentDate = new Date(formattedDate);
            let dayOfWeek = currentDate.getDay(); // 0 = Sunday, 6 = Saturday

            let isToday = currentDate.getDate() === this.today.getDate() && currentDate.getMonth() === this.today.getMonth() && currentDate.getFullYear() === this.today.getFullYear();

            let classList = 'background-color:rgb(255, 255, 255) !important; background:rgb(255, 255, 255) !important';

            let matchingRecords = [];
            let isHoliday = false;
            let removePJPItembtn = true;

            // Always display holidays, even before startDt
            let matchingHoliday = this.HolidayList?.filter(holi => {
                let recDate = holi.beatDate ? new Date(holi.beatDate).toISOString().split('T')[0] : null;
                return recDate === formattedDate;
            }) || [];

            if (matchingHoliday.length > 0) {
                classList = 'background-color: #f7afac !important;color:#b20d0d';
                //  matchingRecords = matchingHoliday;
                matchingRecords = matchingHoliday.map(record => {
                    return {
                        ...record,
                        style: 'background-color: #b20d0d;'
                    };
                });
                isHoliday = true;
                removePJPItembtn = false;
            }

            if (dayOfWeek == 0) {
                classList = 'background-color: #f7caac !important;color:red';
            }

            if (isToday) {
                classList = 'background-color: #d0e4e7 !important;color:#9c776a';
            }

            // Skip weekends & holidays for beat plans, but still display holidays
            if (!isHoliday/*  && dayOfWeek !== 0 */) {
                console.log('plansssssss:   ' + JSON.stringify(this.beatPlan))
                let beatPlan = this.beatPlan?.filter(day => {
                    let recDate = day.beatDate ? new Date(day.beatDate).toISOString().split('T')[0] : null;
                    return recDate === formattedDate;
                }) || [];


                // Set currentDate and today to midnight (00:00:00) to ignore time
                let today = new Date(); // Today's date

                // Normalize both dates to midnight (00:00:00) to ignore time
                currentDate.setHours(0, 0, 0, 0);
                today.setHours(0, 0, 0, 0);

                // Compare only the date part (ignores the time)
                let isGreaterThanToday = currentDate > today;

                if (!isGreaterThanToday) {
                    removePJPItembtn = false;
                }


                if (beatPlan.length === 0 && isGreaterThanToday && this.isDSM && dayOfWeek !== 0) {
                    /*  console.log('ind:' + ind)
                      let defaultBeat = this.masterBeatPlan[ind]; // Select the first beat from the list as the default for the day
                      defaultBeat.style = 'background-color: #008a07;';
                      matchingRecords = [defaultBeat];
                      removePJPItembtn = false; // Show the remove button only if there are beat plans for the day
  
  
                      ind = (ind === this.masterBeatPlan.length - 1) ? 0 : ind + 1;*/
                    // this.ind = ind;
                } else if (beatPlan.length > 0) {

                    /*    matchingRecords = beatPlan.flatMap(record => {
                           // Create an array to hold the records for the current date
                           let recordsForDate = [];
   
                           // If the PJP item has "Not Approved" status, show 2 records (Assigned and Approved Beats)
                           if (record.ApprovalStatus !== 'Approved') {
                               console.log('recordddd:-----' + JSON.stringify(record))
                               // Add Assigned Beat with a specific color
                               if (record.assbeatId) {
                                   recordsForDate.push({
                                       ...record,
                                       beatName: record.assbeatName,
                                       beatId: record.assbeatId,
                                       style: 'background-color: #7f7d13;'
                                   });
                               }
   
                               // Add Approved Beat with a different color
                               if (record.beatId) {
                                   recordsForDate.push({
                                       ...record,
                                       beatName: record.beatName,
                                       beatId: record.beatId,
                                       style: 'background-color: #0070d2;',
                                   });
                               }
                           } else {
                               // If it's approved, just return the original record with the default color
                               recordsForDate.push({
                                   ...record,
                                   style: record.ApprovalStatus === 'Not Submitted'
                                       ? 'background-color: #7f7d13;'
                                       : record.ApprovalStatus === 'Submitted'
                                           ? 'background-color: #ab715c'
                                           : 'background-color: #0070d2;'
                               });
                           }
   
                           return recordsForDate; // Return the array of records for this date
                       }); */



                    //matchingRecords = beatPlan; // If there's a matching beat plan, assign it
                    matchingRecords = beatPlan.map(record => {
                        if (record.ApprovalStatus == 'Not Submitted') this.showSubmitBtn = true;
                        return {
                            ...record,
                            style: record.approvedBeat ? 'background-color:rgb(0, 138, 7);' : record.ApprovalStatus === 'Not Submitted' ? 'background-color:rgb(226, 136, 15);' : record.ApprovalStatus === 'Submitted' ? 'background-color:rgb(37, 88, 176)' : record.ApprovalStatus === 'Rejected' ? 'background-color:rgb(236, 24, 24);' : 'background-color: #0070d2;'
                        };
                    });


                    //

                }

                /*  while (beatIndex < this.beatPlan.length) {
                      let beatPlan = this.beatPlan[beatIndex];
                      console.log('beatPlan:' + JSON.stringify(beatPlan))
                      // Determine which start date to use for this beat plan
                      let effectiveStartDate = beatPlan.isRepeat ? this.PJPNextStartDate : this.PJPStartDate;
  
                      // Skip if date is before the applicable start date
                      if (effectiveStartDate && formattedDate < effectiveStartDate) {
                          break;
                      }
  
                      // Skip weekends & holidays before assigning a beat plan
                      if (!this.isWeekendOrHoliday(formattedDate)) {
                          matchingRecords = [beatPlan];
                          beatIndex++; // Move to the next beat plan
                          break;
                      }
  
                      
                  }*/

            }
            console.log('matchingRecords:' + JSON.stringify(matchingRecords))
            return {
                ...dayObj,
                records: matchingRecords,
                style: classList,
                showTooltip: false,
                isHoliday: isHoliday,
                removePJPItembtn: removePJPItembtn,
                beatStyle: isHoliday ? 'background-color: #b20d0d;' : 'background-color: #008a07;'
            };
        });

        this.ind = ind;

        this.calendarDays = this.calendarMonths[this.currentMonthIndex].days;

        this.isBeatPlanView = false;
        this.isCalenderShow = true;
    }
    showNextMonth() {
        if (this.currentMonthIndex < this.calendarMonths.length - 1) {
            this.currentMonthIndex += 1;
            this.mapBeatPlansToCalendar();
        }
    }

    showPreviousMonth() {
        if (this.currentMonthIndex > 0) {
            this.currentMonthIndex -= 1;
            this.ind = 0;
            this.mapBeatPlansToCalendar();

        }
    }
    get currentMonthLabel() {
        if (
            this.calendarMonths &&
            this.calendarMonths.length > 0 &&
            this.currentMonthIndex < this.calendarMonths.length
        ) {
            return this.calendarMonths[this.currentMonthIndex].label;
        }
        return '';
    }

    get currentMonthDays() {
        if (
            this.calendarMonths &&
            this.calendarMonths.length > 0 &&
            this.currentMonthIndex < this.calendarMonths.length
        ) {

            // console.log('this.currentMonthIndex:' + this.currentMonthIndex);
            // console.log(JSON.stringify(this.calendarMonths[this.currentMonthIndex].days));
            return this.calendarMonths[this.currentMonthIndex].days;
        }
        return [];
    }


    get isNotDSM() {
        return !this.isDSM;
    }

    get isPJPNotSubmitted() {
        return this.calenderBeat.Approval_Status__c !== 'Submitted';
    }

    // Handler to toggle customer visibility
    handleToggleChange(event) {
        this.showCustomers = event.target.checked;
    }

    selectedTabFunction() {
        this.resetData();
        switch (this.selectedTab) {
            case 'Summary':
                this.getGraphData();
                break;
            case 'Beats & PJP':
                this.dataUploadObjectName = 'Junction_Beat__c';
                this.getBeatPlanData('pjp');
                break;
            case 'Visits':
                this.getVisitData();
                this.isListView = false;

                break;
            case 'Orders':
                this.getOrderData();
                break;
            case 'Invoices':
                this.invoiceData();
                break;
            case 'Incentives':
                this.Incentives();
                break;
            case 'Expenses':
                this.expenseData();
                break;
            case 'Details':
                this.getUserDetails();
                break;
            case 'Attendance':
                this.attandanceData();
                break;
            case 'Primary Customers':
                this.dataUploadObjectName = this.isDSM ? 'Employee_Customer_Assignment__c' : 'Product_Mapping__c';
                this.getPrimaryCustomerAssignment();
                break;
            case 'Secondary Customers':
                this.dataUploadObjectName = 'Product_Mapping__c';
                this.getSecoundaryCustomerAssignment();
                break;
            case 'Map':
                break;
            case 'Not Visited Customers':
                this.visitSummaryData();

            default:
                break;
        }
    }


    getRecordStyle(record) {
        return record.ApprovalStatus === 'Not Submitted' ? 'background-color: #7f7d13;' :
            record.ApprovalStatus === 'Submitted' ? 'background-color: #ab715c' : record.day.beatStyle;
    }

    openModal() {
        const todayDate = new Date();
        const yyyy = todayDate.getFullYear();
        const mm = String(todayDate.getMonth() + 1).padStart(2, '0'); // Months are 0-based
        const dd = String(todayDate.getDate()).padStart(2, '0');
        this.todaydate = `${yyyy}-${mm}-${dd}`;
        this.isModalOpen = true;
        this.autoCreatePJP = true;
        this.modalBody = {
            'headerName': 'Run PJP',
            'dateLabel': 'Start Date',
            'beatLabel': 'Start Beat'
        };

    }
    openAssignModal() {
        const todayDate = new Date();
        const yyyy = todayDate.getFullYear();
        const mm = String(todayDate.getMonth() + 1).padStart(2, '0'); // Months are 0-based
        const dd = String(todayDate.getDate()).padStart(2, '0');
        this.todaydate = `${yyyy}-${mm}-${dd}`;
        this.isModalOpen = true;
        this.autoCreatePJP = false;
        this.modalBody = {
            'headerName': 'Assign Beats',
            'dateLabel': 'Date',
            'beatLabel': 'Beat'
        };
    }

    closeModal() {
        this.isModalOpen = false;
        this.startDate = null;
        this.startBeat = null;
        this.filterBeatData.beatSearchKeyword = null;
        this.filterBeatData.beatVal = null;
        this.selectedBeatId = null;

    }

    handleStartDateChange(event) {
        const selectedDate = event.target.value;

        if (selectedDate < this.todaydate) {
            // If the selected date is in the past, reset it to today's date
            this.startDate = this.todaydate;
            // Optionally, you can show an alert to the user that past dates are not allowed
            this.genericToastDispatchEvent('Error', 'Past dates are not allowed.', 'error');
            return;
        } else {
            this.startDate = selectedDate;
        }
        // this.startDate = event.target.value;
    }

    handleSearchChange(event) {

        const searchKey = event.target.value;
        this.filterBeatData.beatSearchKeyword = searchKey;
        this.isSubPartLoad = true;


        if (searchKey.length > 0) {

            this.filteredBeatOptions = this.masterBeatPlan.filter(opt =>
                opt.beatName.toLowerCase().includes(searchKey.toLowerCase())
            );

            this.showDropdown = this.filteredBeatOptions.length > 0;
        } else {
            this.showDropdown = false;
        }
        this.isSubPartLoad = false;
    }

    handleOptionSelect(event) {


        const selectedVal = event.currentTarget.dataset.id;
        // alert('selectedVal:'+selectedVal)
        const selectedLabel = this.masterBeatPlan.find(opt => opt.beatId === selectedVal)?.beatName;


        this.filterBeatData.beatVal = selectedVal;
        this.filterBeatData.beatSearchKeyword = selectedLabel;
        this.showDropdown = false;

        this.selectedBeatId = selectedVal;


        // Dispatch or call your existing handler
        const changeEvent = new CustomEvent('change', {
            detail: { name: 'beat', value: selectedVal }
        });
        this.dispatchEvent(changeEvent);
    }

    handlePJPCreation() {
        if (!this.selectedBeatId) {
            this.genericToastDispatchEvent('Error', 'Please Select Start Beat', 'error');
            return;
        }
        else if (!this.startDate) {
            this.genericToastDispatchEvent('Error', 'Please Select Start Date', 'error');
            return;
        }


        this.isSubPartLoad = true;
        PJP_CREATE({ ids: this.selectedId, startdate: this.startDate, startBeat: this.selectedBeatId })
            .then(result => {
                this.beatPlan = result.jDbeatList;
                console.log('this.beatPlan:' + this.beatPlan);
                this.junctionBeats = result.JunctionList;
                this.HolidayList = result.HolidayList;
                this.calenderBeat = result.calenderBeat;

                this.isBeatPlanView = false;
                this.closeModal();
                this.handleViewCal();
                this.isCalenderShow = true;


                this.isSubPartLoad = false;
            })
            .catch(error => {
                console.error(error);
                this.closeModal();
                this.isPageLoaded = false;
                this.isSubPartLoad = false;
            });

    }

    setRecurringFrequency(event) {
        const freq = event.target.value;
        this.calenderBeat.Recurring_Frequency__c = freq;
        this.newPJPRecord.Recurring_Frequency__c = freq;
    }

    rotateBeats() {
        if (!this.calenderBeat.Recurring_Frequency__c) {
            this.genericToastDispatchEvent('Error', 'Please enter valid frequency', 'error');
            return;
        }
        this.isSubPartLoad = true;
        ROTATEBEATS({ ids: this.selectedId, frequency: this.calenderBeat.Recurring_Frequency__c })
            .then(result => {
                this.filteredBeats = [...this.masterBeatPlan];
                this.getBeatPlanData('CalendarView');
                // this.newPJPRecord.Recurring_Frequency__c = null;
                this.isSubPartLoad = false;
            })
            .catch(error => {
                console.error(error);
                this.isPageLoaded = false;
                this.isSubPartLoad = false;
            });

    }


    handlePJPSave() {
        if (!this.selectedBeatId) {
            this.genericToastDispatchEvent('Error', 'Please Select Beat', 'error');
            return;
        }
        else if (!this.startDate) {
            this.genericToastDispatchEvent('Error', 'Please Select Date', 'error');
            return;
        }
        const firstDay = new Date(this.today);
        const lastDay = new Date();
        lastDay.setDate(firstDay.getDate() + 30);

        let beatDate = new Date(this.startDate);

        if (beatDate > lastDay) {
            this.genericToastDispatchEvent('Error', 'You cannot create PJP for dates higher than 30 days.', 'error');
            return;
        }

        if (beatDate.getMonth() == firstDay.getMonth() + 1) {
            this.showNextMonth();
        }
        else if (beatDate.getMonth() == firstDay.getMonth() - 1) {
            this.showPreviousMonth();
        }

        this.draggedAccountId = this.selectedBeatId;

        this.updatePJPCalender(this.startDate, this.selectedBeatId);
        this.closeModal();



    }
    handlePJPSaveNew() {
        if (!this.selectedBeatId) {
            this.genericToastDispatchEvent('Error', 'Please Select Beat', 'error');
            return;
        }
        else if (!this.startDate) {
            this.genericToastDispatchEvent('Error', 'Please Select Date', 'error');
            return;
        }

        const firstDay = new Date(this.today);
        const lastDay = new Date();
        lastDay.setDate(firstDay.getDate() + 30);

        let beatDate = new Date(this.startDate);

        if (beatDate > lastDay) {
            this.genericToastDispatchEvent('Error', 'You cannot create PJP for dates higher than 30 days.', 'error');
            return;
        }

        if (beatDate.getMonth() == firstDay.getMonth() + 1) {
            this.showNextMonth();
        }
        else if (beatDate.getMonth() == firstDay.getMonth() - 1) {
            this.showPreviousMonth();
        }

        // this.updatePJPCalender(this.startDate, this.selectedBeatId);


        this.draggedAccountId = this.selectedBeatId;


        this.updatePJPCalender(this.startDate, this.selectedBeatId);
        this.startDate = null;
        this.startBeat = null;
        this.filterBeatData.beatSearchKeyword = null;
        this.filterBeatData.beatVal = null;
        this.selectedBeatId = null;
        this.closeModal();



    }

    removeItem(event) {
        // Prevent the event from propagating to parent handlers (like openRecord)
        event.stopPropagation();
        // Get the beatId from the button's data-account attribute
        const pjpItemId = event.target.dataset.account;


        deletePJPItem({ pjpItemId: pjpItemId }) // Call the Apex method
            .then(() => {
                this.genericToastDispatchEvent('Success', 'PJP Item removed successfully!', 'success');
                this.getBeatPlanData('CalendarView');
            })
            .catch((error) => {
                this.genericToastDispatchEvent('Error', 'Error deleting PJP Item: ' + error.body.message, 'error');
            });

    }

    savePjpItems(dayIndex) {

        let i = 0;


        let pjpItems = this.calendarMonths[this.currentMonthIndex].days[dayIndex].records.map(rec => {
            return {
                PJP__c: this.calenderBeat != null ? this.calenderBeat.Id : null,
                Date__c: rec.beatDate,
                Assigned_Beat__c: rec.beatId,
                Beat__c: this.isDSM ? rec.beatId : null,
                Order_Number__c: i + 1,
                Status__c: this.isDSM ? 'Approved' : 'Not Submitted',
                Id: rec.pjpItemId != null ? rec.pjpItemId : null,
            };
            i = i + 1;
        });



        savePjpItems({
            userId: this.selectedId,
            pjpItems: pjpItems
        })
            .then(() => {
                this.genericToastDispatchEvent('Success', 'PJP assignments saved!', 'success');
                this.filteredBeats = [...this.masterBeatPlan];
                this.getBeatPlanData('CalendarView');
            })
            .catch(error => {
                this.genericToastDispatchEvent('Error', error.body.message, 'error');
            });
    }

    handleBeatDragStart(event) {
        // Store the dragged beat's information (you could store the beatId or any other necessary data)
        this.draggedBeat = {
            beatId: event.target.dataset.id,
            // beatName: event.target.querySelector('h3').innerText, // Optional, if you need the name of the beat
        };
    }

    handleBeatDrop(event) {
        event.preventDefault();

        const toBeatId = event.currentTarget.dataset.id;
        // Get the `fromBeatId` (where the beat was dragged from)
        const fromBeatId = this.draggedBeat?.beatId;

        if (!fromBeatId || !toBeatId || fromBeatId === toBeatId) return; // If the beat is dropped on the same one, do nothing

        // Proceed with any logic you want to handle when beats are swapped, like updating your data model
        this.moveBeat(fromBeatId, toBeatId); // Assuming you have a `moveBeat` function to handle this
        this.draggedBeat = null;
    }

    moveBeat(fromBeatId, toBeatId) {

        // Logic for moving the beat (you can handle this as per your requirement)
        const fromBeat = this.beatPlan.find(beat => beat.beatId === fromBeatId);
        const toBeat = this.beatPlan.find(beat => beat.beatId === toBeatId);

        if (fromBeat && toBeat) {
            // Swap the positions of the beats in the array (or any other logic needed)
            const fromIndex = this.beatPlan.findIndex(beat => beat.beatId === fromBeatId);
            const toIndex = this.beatPlan.findIndex(beat => beat.beatId === toBeatId);

            if (fromIndex !== -1 && toIndex !== -1) {
                // Swap beats (or you can update their order based on your needs)
                [this.beatPlan[fromIndex], this.beatPlan[toIndex]] = [this.beatPlan[toIndex], this.beatPlan[fromIndex]];
                // Update the orderNumber for each beat based on their new position in the array
                let updatePromises = [];
                this.beatPlan.forEach((beat, index) => {
                    beat.orderNumber = index + 1;  // Update orderNumber based on the new index

                    let data = {
                        Id: beat.beatId,
                        Order_Number__c: beat.orderNumber,
                    };
                    const recordInput = {
                        fields: data
                    };
                    // Push each update promise
                    updatePromises.push(updateRecord(recordInput));
                    //this.changeVisitPlan(recordInput, 'Beat Plans updated successfully!');
                });
                // After all updates are done
                Promise.all(updatePromises)
                    .then(() => {
                        this.genericToastDispatchEvent('Success', 'Beat Plans updated successfully!', 'success');
                    })
                    .catch(error => {
                        console.error('Error updating beat plans:', error);
                    });

                // Trigger re-render of the beatPlan with updated order numbers
                this.beatPlan = [...this.beatPlan];
            }

        }
    }


    handleDragStart(event) {
        // Prevent the event from bubbling up to the parent element
        event.stopPropagation();

        this.draggedStore = {
            storeId: event.target.dataset.id,
            fromBeatId: event.target.dataset.beatId,
            junction: event.target.dataset.junction,
        };
    }

    handleDragOver(event) {
        event.preventDefault();
    }

    handleDrop(event) {

        event.preventDefault();

        const toBeatId = event.currentTarget.dataset.id;

        const dragBeatId = this.draggedBeat?.beatId;
        if (dragBeatId) {
            if (!dragBeatId || !toBeatId || dragBeatId === toBeatId) return;

            this.moveBeat(dragBeatId, toBeatId); // Assuming you have a `moveBeat` function to handle this
            this.draggedBeat = null;
        }
        else {

            const toBeat = this.beatPlan.find(beat => beat.beatId === toBeatId);
            const fromBeat = this.beatPlan.find(beat => beat.beatId === this.draggedStore?.fromBeatId);
            const toStoreId = event.target.dataset.storeid;
            let toStoreIndex = toBeat.accountList.findIndex(store => store.accId === toStoreId);
            //const acc = this.draggedStore.storeId;
            //const visDta = fromBeat.jdData.find(bt => bt.jDId === acc);

            if (!toBeat || !fromBeat) return;

            if (toStoreIndex === -1) {
                toStoreIndex = toBeat.accountList.length;
            }

            // Proceed with drag-and-drop if validation passes
            if (this.draggedStore/* && this.draggedStore.fromBeatId !== toBeatId*/) {

                this.moveStore(this.draggedStore.storeId, this.draggedStore.fromBeatId, toBeatId, toStoreIndex);
            }
            this.draggedStore = null;
        }

    }

    moveStore(storeId, fromBeatId, toBeatId, toStoreIndex) {
        let fromBeat = this.beatPlan.find(beat => beat.beatId === fromBeatId);
        let toBeat = this.beatPlan.find(beat => beat.beatId === toBeatId);

        let toBeatIndex = this.beatPlan.findIndex(beat => beat.beatId === toBeatId);
        let fromBeatIndex = this.beatPlan.findIndex(beat => beat.beatId === fromBeatId);


        if (toBeatIndex === -1 || fromBeatIndex === -1) return;

        if (fromBeat && toBeat) {
            // Handle moving the store within the same beat
            if (fromBeatId === toBeatId) {

                const fromStoreIndex = fromBeat.accountList.findIndex(store => store.accId === storeId);
                //  alert(fromStoreIndex + '-----' + toStoreIndex)
                if (fromStoreIndex === -1) return;

                if (fromStoreIndex !== -1) {
                    // Remove store from the original position
                    const [store] = fromBeat.accountList.splice(fromStoreIndex, 1);


                    // Insert the store at the new index (which should be passed via event)
                    fromBeat.accountList.splice(toStoreIndex, 0, store);
                    let updatePromises = [];
                    // Reorder the accountList based on the new order
                    fromBeat.accountList.forEach((store, index) => {

                        store.orderNumber = index + 1; // Assuming 'order' is the field for the order number
                        let data = {
                            Id: store.JuncId,
                            Order_Number__c: store.orderNumber,
                        };
                        const recordInput = {
                            fields: data
                        };
                        // Push each update promise
                        updatePromises.push(updateRecord(recordInput));
                        //this.changeVisitPlan(recordInput, 'Beat Plans updated successfully!');
                    });
                    // After all updates are done
                    Promise.all(updatePromises)
                        .then(() => {
                            this.genericToastDispatchEvent('Success', 'Beat Plans updated successfully!', 'success');
                        })
                        .catch(error => {
                            console.error('Error updating beat plans:', error);
                        });

                }
            } else {

                //  alert(toBeat.mainBeat.Primary_Customer__c + '============' + fromBeat.mainBeat.Primary_Customer__c)

                if (toBeat.mainBeat.Primary_Customer__c !== fromBeat.mainBeat.Primary_Customer__c) {
                    this.genericToastDispatchEvent('', 'This beat is dedicated to other Primary Customer', 'warning');
                    return;
                }


                for (var i = 0; i < toBeat.accountList.length; i++) {
                    if (toBeat.accountList[i].accId == storeId && fromBeatId !== toBeatId) {
                        this.genericToastDispatchEvent('', 'Already customer added', 'warning');
                        return;
                    }
                }

                /*   console.log('fromBeat:' + JSON.stringify(fromBeat));
                  console.log('toBeat:' + JSON.stringify(toBeat)); */
                // Move store from one beat to another
                const fromStoreIndex = fromBeat.accountList.findIndex(store => store.accId === storeId);
                if (fromStoreIndex === -1) return;
                if (fromStoreIndex !== -1) {
                    let [store] = fromBeat.accountList.splice(fromStoreIndex, 1);
                    toBeat.accountList.push(store);
                    let updatePromises = [];
                    // Reorder the account list in the target beat
                    toBeat.accountList.forEach((store, index) => {
                        store.orderNumber = index + 1; // Assuming 'order' is the field for the order number

                        let data = {
                            Id: store.JuncId,
                            Order_Number__c: store.orderNumber,
                            Child_beat__c: toBeatId
                        };
                        const recordInput = {
                            fields: data
                        };
                        console.log('recordInput1:' + JSON.stringify(recordInput))
                        // Push each update promise
                        updatePromises.push(updateRecord(recordInput));
                        //this.changeVisitPlan(recordInput, 'Beat Plans updated successfully!');

                    });

                    // Reorder the account list in the source beat as well
                    fromBeat.accountList.forEach((store, index) => {
                        store.orderNumber = index + 1; // Update order for the source beat
                        let data = {
                            Id: store.JuncId,
                            Order_Number__c: store.orderNumber,
                        };
                        const recordInput = {
                            fields: data
                        };
                        console.log('recordInput2:' + JSON.stringify(recordInput))
                        // Push each update promise
                        updatePromises.push(updateRecord(recordInput));
                        //this.changeVisitPlan(recordInput, 'Beat Plans updated successfully!');

                    });
                    // After all updates are done
                    Promise.all(updatePromises)
                        .then(() => {
                            this.genericToastDispatchEvent('Success', 'Beat Plans updated successfully!', 'success');
                        })
                        .catch(error => {
                            console.error('Error updating beat plans:', error);
                        });


                }
            }
            // Update the beat plan state
            // this.beatPlan = [...this.beatPlan];
            this.getBeatPlanData('pjp');
            let data = {
                Id: this.draggedStore.junction,
                Child_beat__c: toBeatId,
            };
            console.log('beatPlan:' + JSON.stringify(this.beatPlan))
            const recordInput = {
                fields: data
            };
            // this.changeVisitPlan(recordInput, 'Visit Plans updated successfully!');
        }
    }

    handleTouchStart(event) {
        // Don't start dragging right away
        this.isTouching = false;
        this.isLongPressActive = false;

        // Save for reference
        const target = event.target;

        this.longPressTimer = setTimeout(() => {
            this.isLongPressActive = true;
            this.isTouching = true;
            this.draggedElement = target;

            this.draggedStore = {
                storeId: target.dataset.id,
                fromBeatId: target.dataset.beatId,
                junction: target.dataset.junction,
            };

            this.initialTouchX = event.touches[0].clientX;
            this.initialTouchY = event.touches[0].clientY;

            // ✅ Trigger vibration
            if (navigator.vibrate) {
                navigator.vibrate(100);
            }

        }, 300); // long press threshold (in ms)
    }

    handleTouchMove(event) {

        // ✅ Prevent scrolling only during drag
        event.preventDefault();
        if (!this.isTouching || !this.isLongPressActive || !this.draggedElement) {
            clearTimeout(this.longPressTimer);
            return;
        }

        if (event.touches && event.touches.length > 0) {
            const touchX = event.touches[0].clientX;
            const touchY = event.touches[0].clientY;

            this.currentTouchY = touchY;

            // ✅ Corrected delta calculation
            const deltaX = touchX - this.initialTouchX;
            const deltaY = touchY - this.initialTouchY;

            this.draggedElement.style.position = 'relative'; // Optional for safety
            this.draggedElement.style.zIndex = 1000;
            this.draggedElement.style.transform = `translate(${deltaX}px, ${deltaY}px)`;
            this.draggedElement.classList.add('dragging');
        }
    }

    handleTouchEnd(event) {
        event.preventDefault();

        clearTimeout(this.longPressTimer);


        if (!this.isLongPressActive) return;

        this.isTouching = false;
        this.isLongPressActive = false;



        if (!this.currentTouchY) {
            return;
        }

        const allStores = [...this.template.querySelectorAll('[data-storeid]')];

        let closestStore = null;
        let minDistance = Number.MAX_VALUE;

        allStores.forEach(storeEl => {
            const rect = storeEl.getBoundingClientRect();
            const storeCenterY = rect.top + rect.height / 2;
            const distance = Math.abs(storeCenterY - this.currentTouchY);

            if (distance < minDistance) {
                minDistance = distance;
                closestStore = storeEl;
            }
        });



        // const toBeatId = event.currentTarget.dataset.id;
        const toStoreId = closestStore.dataset.storeid;
        const toBeatId = closestStore.dataset.beatId;

        const toBeat = this.beatPlan.find(beat => beat.beatId === toBeatId);
        const fromBeat = this.beatPlan.find(beat => beat.beatId === this.draggedStore?.fromBeatId);



        const toStoreIndex = toBeat.accountList.findIndex(store => store.accId === toStoreId);
        const fromStoreIndex = fromBeat.accountList.findIndex(store => store.accId === this.draggedStore.storeId);

        //alert(fromStoreIndex + '-----' + toStoreIndex)

        if (toStoreIndex !== -1 && fromStoreIndex !== -1) {
            // this.moveStore(this.draggedStoreId, this.draggedBeatId, toBeatId, toStoreIndex);
            this.moveStore(this.draggedStore.storeId, this.draggedStore.fromBeatId, toBeatId, toStoreIndex);
        }

        // Reset the transformation (optional: based on your requirement, it could be a drop position)
        if (this.draggedElement) {
            this.draggedElement.classList.remove('dragging');
            this.draggedElement.style.transform = '';
        }
        // this.draggedStoreId = null;
        this.draggedBeatId = null;
        this.currentTouchY = null;
        this.draggedElement = null;

        // alert('this.draggedStore.storeId:'+this.draggedStore.storeId)
        // const toStoreIndex = toBeat.accountList.findIndex(store => store.accId === toStoreId);
        //const acc = this.draggedStore.storeId;
        //const visDta = fromBeat.jdData.find(bt => bt.jDId === acc);

        /* if (!toBeat || !fromBeat) return;


        if (toStoreIndex === -1) {
            toStoreIndex = toBeat.accountList.length;
        }

        // Proceed with drag-and-drop if validation passes
        if (this.draggedStore) {
            this.moveStore(this.draggedStore.storeId, this.draggedStore.fromBeatId, toBeatId, toStoreIndex);
        }
        this.draggedStore = null; */

    }

    handleAccountSearch(event) {
        const searchTerm = event.target.value.toLowerCase();

        if (searchTerm === '') {
            this.filteredBeats = [...this.masterBeatPlan];
        } else {

            this.filteredBeats = this.masterBeatPlan.filter(account => {
                const beatNameMatch = account.beatName.toLowerCase().includes(searchTerm.toLowerCase());
                const primaryCustomerMatch = account.mainBeat.Primary_Customer__c
                    ? account.mainBeat.Primary_Customer__r.Name.toLowerCase().includes(searchTerm.toLowerCase())
                    : false;
                const subStockistMatch = account.mainBeat.Sub_Stockist__c
                    ? account.mainBeat.Sub_Stockist__r.Name.toLowerCase().includes(searchTerm.toLowerCase())
                    : false;

                // Return true if any of the conditions match
                return beatNameMatch || primaryCustomerMatch || subStockistMatch;
            });

            /*  this.filteredBeats = this.masterBeatPlan.filter(account =>
                 account.beatName.toLowerCase().includes(searchTerm)) */

        }
    }
    get divClass() {
        return this.isNotDSM ? 'slds-col slds-size_9-of-12 scrolladd' : 'slds-col slds-size_12-of-12 scrolladd';
    }
    get divClass2() {
        return this.isActiveUserNotDSM ? 'slds-col slds-size_9-of-12 scrolladd' : 'slds-col slds-size_12-of-12 scrolladd';
    }

    createNewPJP() {
        this.showPJPForm = true;
        const todayDate = new Date();
        const yyyy = todayDate.getFullYear();
        const mm = String(todayDate.getMonth() + 1).padStart(2, '0'); // Months are 0-based
        const dd = String(todayDate.getDate()).padStart(2, '0');
        this.todaydate = `${yyyy}-${mm}-${dd}`;
        this.newPJPRecord = {
            Start_Month__c: '',
            Next_Start_Date__c: ''
        };

    }
    handlePJPStartDate(event) {
        const selectedDate = event.target.value;

        if (selectedDate < this.todaydate) {
            // If the selected date is in the past, reset it to today's date
            this.newPJPRecord.Start_Month__c = null;
            // Optionally, you can show an alert to the user that past dates are not allowed
            this.genericToastDispatchEvent('Error', 'Past dates are not allowed.', 'error');
            event.target.setCustomValidity("Please Select Valid Start Date.");
            event.target.value = null; // Clear the invalid input
            event.target.reportValidity();
            return;

        } else {
            this.newPJPRecord.Start_Month__c = selectedDate;
        }


    }
    handlePJPEndDate(event) {
        const selectedDate = event.target.value;
        if (selectedDate < this.newPJPRecord.Start_Month__c || selectedDate < this.todaydate) {
            // If the selected date is in the past, reset it to today's date
            this.newPJPRecord.Next_Start_Date__c = null;
            // Optionally, you can show an alert to the user that past dates are not allowed
            this.genericToastDispatchEvent('Error', 'Past dates are not allowed.', 'error');
            event.target.setCustomValidity("Please Select Valid End Date.");
            event.target.value = ''; // Clear the invalid input
            event.target.reportValidity();
            return;
        } else {
            this.newPJPRecord.Next_Start_Date__c = selectedDate;
        }

    }
    handlePJPRecCreation(event) {


        if (!this.newPJPRecord.Start_Month__c) {
            this.genericToastDispatchEvent('Error', 'Please Select Valid Start Date', 'error');
            return;
        }
        else if (!this.newPJPRecord.Next_Start_Date__c) {
            this.genericToastDispatchEvent('Error', 'Please Select Valid End Date', 'error');
            return;
        }

        const fields = {
            OwnerId: this.selectedId,
            Start_Month__c: this.newPJPRecord.Start_Month__c,
            Next_Start_Date__c: this.newPJPRecord.Next_Start_Date__c,
            User__c: this.selectedId
        };
        const recordInput = { apiName: CALENDER_OBJECT.objectApiName, fields };
        createRecord(recordInput)
            .then((result) => {
                this.getBeatPlanData('pjp');
                this.showPJPForm = false;
            })
            .catch((error) => {

                console.error('Error creating record:', error);
            });
    }

    closePJPForm() {
        this.showPJPForm = false;
    }

    handleDataUpload() {
        this.showDataUpload = true;
        this.isCalenderShow = false;
        this.isBeatPlanView = false;
        this.isButtonFunctions = false;

    }



    handleAddVisit() {

        if (this.calenderBeat == null) {
            this.genericToastDispatchEvent('Error', 'Atleast one Active PJP record should be present for the user!', 'error');
        }
        else {

            if (this.beatPlan && this.beatPlan.length != 0) {
                this.isCalenderShow = false;
                this.isBeatPlanView = false;
                this.isButtonFunctions = false;
                this.isAddVisit = true;
                this.isNewBeatCreate = false;
                this.isCloneBeat = false;
            } else {
                this.genericToastDispatchEvent('', 'Create beat first', 'warning');
            }
        }
    }
    handleCloneBeat() {

        if (this.calenderBeat == null) {
            this.genericToastDispatchEvent('Error', 'Atleast one Active PJP record should be present for the user!', 'error');
        }
        else {

            if (this.beatPlan && this.beatPlan.length != 0) {
                this.isCalenderShow = false;
                this.isBeatPlanView = false;
                this.isButtonFunctions = false;
                this.isAddVisit = true;
                this.isCloneBeat = true;
                this.isNewBeatCreate = false;
            } else {
                this.genericToastDispatchEvent('', 'Create beat first', 'warning');
            }
        }
    }
    handleViewHoliday() {
        this.isCalenderShow = false;
        this.isBeatPlanView = false;
        this.isAddVisit = false;
        this.isHoliday = true;
        this.isSubPartLoad = true;

        HOLIDAY_DATA({
            ids: this.selectedId
        })
            .then(result => {
                this.holidayData = result.holiday;
                this.isSubPartLoad = false;
            })
            .catch(error => {
                console.error(error);
                this.isSubPartLoad = false;
            });

    }
    changeVisitPlan(recordInput, message) {
        updateRecord(recordInput)
            .then((result) => {
                console.log(result);
                this.genericToastDispatchEvent('Success', message, 'success');
            })
            .catch((error) => {
                // Handle error in record creation

                console.error('Error creating record:', error);
            });
    }
    handleAddBeat() {

        /*    if(this.calenderBeat == null){
                this.createCalenderPlan();
            }else{
                this.createBeatPlan();
            }*/
        if (this.calenderBeat == null) {
            this.genericToastDispatchEvent('Error', 'Atleast one Active PJP record should be present for the user!', 'error');
        }
        else {
            this.isCalenderShow = false;
            this.isBeatPlanView = false;
            this.isButtonFunctions = false;
            this.isAddVisit = true;
            this.isNewBeatCreate = true;
            this.isCloneBeat = false;
        }

    }
    createCalenderPlan() {
        const fields = {
            OwnerId: this.selectedId
        };
        const recordInput = { apiName: CALENDER_OBJECT.objectApiName, fields };
        createRecord(recordInput)
            .then((result) => {
                this.calenderBeat = {
                    Id: result.id,
                    Start_Month__c: null,
                    Next_Start_Date__c: null
                };
                this.createBeatPlan();

            })
            .catch((error) => {

                console.error('Error creating record:', error);
            });
    }
    createBeatPlan() {
        const fields = {
            OwnerId: this.selectedId,
            Calendar_beat__c: this.calenderBeat.Id
        };
        const recordInput = { apiName: CH_BEAT_OBJECT.objectApiName, fields };
        createRecord(recordInput)
            .then((result) => {
                this.getBeatPlanData('pjp');

            })
            .catch((error) => {

                console.error('Error creating record:', error);
            });
    }

    handleViewCal() {
        if (this.beatPlan && this.beatPlan.length != 0) {

            this.generateCalendar();
            this.isHoliday = false;

            if (this.calenderBeat.Start_Month__c != null) {
                //  this.mapBeatPlansToCalendar('');
            } else {
                this.isCalenderShow = true;
                this.isBeatPlanView = false;


            }
            this.dataUploadObjectName = 'PJP_Item__c';

            this.getBeatPlanData('CalendarView');
        }
        else {
            this.genericToastDispatchEvent('', 'Create beat first', 'warning');
        }
    }
    handleViewPJP() {
        // this.isCalenderShow = false;
        // this.isBeatPlanView = false;
        // this.isAddVisit = false;
        this.isHoliday = false;
        this.ind = 0;
        console.log(JSON.stringify(this.beatPlan))
        this.dataUploadObjectName = 'Junction_Beat__c';
        // if (this.beatPlan && this.beatPlan.length != 0) {
        this.isBeatPlanView = true;
        this.isCalenderShow = false;
        this.beatPlan.sort((a, b) => a.orderNumber - b.orderNumber);
        //} else {
        this.getBeatPlanData('pjp');
        //}
    }
    goBack() {
        this.isCalenderShow = true;
        this.isBeatPlanView = false;
        this.isAddVisit = false;
        this.isHoliday = false;
        this.getBeatPlanData('CalendarView');
    }
    handleAddHoliday() {
        this.isHolidayPopup = true;
    }

    removeHoliday(event) {
        const index = parseInt(event.currentTarget.dataset.index, 10);
        const id = event.currentTarget.dataset.id;
        deleteRecord(id)
            .then(() => {
                this.holidayData = [...this.holidayData.slice(0, index), ...this.holidayData.slice(index + 1)];
                //this.handleViewHoliday();        
            })
            .catch((error) => {
                console.log(error);
            });
    }
    handleMouseOver(event) {
        event.preventDefault();

        const indexi = parseInt(event.target.dataset.indexi, 10);
        const indexj = parseInt(event.target.dataset.indexj, 10);

        // eslint-disable-next-line vars-on-top
        var accDta = [];
        if (this.calendarMonths[this.currentMonthIndex].days[indexi].isHoliday) {
            return;
        }

        const Dta = this.calendarMonths[this.currentMonthIndex].days[indexi].records[indexj];
        console.log('Dta:==============' + JSON.stringify(Dta))
        if (Dta.accountList) {
            for (let i = 0; i < Dta.accountList.length; i++) {


                const rec = Dta.accountList[i];
                accDta.push({
                    name: rec.accName,
                    id: rec.accId
                });
            }
        }
        // eslint-disable-next-line eqeqeq
        if (accDta.length == 0) {
            accDta = [{
                name: 'No Accounts',
                id: 'No Accounts'
            }]
        }

        // this.calendarMonths[this.currentMonthIndex].days[indexi].showTooltip = true
        this.indexVal = indexi
        this.calendarMonths[this.currentMonthIndex].days = [...this.calendarMonths[this.currentMonthIndex].days];
        //  this.tooltipData = accDta;
        // this.showTooltip = true;
    }

    handleMouseLeave() {
        this.calendarMonths[this.currentMonthIndex].days[this.indexVal].showTooltip = false
        this.indexVal = 0;
        this.calendarMonths[this.currentMonthIndex].days = [...this.calendarMonths[this.currentMonthIndex].days];
    }
    // Helper function to check if a date is a weekend or a holiday
    isWeekendOrHoliday(dateStr) {
        let date = new Date(dateStr);
        let dayOfWeek = date.getDay(); // 0 = Sunday, 6 = Saturday

        // Check if the date is a weekend
        if (dayOfWeek === 0) {
            return true;
        }

        // Check if the date is a holiday
        let isHoliday = this.HolidayList?.some(holi => {
            let recDate = holi.beatDate ? new Date(holi.beatDate).toISOString().split('T')[0] : null;
            return recDate === dateStr;
        });

        return isHoliday;
    }
    onClickDispatchEvent(event) {
        const msg = event.detail;
        if (msg.message == 'goBack') {
            this.selectedTabFunction();
            this.isCalenderShow = false;
            this.isBeatPlanView = true;
            this.isButtonFunctions = true;
            this.isAddVisit = false;
            this.showDataUpload = false;
        }
        if (msg.message == 'visitCreated') {
            this.isCalenderShow = false;
            this.isBeatPlanView = true;
            this.isButtonFunctions = true;
            this.isAddVisit = false;
            this.getBeatPlanData('pjp');
        }
        else if (msg.message == 'beatPopClose') {
            if (!msg.saveNew) {
                this.isNewBeatCreate = false;

            } else {
                this.getBeatPlanData('pjp');
                this.isNewBeatCreate = false;
            }

        }
        else if (msg.message == 'saveBeatPlan') {
            if (!msg.saveNew) {
                this.getBeatPlanData('pjp');
                this.isNewBeatCreate = false;
            } else {

            }

        }
        else if (msg.message == 'HolidayPopClose') {
            if (!msg.saveNew) {
                this.isHolidayPopup = false;

            } else {
                this.handleViewHoliday
                this.isHolidayPopup = false;
            }

        }
        else if (msg.message == 'saveHolidayPlan') {
            if (!msg.saveNew) {
                this.handleViewHoliday();
                this.isHolidayPopup = false;
            }

        }
    }

    handleCalDragStart(event) {
        this.draggedAccountId = event.target.dataset.id;
        console.log('draggedAccountId: ==== ' + this.draggedAccountId);
    }

    handleCalDragOver(event) {
        event.preventDefault();
    }

    handleCalDrop(event) {
        event.preventDefault();

        const date = event.currentTarget.dataset.date;
        this.updatePJPCalender(date, this.draggedAccountId);


    }
    updatePJPCalender(date, beatId) {

        let calendarDays = this.calendarMonths[this.currentMonthIndex].days;


        if (date && beatId) {
            const account = this.masterBeatPlan.find(acc => acc.beatId === beatId);


            if (account) {

                const yyyy = new Date().getFullYear();
                const mm = String(new Date().getMonth() + 1).padStart(2, '0'); // Months are 0-based
                const dd = String(new Date().getDate()).padStart(2, '0');
                const todaydate = `${yyyy}-${mm}-${dd}`;


                if (date < todaydate) {
                    this.genericToastDispatchEvent('Error', 'You cannot plan beats for Past Dates!', 'error');
                    return;
                }

                const dayIndex = calendarDays.findIndex(day => day.formattedDate === date);


                if (dayIndex !== -1) {
                    this.dayIndex = dayIndex;

                    const exists = calendarDays[dayIndex].records.some(
                        acc => acc.beatId === beatId
                    );

                    if (exists) {
                        this.genericToastDispatchEvent('Error', 'This beat is already assigned on this day!', 'error');
                        return;
                    }
                    if (calendarDays[dayIndex].isHoliday) {
                        this.genericToastDispatchEvent('Error', 'You cannot plan beats on Holiday!', 'error');
                        return;
                    }


                    // Check if the selected day already has a beat assigned
                    if (calendarDays[dayIndex].records.length > 0 && calendarDays[dayIndex].records[0].pjpItemId != null) {

                        const modal = this.template.querySelector('c-custom-confirmation-modal');
                        modal.openModal(`The beat is already assigned on this day. Are you sure you want to request for new beat in PJP for this day?`);

                        /* this.genericToastDispatchEvent('Error', 'Only one beat can be assigned per day.!', 'error');

                        return; // Prevent adding another beat on the same day */
                    }
                    /*  else if (new Date(date).getDay() == 0) { // We removed this confirmation modal for holiday because it was showing error while clicking 'Yes' , we will not get records for existing beat (records[0])
                         const modal = this.template.querySelector('c-custom-confirmation-modal');
                         modal.openModal(`Are you sure you want to request beat for Sunday?`);
                     } */
                    else {


                        if (!exists) {
                            this.calendarMonths[this.currentMonthIndex].days[dayIndex].records = [
                                ...this.calendarMonths[this.currentMonthIndex].days[dayIndex].records,
                                { beatId: account.beatId, beatName: account.beatName, beatDate: date }
                            ];


                            this.savePjpItems(dayIndex);
                        }
                    }
                    // Check if account already exists for this day

                }
            }
        }
    }

    handleModalResponse(event) {

        if (event.detail) {
            // User clicked "Yes"

            let calendarDays = this.calendarMonths[this.currentMonthIndex].days;
            const newBeat = this.masterBeatPlan.find(acc => acc.beatId === this.draggedAccountId);

            let records = calendarDays[this.dayIndex].records;

            const exisBeat = records[0];
            exisBeat.beatId = newBeat.beatId;
            exisBeat.beatName = newBeat.beatName;
            //exisBeat.pjpItemId = exisBeat.pjpItemId;

            this.savePjpItems(this.dayIndex);


        } else {
            // User clicked "No"
            console.log('Beat not added to this day.');
        }
    }

    submitApproval() {

        let pjpId = this.calenderBeat != null ? this.calenderBeat.Id : null;

        submitApprovalProcess({ userId: this.selectedId, pjpId: this.pjpId })
            .then(result => {
                this.getBeatPlanData('CalendarView');
                // Handle success - Notify user or update UI
                this.genericToastDispatchEvent('Success', 'PJP successfully submitted for approval!', 'success');
            })
            .catch(error => {
                // Handle error
                console.error('Error submitting PJP for approval: ', error);
                this.genericToastDispatchEvent('Error', error, 'error');
            });


    }




    loadGoogleChartLoad(result, isLoadNew) {
        let colors = ['#b87333', 'silver', 'gold', '#e5e4e2'];
        this.chartData = []; // ✅ Initialize empty array

        // ✅ Add Sales Data Chart
        if (result.formattedUsersSales && result.formattedUsersSales.length > 0) {
            const salesData = result.formattedUsersSales;
            this.chartData.push({
                chartType: 'ColumnChart',
                title: 'Sales by Year',
                data: salesData.map((item, index) => [
                    item.monthName,
                    parseFloat(item.totalGrandTotal),
                    colors[index % colors.length]
                ])
            });

        }
        // ✅ Add Visit Data Chart
        if (result.visitGraphlist && result.visitGraphlist.length > 0) {
            const salesData = result.visitGraphlist;
            this.chartData.push({
                chartType: 'ColumnChart',
                title: 'Visit by Year',
                data: salesData.map((item, index) => [
                    item.monthName,
                    parseInt(item.totalVisits),
                    colors[index % colors.length]
                ])
            });
        }
        // ✅ Add Orders Data Chart
        if (result.formattedUsersOrder && result.formattedUsersOrder.length > 0) {
            const salesData = result.formattedUsersOrder;
            this.chartData.push({
                chartType: 'ColumnChart',
                title: 'Orders by Year',
                data: salesData.map((item, index) => [
                    item.monthName,
                    parseFloat(item.totalGrandTotal),
                    colors[index % colors.length]
                ])
            });
        }

        // ✅ Add Expense Data Chart
        if (result.formattedUsersExp && result.formattedUsersExp.length > 0) {
            const salesData = result.formattedUsersExp;
            this.chartData.push({
                chartType: 'ColumnChart',
                title: 'Expenses by Year',
                data: salesData.map((item, index) => [
                    item.monthName,
                    parseFloat(item.totalGrandTotal),
                    colors[index % colors.length]
                ])
            });
        }
        if (result.graphlist && result.graphlist.length > 0) {
            const salesData = result.graphlist;

            // Prepare data for ColumnChart or LineChart
            this.chartData.push({
                chartType: 'linechart_material', // or 'LineChart'
                title: 'Actual vs Target', // Chart title
                data: salesData.map((item) => [
                    item.xAxis, // x-axis label (e.g., "Feb 2025")
                    parseFloat(item.actual), // actual value (decimal)
                    parseFloat(item.target) // target value (decimal)
                ])
            });
        }

        // ✅ Prepare VF Page URL & Send Data
        if (this.chartData.length > 0) {
            this.isVfPage = true;
            this.prepareVFUrl(isLoadNew);
        } else {
            this.isVfPage = false;
        }
    }
    prepareVFUrl(isLoadNew) {
        let baseUrl = "/apex/GoogleChart";
        let encodedData = encodeURIComponent(JSON.stringify(this.chartData));
        this.vfPageUrl = `${baseUrl}?data=${encodedData}`;
        if (isLoadNew) {
            this.sendDataToVF();
        }
    }

    handleIframeLoad() {
        const iframe = this.template.querySelector("iframe");
        if (iframe) {
            this.vfWindow = iframe.contentWindow;
            setTimeout(() => this.sendDataToVF(), 500); // Ensure VF is fully loaded before sending data
        }
    }

    sendDataToVF() {
        if (!this.vfWindow) {
            console.error("VF window not ready yet!");
            return;
        }

        this.vfWindow.postMessage({ chartData: this.chartData }, "*");
    }
    handleUserChange(event) {
        const id = event.detail.value;
        const selectedOption = this.usersOptions.find(option => option.value === id);
        //this.selectedName = selectedOption ? selectedOption.label : '';
        this.nameSelected = {
            user: selectedOption.label,
            id: selectedOption.value,
            profile: selectedOption.profile
        }
        this.isDSM = this.nameSelected.profile === 'DSM' || this.nameSelected.profile === 'SSA';
        if (id != null) {
            this.selectedId = id;
            if (this.recordId) {
                this.employeeId = this.recordId;
                this.objectName = 'Employee';
            }
            else {
                this.employeeId = this.selectedId;
                this.objectName = 'User';
            }
            this.newBeatBtn = this.isAdmin /* || this.LoggedInUser.Id != this.selectedId */;
            //this.getGraphData();
            this.selectedTabFunction();
        }
    }

    // User Search 
    handleUserSearch(event) {
        let searchValueName = event.target.value;
        if (searchValueName) {
            let objData = this.userList;
            let searchedData = [];
            for (let i = 0; i < objData.length; i++) {
                const objName = objData[i];
                if (
                    (objName.Name && objName.Name.toLowerCase().includes(searchValueName.toLowerCase())) ||
                    (objName.Employee_Code__c && objName.Employee_Code__c.toLowerCase().includes(searchValueName.toLowerCase())) 
                ) {
                    searchedData.push(objName);
                    if (searchedData.length >= 50) break;
                }
            }
            this.showUsers = searchedData.length > 0;
            this.searchedUserList = searchedData;
        } else {
            this.showUsers = true;
            this.searchedUserList = this.userList;
            this.userSearchText ='';
            this.isReadOnly = false;
        }
    }

    selectUser(event) {
        const dataset = event.currentTarget.dataset;

        let userId = dataset.id;
        let userName = dataset.name;
        let profileName = dataset.profile;
        this.userSearchText = userName;
        this.showUsers = false;
        this.isReadOnly = true;
        this.nameSelected = {
            user: userName,
            id: userId,
            profile: profileName
        }
        this.isDSM = this.nameSelected.profile === 'DSM' || this.nameSelected.profile === 'SSA';
        if (userId != null) {
            this.selectedId = userId;
         //   alert('this.selectedId>'+this.selectedId);
            if (this.recordId) {
                this.employeeId = this.recordId;
                this.objectName = 'Employee';
            }
            else {
                this.employeeId = this.selectedId;
                this.objectName = 'User';
            }
            this.newBeatBtn = this.isAdmin /* || this.LoggedInUser.Id != this.selectedId */;
            //this.getGraphData();
            this.selectedTabFunction();
        }
   
    }



    getGraphData() {
        if (this.selectedId == null)
            return;
        GRAPH_DATA_USER({
            ids: this.selectedId
        })
            .then(result => {
                this.loadGoogleChartLoad(result, true);
            })
            .catch(error => {
                console.error(error);
            });
    }
    selectTab(event) {
        const clickedTab = event.target.label; // Get the label of the clicked tab
        // const clickedTabValue = event.target.value; // Get the value of the clicked tab
        this.selectedTab = clickedTab;
        this.selectedTabFunction();
    }
    resetData() {
        this.beatPlan = [];
        this.beatCalenderPlan = [];
        this.beats = [];
        this.isAddVisit = false;
        //this.isListView = false;
        this.isButtonFunctions = this.selectedUserActive;
        this.InvFilter.srchVal = '';
        this.InvFilter.srchVal = '';
        this.ordFilter.srchVal = '';
        this.visFilter.srchVal = '';
        this.map = null;
        this.isListView = false;
        this.isListViewShow = true;
        this.showDataUpload = false;


    }
    /* moveStore(storeId, fromBeatId, toBeatId) {
       
           let fromBeat = this.beatPlan.find(beat => beat.beatId === fromBeatId);
           let toBeat = this.beatPlan.find(beat => beat.beatId === toBeatId);
       
           let toBeatIndex = this.beatPlan.findIndex(beat => beat.beatId === toBeatId);
           let fromBeatIndex = this.beatPlan.findIndex(beat => beat.beatId === fromBeatId);
       
           //alert(toBeatIndex + '---' + fromBeatIndex)
           if (toBeatIndex === -1 || fromBeatIndex === -1) return;
           var toBeatDate = new Date(toBeat.beatDate);
       
           
       
           if (fromBeat && toBeat) {
               const finAcc = toBeat.accountList.find(store => store.accId === storeId);
               for (var i = 0; i < toBeat.accountList.length; i++) {
                   if (toBeat.accountList[i].accId == storeId && fromBeatId !== toBeatId) {
                       this.genericToastDispatchEvent('', 'Already customer added', 'warning');
                       return;
                   }
               }
               const storeIndex = fromBeat.accountList.findIndex(store => store.accId === storeId);
              // alert(storeIndex)
               if (storeIndex !== -1) {
                   var [store] = fromBeat.accountList.splice(storeIndex, 1);
                   // store.plannedDate = toBeat.beatDate;
                   toBeat.accountList.push(store);
                   this.beatPlan = [...this.beatPlan];
                   let data = {
                       Id: this.draggedStore.junction,
                       Child_beat__c: toBeatId,
                   };
                   const recordInput = {
                       fields: data
                   }
                   this.changeVisitPlan(recordInput);
               }
           }
       }*/
    /*   mapBeatPlansToCalendar() {
           let beatIndex = 0; // Track current beatPlan index
           var startDt =this.calenderBeat.Start_Month__c;
           this.calendarDays = this.calendarDays.map(dayObj => {
               if (!dayObj.date) return dayObj;
       
               let formattedDate = dayObj.formattedDate;
               let currentDate = new Date(formattedDate);
               let dayOfWeek = currentDate.getDay(); // 0 = Sunday, 6 = Saturday
       
               let classList = 'background-color:rgb(255, 255, 255) !important; background:rgb(255, 255, 255) !important';
               let matchingRecords = [];
               let isHoliday = false;
               // If it's a weekend, mark as 'Official Holiday' and skip beat plans
               if (dayOfWeek === 0 || dayOfWeek === 6) {
                   return {
                       ...dayObj,
                       // records: [{ Name: 'Official Holiday' }],
                       style: classList,
                       showTooltip: false
                   };
               }
               
               // Check if a holiday exists on this date
               let matchingHoliday = this.HolidayList?.filter(holi => {
                   let recDate = holi.beatDate ? new Date(holi.beatDate).toISOString().split('T')[0] : null;
                   return recDate === formattedDate;
               }) || [];
       
               // If a holiday exists, display it
               if (matchingHoliday.length > 0) {
                   classList = 'background-color: #f7caac !important; background: #f7caac !important';
                   matchingRecords = matchingHoliday;
                   isHoliday = true;
               } 
               // If no holiday, assign the next available beat plan
               else if (this.beatPlan && beatIndex < this.beatPlan.length) {
                   matchingRecords = [this.beatPlan[beatIndex]];
                   isHoliday = false;
                   beatIndex++; // Move to the next beat plan
               }
       
               return {
                   ...dayObj,
                   records: matchingRecords,
                   style: classList,
                   showTooltip: false,
                   isHoliday : isHoliday
               };
           });
       
           this.isBeatPlanView = false;
           this.isCalenderShow = true;
       }*/
    toggleMore(event) {
        const dateKey = event.target.dataset.date;
        this.calendarDays = this.calendarDays.map(day => {
            if (day.formattedDate === dateKey) {
                return {
                    ...day,
                    showAll: !day.showAll,
                    visibleRecords: day.showAll ? day.records.slice(0, 4) : day.records // ✅ Toggle records
                };
            }
            return day;
        });
    }

    openRecord(event) {
        const recordId = event.target.dataset.id;

        if (this.isPhone) {

            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: recordId,
                    actionName: 'view' // or 'edit' if needed
                }
            });
        }
        else {
            this[NavigationMixin.GenerateUrl]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: recordId,
                    actionName: 'view'
                }
            }).then(url => {
                // Open the record in a new tab
                window.open(url, '_blank');
            });
        }

        // Generate URL for the record
        /*  this[NavigationMixin.GenerateUrl]({
             type: 'standard__recordPage',
             attributes: {
                 recordId: recordId,
                 actionName: 'view'
             }
         }).then(url => {
             // Open the record in a new tab
             window.open(url, '_blank');
         }); */
    }
    openTargetLWCPAGE(event) {
        const recordId = event.target.dataset.id;

        this[NavigationMixin.GenerateUrl]({
            type: 'standard__component',
            attributes: {
                componentName: 'c__targetVsActualLwc'
            },
            state: {
                c__periodId: recordId,
                c__ExecutiveId: this.selectedId
            }
        }).then(url => {

            window.open(url, '_blank');
        });
    }
    openExpRecord(event) {
        const recordId = event.target.dataset.id;

        this[NavigationMixin.GenerateUrl]({
            type: 'standard__component',
            attributes: {
                componentName: 'c__expenseLwc'
            },
            state: {
                c__recordId: recordId
            }
        }).then(url => {

            window.open(url, '_blank');
        });
    }
    handleVisChange(event) {
        this.visFilter.srchVal = '';
        this.visFilter[event.target.name] = event.target.value;
        this.allVisitData();
    }
    getVisitData() {

        const today = new Date();
       // const firstDate = new Date(today.getFullYear(), today.getMonth(), 1);
        //const lastDate = new Date(today.getFullYear(), today.getMonth() + 1, 0);
        const firstDate = today;
        const lastDate = today;
        const formatDate = (date) => date.toLocaleDateString('en-CA');
        this.visFilter.fromDate = formatDate(firstDate);
        this.visFilter.toDate = formatDate(lastDate);
        this.visFilter.status = 'All';
        this.visFilter.duration = 'All'
        this.allVisitData();
        //this.template.querySelector('[data-id="toggle1"]').unchecked = false;      
    }

    allVisitData() {
        this.isSubPartLoad = true;
        const { fromDate, toDate, status, duration } = this.visFilter
        VISIT_DATA({
            ids: this.selectedId,
            frmDate: fromDate,
            toDate: toDate,
            status: status,
            duration: duration
        })
            .then(result => {
                this.VisitData = result.visitData;
                this.isVisitData = this.VisitData.length != 0 ? true : false;
                this.visFilter.originalVisData = result.visitData;
                if (this.visFilter.duration == 'All' && this.visFilter.status == 'All') {
                    this.visFilter.durationVal = result.duration;
                }
                this.visFilter.statusVal = result.statusOptions;
                this.isSubPartLoad = false;
            })
            .catch(error => {
                console.error(error);
                this.isSubPartLoad = false;
            });
    }
    // isMapLoaded = false;
    handleVisSerch(event) {
        const txt = event.target.value;
        if (txt.length > 0) {
            this.visFilter.srchVal = txt;
            var visUpdate = [];
            for (let i = 0; i < this.visFilter.originalVisData.length; i++) {
                const vis = this.visFilter.originalVisData[i];
                if (vis.accName && vis.accName.toLowerCase().indexOf(txt.toLowerCase()) !== -1) {
                    visUpdate.push(vis);
                }
            }
            this.VisitData = visUpdate;
        } else {
            this.VisitData = this.visFilter.originalVisData;
        }
    }
    changeToggle() {
        this.isListView = !this.isListView;
        this.isListViewShow = !this.isListViewShow
        // if(!this.isListView){
        //this.initializeMap();
        // }else{
        //     this.map.remove();
        // }
    }

    getOrderData() {

        const today = new Date();
        //const firstDate = new Date(today.getFullYear(), today.getMonth(), 1);
        //const lastDate = new Date(today.getFullYear(), today.getMonth() + 1, 0);
        const firstDate = today;
        const lastDate = today;
        const formatDate = (date) => date.toLocaleDateString('en-CA');
        this.ordFilter.fromDate = formatDate(firstDate);
        this.ordFilter.toDate = formatDate(lastDate);
        this.ordFilter.status = 'All';
        this.OrderData();
    }
    OrderData() {
        this.isSubPartLoad = true;
        const { status, fromDate, toDate } = this.ordFilter;
        ORD_DATA({
            ids: this.selectedId,
            status: status,
            frmDate: fromDate,
            toDate: toDate
        })
            .then(result => {
                this.ordFilter.statusVal = result.statusOptions
                this.ordFilter.allordData = result.TotalOrderData;
                this.isOrderData = this.ordFilter.allordData.length != 0 ? true : false;
                this.ordFilter.originalOrdData = result.TotalOrderData;
                this.getOrderSumary();
                this.isSubPartLoad = false;
            })
            .catch(error => {
                console.error(error);
                this.isSubPartLoad = false;
            });
    }
    handleOrdChange(event) {
        this.ordFilter.srchVal = '';
        this.ordFilter[event.target.name] = event.target.value;
        this.OrderData();
    }
    handleOrdSerch(event) {
        const txt = event.target.value;
        if (txt.length > 0) {
            this.ordFilter.srchVal = txt;
            var ordUpdate = [];
            for (let i = 0; i < this.ordFilter.originalOrdData.length; i++) {
                const ord = this.ordFilter.originalOrdData[i];
                if (ord.accName && ord.accName.toLowerCase().indexOf(txt.toLowerCase()) !== -1) {
                    ordUpdate.push(ord);
                }
            }
            this.ordFilter.allordData = ordUpdate;
        } else {
            this.ordFilter.allordData = this.ordFilter.originalOrdData;
        }
        this.getOrderSumary();
    }

    getOrderSumary() {
        if (!this.ordFilter || !this.ordFilter.allordData) {
            this.ordFilter.totalOrderAmount = 0;
            this.ordFilter.totalNoOfOrders = 0;
        }

        const totalOrderAmount = this.ordFilter.allordData.reduce(
            (sum, ord) => sum + (ord.Amount || 0),
            0
        );

        const primaryOrderAmount = this.ordFilter.allordData
            .filter(ord => ord.customerType === 'Primary Customer')
            .reduce((sum, ord) => sum + (ord.Amount || 0), 0);

        const secondaryOrderAmount = this.ordFilter.allordData
            .filter(ord => ord.customerType === 'Secondary Customer')
            .reduce((sum, ord) => sum + (ord.Amount || 0), 0);


        const totalNoOfOrders = this.ordFilter.allordData.length;

        this.ordFilter.totalOrderAmount = totalOrderAmount.toFixed(2) || 0;
        this.ordFilter.primaryOrderAmount = primaryOrderAmount.toFixed(2) || 0;
        this.ordFilter.secondaryOrderAmount = secondaryOrderAmount.toFixed(2) || 0;
        this.ordFilter.totalNoOfOrders = totalNoOfOrders || 0;
    }

    invoiceData() {

        const today = new Date();
        //const firstDate = new Date(today.getFullYear(), today.getMonth(), 1);
        //const lastDate = new Date(today.getFullYear(), today.getMonth() + 1, 0);
        const firstDate = today;
        const lastDate = today;
        const formatDate = (date) => date.toLocaleDateString('en-CA');
        this.InvFilter.fromDate = formatDate(firstDate);
        this.InvFilter.toDate = formatDate(lastDate);
        this.InvFilter.status = 'All';
        this.getInvoiceData();
    }
    getInvoiceData() {
        this.isSubPartLoad = true;
        const { status, fromDate, toDate } = this.InvFilter;
        INV_DATA({
            ids: this.selectedId,
            status: status,
            frmDate: fromDate,
            toDate: toDate
        })
            .then(result => {
                this.InvFilter.statusVal = result.statusOptions
                this.InvFilter.allInvData = result.TotalInvoiceData;
                this.isInvData = this.InvFilter.allInvData.length != 0 ? true : false;
                this.InvFilter.originalInvData = result.TotalInvoiceData;
                this.getInvoiceSumary();
                this.isSubPartLoad = false;
            })
            .catch(error => {
                console.error(error);
                this.isSubPartLoad = false;
            });
    }

    getInvoiceSumary() {
        if (!this.InvFilter || !this.ordFilter.allInvData) {
            this.InvFilter.totalAmount = 0;
            this.InvFilter.totalNoOfInvoices = 0;
        }

        const totalAmount = this.InvFilter.allInvData.reduce(
            (sum, inv) => sum + (inv.Amount || 0),
            0
        );

        const totalNoOfInv = this.InvFilter.allInvData.length;

        this.InvFilter.totalAmount = totalAmount.toFixed(2) || 0;
        this.InvFilter.totalNoOfInvoices = totalNoOfInv || 0;
    }
    handleInvChange(event) {
        this.InvFilter[event.target.name] = event.target.value;
        this.InvFilter.srchVal = '';
        this.getInvoiceData();
    }
    handleInvSerch(event) {
        const txt = event.target.value;
        if (txt.length > 0) {
            this.InvFilter.srchVal = txt;
            var ordUpdate = [];
            for (let i = 0; i < this.InvFilter.originalInvData.length; i++) {
                const inv = this.InvFilter.originalInvData[i];
                if ((inv.accName && inv.accName.toLowerCase().indexOf(txt.toLowerCase()) !== -1) || 
                  (inv.customerCode && inv.customerCode.toLowerCase().indexOf(txt.toLowerCase()) !== -1)  ) {
                    ordUpdate.push(inv);
                }
            }
            this.InvFilter.allInvData = ordUpdate;
        } else {
            this.InvFilter.allInvData = this.InvFilter.originalInvData;
        }
        this.getInvoiceSumary();
    }
    expenseData() {
        const today = new Date();

        // Get the first and last day of the current year
        const firstDate = new Date(today.getFullYear(), 0, 1);  // January 1st
        const lastDate = new Date(today.getFullYear(), 11, 31); // December 31st

        // Format date correctly without timezone issues
        const formatDate = (date) => {
            const year = date.getFullYear();
            const month = String(date.getMonth() + 1).padStart(2, '0'); // Ensure two digits
            const day = String(date.getDate()).padStart(2, '0'); // Ensure two digits
            return `${year}-${month}-${day}`;
        };

        this.expFilter.fromDate = formatDate(firstDate); // 'YYYY-MM-DD'
        this.expFilter.toDate = formatDate(lastDate); // 'YYYY-MM-DD'
        this.expFilter.status = 'All';

        this.getExpenseData();
    }

    getExpenseData() {
        this.isSubPartLoad = true;
        const { status, fromDate, toDate } = this.expFilter;
        EXP_DATA({
            ids: this.selectedId,
            status: status,
            frmDate: fromDate,
            toDate: toDate
        })
            .then(result => {
                this.expFilter.statusVal = result.statusOptions
                const dt = result.dateWiseExpenses;
                var expDt = [];
                for (let i = 0; i < dt.length; i++) {
                    const exp = dt[i].expData[0];
                    expDt.push(exp);
                }
                this.expFilter.allExpData = expDt
                this.isexpData = this.expFilter.allExpData.length != 0 ? true : false;
                this.expFilter.originalExpData = expDt;
                this.isSubPartLoad = false;
            })
            .catch(error => {
                console.error(error);
                this.isSubPartLoad = false;
            });
    }
    handleExpChange(event) {
        this.expFilter[event.target.name] = event.target.value;
        this.getExpenseData();
    }
    getUserDetails() {
        setTimeout(() => {
            const childComp = this.template.querySelector('c-employee-record-view-form');
            if (childComp) {
                childComp.getAllData();
            } else {
                console.error('Child component not found');
            }
        }, 0);
    }
    handleAttChange(event) {
        this.attFilter.srchVal = '';
        this.attFilter[event.target.name] = event.target.value;
        this.getUserAttendance();
    }
    attandanceData() {
        const today = new Date();
        const firstDate = new Date(today.getFullYear(), today.getMonth(), 1);

        const formatDate = (date) => date.toLocaleDateString('en-CA');
        this.attFilter.fromDate = formatDate(firstDate);
        this.attFilter.toDate = formatDate(today);
        this.attFilter.status = 'All';
        this.getUserAttendance();
    }
    getUserAttendance() {
        this.isSubPartLoad = true;
        const { fromDate, toDate, status } = this.attFilter;
        ATT_DATA({
            ids: this.selectedId,
            frmDate: fromDate,
            toDate: toDate,
            status: status
        })
            .then(result => {
                this.attFilter.allAttData = result.formattedUsersData;
                this.isAttanData = this.attFilter.allAttData.length != 0 ? true : false;
                this.isSubPartLoad = false;
            })
            .catch(error => {
                console.error(error);
                this.isSubPartLoad = false;
            });
    }
    handleRepeatDays() {
        this.isSubPartLoad = true;
        REPEAT_DAYS({
            ids: this.selectedId,
        })
            .then(result => {
                this.isSubPartLoad = false;
                this.beatPlan = result.jDbeatList;
                this.junctionBeats = result.JunctionList;
                this.HolidayList = result.HolidayList;
                this.mapBeatPlansToCalendar();
            })
            .catch(error => {
                console.error(error);
                this.isSubPartLoad = false;
            });
    }
    Incentives() {
        const today = new Date();

        // Get the first and last day of the current year
        const firstDate = new Date(today.getFullYear(), 0, 1);  // January 1st
        const lastDate = new Date(today.getFullYear(), 11, 31); // December 31st

        // Format date correctly without timezone issues
        const formatDate = (date) => {
            const year = date.getFullYear();
            const month = String(date.getMonth() + 1).padStart(2, '0'); // Ensure two digits
            const day = String(date.getDate()).padStart(2, '0'); // Ensure two digits
            return `${year}-${month}-${day}`;
        };

        this.InceFilter.fromDate = formatDate(firstDate); // 'YYYY-MM-DD'
        this.InceFilter.toDate = formatDate(lastDate); // 'YYYY-MM-DD'

        this.getIncentivesData();
    }
    getIncentivesData() {
        this.isSubPartLoad = true;
        const { fromDate, toDate } = this.InceFilter;
        INC_DATA({
            ids: this.selectedId,
            fromDt: fromDate,
            toDate: toDate
        })
            .then(result => {
                this.isSubPartLoad = false;
                this.InceFilter.allInvData = result.agg;
                this.isIncenTtData = this.InceFilter.allInvData.length != 0 ? true : false;
            })
            .catch(error => {
                console.error(error);
                this.isSubPartLoad = false;
            })
    }
    handleIncChange(event) {
        this.InceFilter[event.target.name] = event.target.value;
        this.getIncentivesData();
    }
    handlePjpDateChange(event) {
        const selectedDate = new Date(event.target.value);
        const currentDate = new Date();

        const currentYear = currentDate.getFullYear();
        const currentMonth = currentDate.getMonth();

        const selectedYear = selectedDate.getFullYear();
        const selectedMonth = selectedDate.getMonth();

        if (selectedYear === currentYear && selectedMonth === currentMonth) {
            this.PJPStartDate = event.target.value;

            this.calenderBeat.Start_Month__c = event.target.value;
            const recordInput = {
                fields: this.calenderBeat
            }
            updateRecord(recordInput)
                .then((result) => {
                    console.log(result);
                    this.mapBeatPlansToCalendar();
                })
                .catch((error) => {
                    // Handle error in record creation

                    console.error('Error creating record:', error);
                });
        } else {
            this.PJPStartDate = null;
            this.genericToastDispatchEvent('', 'Please select a date within the current month and not in the past.', 'warning');
            event.target.setCustomValidity("Please select a date within the current month.");
        }

        event.target.reportValidity();
    }
    handlePJPNextDateChange(event) {
        const selectedDate = new Date(event.target.value); // Get selected date
        const today = new Date(); // Get current date
        today.setHours(0, 0, 0, 0); // Normalize to remove time for comparison

        const currentYear = today.getFullYear();
        const currentMonth = today.getMonth();

        const selectedYear = selectedDate.getFullYear();
        const selectedMonth = selectedDate.getMonth();

        // Check if selected date is today or in the future AND within the same month
        if (selectedDate >= today && selectedYear === currentYear && selectedMonth === currentMonth) {
            console.log("Valid date selected:", selectedDate);
            this.PJPNextStartDate = event.target.value;
            this.calenderBeat.Next_Start_Date__c = event.target.value;
            const recordInput = {
                fields: this.calenderBeat
            }
            updateRecord(recordInput)
                .then((result) => {
                    console.log(result);
                    this.mapBeatPlansToCalendar('');
                })
                .catch((error) => {
                    // Handle error in record creation
                    this.genericToastDispatchEvent('', 'Error creating record:' + error, 'error');
                    console.error('Error creating record:', error);
                    event.target.reportValidity();
                });
            // Proceed with further processing
        } else {
            this.genericToastDispatchEvent('', 'Please select a date within the current month. Dates in the past or future months are not allowed.', 'warning');
            this.PJPNextStartDate = null;
            event.target.setCustomValidity("Please select a valid date within the current month.");
            console.error("Invalid date: Please select a date within the current month. Dates in the past or future months are not allowed.");
            event.target.value = ''; // Clear the invalid input
        }
        event.target.reportValidity();
    }
    getPrimaryCustomerAssignment() {
        console.log('entered-22---');
        setTimeout(() => {
            const childComp = this.template.querySelector('c-customer-assignment');
            if (childComp) {
                childComp.refreshData();
            } else {
                console.error('Child component not found');
            }
        }, 0);
    }
    getSecoundaryCustomerAssignment() {
        setTimeout(() => {
            const childComp = this.template.querySelector('c-secondary-assignment');
            if (childComp) {
                childComp.refreshData();
            } else {
                console.error('Child component not found');
            }
        }, 0);
    }

    reshareAccountAccess() {
       this.isSharing = true;
        shareAccounts({
            recId: this.employeeId,
            objectName: this.objectName,
        })
        .then(result => {
            console.log(result);
            this.isSharing = false;
            this.genericToastDispatchEvent(
                'Success',
                'Customers shared successfully',
                'success'
            );
        })
        .catch(error => {
            console.error(error);
            this.isSharing = false;
            this.genericToastDispatchEvent(
                'Error',
                error?.body?.message || 'An unexpected error occurred',
                'error'
            );
        });
    }

    /**Visit Summary */
    visitSummaryData() {
        const today = new Date();
        const firstDate = today;
        const lastDate = today;
        const formatDate = (date) => date.toLocaleDateString('en-CA');
        this.visitSummary.fromDate = formatDate(firstDate);
        this.visitSummary.toDate = formatDate(lastDate);
        this.getvisitSummaryData();
    }
    getvisitSummaryData() {
        this.isSubPartLoad = true;
        const {fromDate, toDate } = this.visitSummary;
        VISIT_SUMMARY({
            userId: this.selectedId,
            startDate: fromDate,
            endDate: toDate
        })
        .then(result => {

            // Assign directly from response map
            this.visitSummary.DailyOutletSummary = result|| [];


            this.visitSummary.showDailyOutletSummary = this.visitSummary.DailyOutletSummary.length > 0;
        
            if (this.visitSummary && this.visitSummary.DailyOutletSummary) {
                
                this.visitSummary.outletCount = this.visitSummary.DailyOutletSummary.length;
 
            } else {
                this.visitSummary.outletCount = 0;
            }
    
            this.isSubPartLoad = false;
        })
        .catch(error => {
            console.error(error);
            this.isSubPartLoad = false;
        });
    }
    handleVisitSummaryChange(event) {
        this.visitSummary[event.target.name] = event.target.value;
        this.getvisitSummaryData();
    }
    


    /**Helper Methods */
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
    genericToastDispatchEvent(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant
            })
        );
    }

    handleFromDate(event) {
        this.fromDate = event.target.value;
    }

    handleToDate(event) {
        this.toDate = event.target.value;
    }

    async loadVisits() {
    if (!this.fromDate || !this.toDate) {
        alert('Please select both From Date and To Date');
        return;
    }
    console.log('Employee Id is ', this.recordId);

    this.isSubPartLoad = true; // show loader

    try {
        const data = await getVisits({
            ids: this.selectedId,
            fromDate: this.fromDate,
            toDate: this.toDate
        });
        console.log('Fetched visits data:', JSON.stringify(data));

        // Group visits by lat/lng
        const grouped = {};
        data
            .filter(v => v.ClockIn_Latitude__c && v.Clockin_Longitude__c)
            .forEach(v => {
                const key = v.ClockIn_Latitude__c + ',' + v.Clockin_Longitude__c;
                if (!grouped[key]) {
                    grouped[key] = [];
                }
                grouped[key].push(v);
            });

        // Build markers from grouped data
        this.mapMarkers = Object.keys(grouped).map(key => {
            const [lat, lng] = key.split(',');
            const visits = grouped[key];
            return {
                location: {
                    Latitude: parseFloat(lat),
                    Longitude: parseFloat(lng)
                },
                title:visits.map(v => v.Name).join(', '),
                description: visits
                    .map(v => `Visit Date: ${v.Visit_Date__c}, Visit for: ${v.Visit_for__c}`)
                    .join('<br/>')
            };
        });

        console.log('Final mapMarkers:', JSON.stringify(this.mapMarkers));
        console.log('Number of markers:', this.mapMarkers.length);
    } catch (error) {
        console.error('Error fetching visits:', error);
        this.mapMarkers = [];
    } finally {
        this.isSubPartLoad = false; // hide loader after success/error
    }
    }



}