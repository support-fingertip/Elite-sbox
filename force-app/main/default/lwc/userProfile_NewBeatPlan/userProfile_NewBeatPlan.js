import { LightningElement,api,track } from 'lwc';
import { createRecord } from "lightning/uiRecordApi";
// import JnBEAT_OBJECT from '@salesforce/schema/Junction_Beat__c'; 
import CHILD_OBJECT from '@salesforce/schema/Child_beat__c'; 
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import ACC_DATA from '@salesforce/apex/userProfileLWC.getAcc';

export default class UserProfile_NewBeatPlan extends LightningElement {
    
    @api selectedUser;
    @api isDesktop;
    @api isPhone;
    @track junDta = {
        // Visit_Date__c : new Date().toISOString().split('T')[0],
        Date__c : new Date().toISOString().split('T')[0],
       // Account__c : '',
        OwnerId : ''
    }

    dateError = false; dateErrorMessage = ''; saveNew = false; isButton = false;
    @track accounts = []; // Full account list
    @track filteredAccounts = []; // Filtered account list
    @track searchKey = ''; // Input search text
    @track showDropdown = false; // Dropdown visibility
    connectedCallback(){
       // this.getData();
        this.junDta = {
            // Visit_Date__c : new Date().toISOString().split('T')[0],
            Date__c : new Date().toISOString().split('T')[0],
           // Account__c : '',
            OwnerId : this.selectedUser.id
        }
    } 

    getData(){
        
        ACC_DATA({})
        .then(result =>{
            console.log(result);
            this.accounts = result.acc;
            this.filteredAccounts = result.acc;
            
        })
        .catch(error =>{
            console.log(error);
        });
    }
    changeValue(event) {
        const selectedDate = new Date(event.target.value);
        const today = new Date();
        
        const selectedDateOnly = new Date(selectedDate.getFullYear(), selectedDate.getMonth(), selectedDate.getDate());
        const firstDayOfMonth = new Date(today.getFullYear(), today.getMonth(), 1);
        const lastDayOfMonth = new Date(today.getFullYear(), today.getMonth() + 1, 0);

        if (selectedDateOnly < firstDayOfMonth || selectedDateOnly > lastDayOfMonth) {
            this.dateError = true;
            this.dateErrorMessage = 'Please select a date within the current month.';
            this.junDta.Date__c = '';
            // this.junDta.Visit_Date__c = ''; 
        } else {
            this.dateError = false;
            this.dateErrorMessage = '';
            this.junDta.Date__c = event.target.value;
            // this.junDta.Visit_Date__c = event.target.value;
        }
    }
    handleAccountSearch(event) {
        this.searchKey = event.target.value;
        if (this.searchKey.length != 0) {
            var storeData = [];
            for (let i = 0; i < this.accounts.length; i++) {
                const acc = this.accounts[i];
                if ((acc.Name && acc.Name.toLowerCase().indexOf(this.searchKey.toLowerCase()) !== -1)) {
                    storeData.push(acc);
                }
            }
            this.filteredAccounts = storeData;
           // this.filteredAccounts = this.accounts.filter(acc => acc.Name.toLowerCase().includes(this.searchKey.toLowerCase()));
            this.showDropdown = this.filteredAccounts.length > 0;
        } else {
            this.showDropdown = false;
        }
    }

    handleBlur(){
        setTimeout(() => {
            this.showDropdown = false;
        }, 1000);
    }
    handleAccountSelect(event) {
        const selectedElement = event.target.closest("li"); // Ensure we get the <li> element
        if (selectedElement) {
            this.junDta.Account__c = selectedElement.dataset.id;
            this.searchKey = selectedElement.dataset.name;
            this.showDropdown = false;
        }
    }
    
    handleSave(){
        // if(this.junDta.Account__c == ''){
        //     this.genericToastDispatchEvent('Error','Please select an account','error');
        //     return;
        // }
        // else if(this.junDta.Visit_Date__c == ''){
        //     this.genericToastDispatchEvent('Error','Please select date','error');
        //     return;
        // }
        if(this.junDta.Date__c == ''){
            this.genericToastDispatchEvent('Error','Please select date','error');
            return;
        }
        this.saveNew = false;
        this.saveData();
    }
    handleSaveNew(){
        // if(this.junDta.Account__c == ''){
        //     this.genericToastDispatchEvent('Error','Please select an account','error');
        //     return;
        // }
        // else if(this.junDta.Visit_Date__c == ''){
        //     this.genericToastDispatchEvent('Error','Please select date','error');
        //     return;
        // }
        if(this.junDta.Date__c == ''){
            this.genericToastDispatchEvent('Error','Please select date','error');
            return;
        }
        this.saveNew = true;
        this.saveData();
    }
    resetNew(){
        this.junDta = {
            // Visit_Date__c : new Date().toISOString().split('T')[0],
            Date__c : new Date().toISOString().split('T')[0],
            //Account__c : '',
            OwnerId : this.selectedUser.id
        }
        this.searchKey = '';
        this.dateError = false; this.dateErrorMessage = '';
    }
    saveData(){
        this.isButton = true;
        const fields= this.junDta;
        const recordInput = { apiName: CHILD_OBJECT.objectApiName, fields };
        createRecord(recordInput)
            .then((result) => {
                console.log(result);
                if(this.saveNew){
                    this.resetNew();
                }
                this.isButton = false;
                const  message = { 
                    message: 'saveBeatPlan' ,
                    saveNew : this.saveNew
                };
                this.genericDispatchEvent(message);                
            })
            .catch((error) => {
                console.error('Error creating record:', error);
                if(error && error.body && error.body.output && error.body.output.errors && error.body.output.errors[0] && error.body.output.errors[0].message){
                    const msg = error.body.output.errors[0].message + '. Select other date.';
                    this.genericToastDispatchEvent('Error',msg,'error');
                }
                this.isButton = false;
            });
    }
    handleClose() {
        const  message = { 
            message: 'beatPopClose' ,
            saveNew : this.saveNew
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
    genericToastDispatchEvent(title,message,variant){
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant
            })
        );
    }
}