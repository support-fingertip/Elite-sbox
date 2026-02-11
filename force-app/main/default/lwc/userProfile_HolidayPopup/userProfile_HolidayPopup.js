import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import HOLIDAY_OBJ from '@salesforce/schema/Holiday__c';
import { createRecord } from "lightning/uiRecordApi";

export default class UserProfile_HolidayPopup extends LightningElement {

    @api isDesktop;
    @api selectedUser;
    @api isPhone;
    @api regionOptions;

    dateErrorMessage = ''; dateError = false; saveNew = false; isButton = false;
    @track holidayData = {
        Date__c: new Date().toISOString().split('T')[0],
        Name: '',
        Region__c: '',
        Description__c: '',
        OwnerId: ''
    }
    @track selRegions = [];
    /*    regionOptions = [
          { label: 'North', value: 'North' },
          { label: 'South', value: 'South' },
          { label: 'East', value: 'East' },
          { label: 'West', value: 'West' }
      ]; */

    connectedCallback() {
        this.holidayData.OwnerId = this.selectedUser.id;
    
        // You can map over this list and create the desired format
        this.regionOptions = this.regionOptions.map((region, index) => {
            return {
                label: region,
                value: region // Use regionCodes array to assign value
            };
        });
    }

    changeValue(event) {
        this.holidayData[event.target.name] = event.target.value;
    }
    dateChangeValue(event) {
        const selectedDate = new Date(event.target.value);
        const today = new Date();

        const selectedDateOnly = new Date(selectedDate.getFullYear(), selectedDate.getMonth(), selectedDate.getDate());
        const firstDayOfMonth = new Date(today.getFullYear(), today.getMonth(), 1);
        const lastDayOfMonth = new Date(today.getFullYear(), today.getMonth() + 1, 0);

        /*  if (selectedDateOnly < firstDayOfMonth || selectedDateOnly > lastDayOfMonth) {
             this.dateError = true;
             this.dateErrorMessage = 'Please select a date within the current month.';
             this.holidayData.Date__c = '';
             // this.junDta.Visit_Date__c = ''; 
         } else { */
        this.dateError = false;
        this.dateErrorMessage = '';
        this.holidayData.Date__c = event.target.value;
        // this.junDta.Visit_Date__c = event.target.value;
        // }
    }
    handleSave() {
        if (this.holidayData.Date__c == '') {
            this.genericToastDispatchEvent('Error', 'Please select date', 'error');
            return;
        }
        if (this.holidayData.Name == '') {
            this.genericToastDispatchEvent('Error', 'Please Enter name', 'error');
            return;
        }
        this.holidayData.Region__c = this.holidayData.Region__c.join(';');
        this.saveNew = false;
        this.saveData();
    }
    handleSaveNew() {

        if (this.holidayData.Date__c == '') {
            this.genericToastDispatchEvent('Error', 'Please select date', 'error');
            return;
        }
        if (this.holidayData.Name == '') {
            this.genericToastDispatchEvent('Error', 'Please Enter name', 'error');
            return;
        }
        this.holidayData.Region__c = this.holidayData.Region__c.join(';');
        this.saveNew = true;
        this.saveData();
    }
    saveData() {
        alert(JSON.stringify(this.holidayData));
        this.isButton = true;
        const fields = this.holidayData;
        const recordInput = { apiName: HOLIDAY_OBJ.objectApiName, fields };

        createRecord(recordInput)
            .then((result) => {
                console.log(result);
                if (this.saveNew) {
                    this.resetNew();
                }
                this.isButton = false;
                const message = {
                    message: 'saveHolidayPlan',
                    saveNew: this.saveNew
                };
                this.genericDispatchEvent(message);
            })
            .catch((error) => {
                console.error('Error creating record:', error);
                if (error && error.body && error.body.output && error.body.output.errors && error.body.output.errors[0] && error.body.output.errors[0].message) {
                    const msg = error.body.output.errors[0].message + '. Select other date.';
                    this.genericToastDispatchEvent('Error', msg, 'error');
                }
                this.isButton = false;
            });
    }
    resetNew() {
        this.holidayData = {
            Date__c: new Date().toISOString().split('T')[0],
            Name: '',
            Region__c: '',
            Description__c: '',
            OwnerId: this.selectedUser.id
        }
        this.dateError = false; this.dateErrorMessage = '';
    }

    handleClose() {
        const message = {
            message: 'HolidayPopClose',
            saveNew: this.saveNew
        };
        this.genericDispatchEvent(message);
    }

    genericDispatchEvent(message) {
        // Creating a custom event with a payload (optional)
        const event = new CustomEvent('mycustomevent', {
            detail: message
        });

        // Dispatching the event
        this.dispatchEvent(event);
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
}