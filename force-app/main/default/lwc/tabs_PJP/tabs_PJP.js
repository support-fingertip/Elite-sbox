import { LightningElement,track,api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

import BEAT_DATA from '@salesforce/apex/userProfileLWC.beatPlan';

export default class Tabs_PJP extends NavigationMixin(LightningElement) {

    @api isDesktop;
    @api isPhone;
    @api selectedUserId

    originalcalendarDaysData = [];
    @track calendarDays = [];
    @track currentMonth;
    @track currentYear;
    today = new Date();

    isSubPartLoad = false;

    connectedCallback(){
        this.generateCalendar();
        this.getBeatPlanData(this.selectedUserId);
    }

    getBeatPlanData(selectedUserId){
        this.isSubPartLoad = true;
        BEAT_DATA({
         ids : selectedUserId
         })
         .then(result => {
             this.beatPlan = result.Visit;
             if(this.beatPlan && this.beatPlan.length != 0){
                 this.mapBeatPlansToCalendar(this.beatPlan);
             }else{
                 this.calendarDays = this.originalcalendarDaysData;
             }
             this.isSubPartLoad = false;
         })
         .catch(error => {
             console.error(error);
             this.isPageLoaded = false;
             this.isSubPartLoad = false;
         });
     }

     mapBeatPlansToCalendar(beatPlans) {
        
        this.calendarDays = this.calendarDays.map(dayObj => {
            if (dayObj.date) {
                let matchingRecords = beatPlans.filter(record => record.Planned_start_Date__c === dayObj.formattedDate);
                return { 
                    ...dayObj, 
                    records: matchingRecords, 
                    visibleRecords: matchingRecords.slice(0, 4), 
                    showAll: false, 
                    hasMore: matchingRecords.length > 4 
                };
            }
            return dayObj;
        });
    } 

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

        // Generate URL for the record
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

    generateCalendar() {
        const year = this.today.getFullYear();
        const month = this.today.getMonth();
        const firstDay = new Date(year, month, 1);
        const lastDay = new Date(year, month + 1, 0);
        const dayNames = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];
        const startDayOfWeek = firstDay.getDay();

        let daysArray = [];

        // Fill empty slots for days before the first day of the month
        for (let i = 0; i < startDayOfWeek; i++) {
            daysArray.push({ date: null, formattedDate: '', records: [] });
        }

        // Fill in the actual days of the month
        for (let day = 1; day <= lastDay.getDate(); day++) {
            let fullDate = new Date(year, month, day);
            let formattedDate = fullDate.toISOString().split('T')[0]; // Format: YYYY-MM-DD
            let dayName = dayNames[fullDate.getDay()];
            daysArray.push({ 
                date: fullDate, 
                formattedDate, 
                records: [], 
                dayNumber: day,
                dayName: dayName 
            });
        }

        this.calendarDays = daysArray;
        this.originalcalendarDaysData = daysArray;
        const today = new Date();
        const monthNames = [
            'January', 'February', 'March', 'April', 'May', 'June', 
            'July', 'August', 'September', 'October', 'November', 'December'
        ];

        this.currentMonth = monthNames[today.getMonth()]; // Get month name
        this.currentYear = today.getFullYear(); 
    }
}