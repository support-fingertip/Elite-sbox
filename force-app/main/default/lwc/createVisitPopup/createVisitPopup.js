import { LightningElement,api,track,wire } from 'lwc';
import VisitData from '@salesforce/apex/beatPlannerlwc.getVisitCreateData';
import { createRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getComptitionData from '@salesforce/apex/beatPlannerlwc.getComptitionData';

//fields
import VISIT_OBJECT from '@salesforce/schema/Visit__c';

export default class CreateVisitPopup extends LightningElement {

    isSearchValueSelected = false; searchPlaceHolder; searchLabel; isValueSearched = false; searchValueName = '';
    headerVisit = '';

    @api recordId;
    @api completeVisit;
    @api newVisitCreate;
    @api reshedule;
    @api dailyLogId;
    @api isDesktop;
    @api isPrimaryCustomer;
    pickData; 
    @api currentVisitData;
    isDisabled = false;
    isOthereVisit = false;
    @track objData = {
        primaryCustomers : [],
        secoundaryCustomers : [],
        searchItems : [],
        searchNameData : []
    }
    @track visitData = {
        Visit_for__c : 'Primary Customer',
        Status__c : 'Planned',
        Lead__c : '',
        Distributor__c : '',
        Dealer__c : '',
        Account1__c : '',
        Daily_Log__c : '',
        Comments__c : '',
        Other_Visit__c  : '',
        PostPoned_Start_Time__c: null,
        Missed_PostPone_Reason__c : '',
        Approval_Status__c : 'Approved',
        Date__c : this.getDateValues(),
        Planned_Start_Time__c : this.getDateValues()
    };
    isPhotoTaken = false;
    containerClass;
    isLoading = false;
    loadinScreenSize ='2';
    isCompetitonExisted = false;



    getDateValues() {
        const now = new Date();
        return now.toISOString();
    }

    //On loading this method will be called
    connectedCallback(){
        if (!navigator.onLine) {
            this.genericDispatchEvent('Error', 'No internet connection. Please check your network and try again.', 'error');
            return;
        }
        if(this.newVisitCreate){
            this.headerVisit = 'New Visit' ;
            this.getVisitData();
        }
        else if(this.reshedule){
            this.headerVisit = 'Reshedule Visit' ;
        }
        else if(this.completeVisit){
            this.headerVisit = 'Complete Visit' ;
            this.isCompetitonExisted = true;
           /* if(this.isPrimaryCustomer)
            {
                this.getComptitionData();
            }
            else
            {
                this.isCompetitonExisted = true;
            }*/
           
        }
        this.containerClass = this.isDesktop ? 'slds-modal__container ' : '';
        this.loadinScreenSize = this.isDesktop ? 2 : 3;
        
    }

    //Get Visit Data
    getVisitData() {
        if (!navigator.onLine) {
            this.genericDispatchEvent('Error', 'No internet connection. Please check your network and try again.', 'error');
            return;
        }
        this.isLoading = true;
        VisitData({ })
        .then(result => {
            this.pickData = result.visitTypes;
            this.objData.primaryCustomers = result.primaryCustomers;
            this.objData.secoundaryCustomers = result.secoundaryCustomers;
            this.objData.searchItems = this.objData.primaryCustomers;
            this.isSearchValueSelected = true;
            this.searchPlaceHolder = 'Search Primary Customer...';
            this.searchLabel = 'Primary Customer';
            this.isLoading = false;
        })
        .catch(error => {
            console.error(error);
        });
    }
    //get Competiton Data
    getComptitionData() {
        if (!navigator.onLine) {
            this.genericDispatchEvent('Error', 'No internet connection. Please check your network and try again.', 'error');
            return;
        }
        this.isLoading = true;
        getComptitionData({visitId: this.recordId})
        .then(result => {
            this.isCompetitonExisted = result.length > 0 ? true : false;
            this.isLoading = false;
        })
        .catch(error => {
            console.error(error);
        });
    }

    //When Visit For Chnaged
    handleChange(event) {
        this.visitData[event.currentTarget.name] = event.detail.value;
        if(event.currentTarget.name === "Visit_for__c"){
            
            this.resetData();
            if(event.detail.value == 'Primary Customer'){
                this.objData.searchItems = this.objData.primaryCustomers;
                this.isSearchValueSelected = true;
                this.searchPlaceHolder = 'Search Primary Customer....';
                this.searchLabel = 'Primary Customer';
            }
            else if(event.detail.value == 'Secondary Customer'){

                this.objData.searchItems = this.objData.secoundaryCustomers;
                this.isSearchValueSelected = true;
                this.searchPlaceHolder = 'Search Secondary Customer....';
                this.searchLabel = 'Secondary Customer';
            }
            else if(event.detail.value == 'Other'){
                this.isOthereVisit = true;
            }
  
        }
    }

    //Customer Search 
    handleSearch(event){
        this.searchValueName = event.target.value;
        // console.log(userName);
        if(this.searchValueName){
            this.searchText();
        }else{
            this.isValueSearched = false;
            this.visitData.Account1__c = '';
        } 
 
    }
    searchText(){
        let objData = this.objData.searchItems;
        let storeData = [];
        for (let i = 0; i < objData.length; i++) {
            const objName = objData[i];
            if ((objName.Name && objName.Name.toLowerCase().indexOf(this.searchValueName.toLowerCase()) !== -1)) {
                storeData.push(objName);
            }
        }
        this.isValueSearched = storeData != 0 ? true : false;
        this.objData.searchNameData = storeData;
    }

    //On select of Customer 
    selectObjName(event){
        const apiFieldName = this.visitData.Visit_for__c; 
        if(apiFieldName == 'Primary Customer'){
            this.visitData.Account1__c = event.currentTarget.dataset.id;
        }
        else if(apiFieldName == 'Secondary Customer'){
            this.visitData.Account1__c = event.currentTarget.dataset.id;
        }
        this.searchValueName = event.currentTarget.dataset.name;
        this.isValueSearched = false;
    }

    //Close Visit
    closeVisit(){
        const event = new CustomEvent('myvisitclick', {
            detail: {message : 'Close'}
        });
        this.dispatchEvent(event);
    }
  
    //Save Visit
    saveVisit(){
        if (!navigator.onLine) {
            this.genericDispatchEvent('Error', 'No internet connection. Please check your network and try again.', 'error');
            return;
        }
        if(this.completeVisit){
           
            if(this.visitData.Comments__c == ''){
                this.showFieldError('visitComments');
                this.genericDispatchEvent('Error','Please fill in all the mandatory fields','Error');
                return;
            }
            if(!this.isCompetitonExisted)
            {
                this.genericDispatchEvent('Error','Please complete the competitor activity to complete the visit','Error');
                return;  
            }
            this.isDisabled = true;
            this.isLoading = true;
            const message = new CustomEvent('myvisitclick', {
                detail: {
                    message: 'createNewVisit' ,
                    Comment: this.visitData.Comments__c
                }
            });
            this.dispatchEvent(message);

        }else if(this.newVisitCreate){
            this.creatingNewVisit();
        }
        else if(this.reshedule){
            if(this.visitData.Missed_PostPone_Reason__c == ''){
                this.showFieldError('newVisitFields');
                this.genericDispatchEvent('Error','Please fill in all the mandatory fields','Error');
                return;
            }
            else if(!this.visitData.PostPoned_Start_Time__c)
            {
                this.showFieldError('newVisitFields');
                this.genericDispatchEvent('Error','Please fill in all the mandatory fields','Error');
                return;
            }


            this.isDisabled = true;
            this.isLoading = true;
               let currentVisitData = this.currentVisitData;
               console.log('currentVisitData--'+currentVisitData);
            const message = new CustomEvent('myvisitclick', {
                detail: {
                    message: 'missedReason',
                    missedReason: this.visitData.Missed_PostPone_Reason__c,
                    missedDate:this.visitData.PostPoned_Start_Time__c,
                    accountId:currentVisitData.acccountId,
                    plannedDate:this.getDateValues(),
                    dailyLogId:currentVisitData.dailyLogId,
                    visitfor:currentVisitData.visitTypes,
                    beatId:currentVisitData.visitPlanId,
                    beatItem:currentVisitData.beatItemId
                }
            });
            this.dispatchEvent(message);
        }
    }

    //Method to create new visit
    creatingNewVisit(){
        if (!navigator.onLine) {
            this.genericDispatchEvent('Error', 'No internet connection. Please check your network and try again.', 'error');
            return;
        }
        this.visitData.Daily_Log__c = this.dailyLogId;
        const fields= this.visitData;
        if(!fields.Visit_for__c && !fields.Date__c)
        {
            this.showFieldError('newVisitFields');
            this.genericDispatchEvent('Error','Please fill in all the mandatory fields','Error');
            return;
        }
        else if(fields.Visit_for__c != 'Other' && (!fields.Account1__c || !this.searchValueName ))
        {
            this.showFieldError('newVisitFields');
            this.genericDispatchEvent('Error','Please select '+fields.Visit_for__c ,'Error');
            return;           
        }
        else if(fields.Visit_for__c == 'Other' && !fields.Other_Visit__c){
           
            this.showFieldError('newVisitFields');
            this.genericDispatchEvent('Error','Please fill in all the mandatory fields','Error');
            return;
           
        }
        this.isDisabled = true;
        
        const recordInput = { apiName: VISIT_OBJECT.objectApiName, fields };
        createRecord(recordInput)
        .then((result) => {
            const event = new CustomEvent('myvisitclick', {
                detail: {message : 'Save'} 
            });
            // Dispatches the event.
            this.isDisabled = false;
            this.dispatchEvent(event);
                               
        })
        .catch((error) => {
            // Handle error in record creation
            const event = new CustomEvent('myvisitclick', {
                detail: {message : 'Save',error:error} 
            });
            // Dispatches the event.
            this.isDisabled = false;
            this.dispatchEvent(event);
            console.error('Error creating record:', error);
        });
    }
    
    /**Visit Check out */
    onCommentChange(event){
        this.visitData[event.currentTarget.name] = event.detail.value;
    }
    handleOrderScreen(event){
        const msg = event.detail;
        if(msg.message == 'camerScreen'){
            this.isPhotoTaken = msg.isPhotoTaken;
        }
    }

    /**Helper Methods */
    resetData(){
        this.searchValueName = '';
        this.Other_Visit__c = '';
        this.isValueSearched = false;
        this.visitData.Account1__c = '';
        this.isOthereVisit = false;
        this.isSearchValueSelected = false;
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
    handleOnBlur(){
        setTimeout(() => {
            this.isValueSearched = false;
        }, 1000);
    }
    showFieldError(fieldPrefix) {
        const inputFields = this.template.querySelectorAll(`[data-id^="${fieldPrefix}"]`); 
        if (inputFields.length > 0) {
            inputFields.forEach(input => {
                input.reportValidity(); // Show validation error
            });
        }
    }
}