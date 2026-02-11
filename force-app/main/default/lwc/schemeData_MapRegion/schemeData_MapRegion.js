import { LightningElement,api, track } from 'lwc';

//Apex class
import MAPREGION_DATA from '@salesforce/apex/SchemeLwc.mapRegion';
import SAVEMAP_DATA from '@salesforce/apex/SchemeLwc.saveMapping';

export default class SchemeData_MapRegion extends LightningElement {

    @api schemeId;
    @api schemeName;
    @api proCatId;
    @api proCatName;
    @api isArea;
    @api isCustomer;
    @api isRegion;
    isPageLoaded = false;

    @track isDisable = {
        allFields : true
    };

    @track dataVal ;
    @track values = {
        proName : '',
        proId : '',
        isProVal : false,
        proData : [],

        accName : '',
        accId : '',
        isAccVal : false,
        accData : [],

        regName : '',
        regId : '',
        isRegVal : false,
        regData : [],

        divName : '',
        divId : '',
        isDivVal : false,
        divData : [],

        areaName:'',
        areaId:'',
        isAreaVal:false,
        areaData:[],

        search : ''
    }
    selectedArea = 'All'; selectedRegion = 'All';
    formattedRegionData = []; formattedAreaData = [];
    delete = [];originalData = [];
    connectedCallback(){
        this.getDataOnload();
    }

    getDataOnload(){
        this.isPageLoaded = true;
        MAPREGION_DATA({
            proId:this.proCatId,
            schemeId : this.schemeId,
            isRegion:this.isRegion,
            isCustomer: this.isCustomer,
            isArea : this.isArea
        })
        .then(result => {
            this.dataVal = [];
            if(this.isArea){
                this.dataVal = (result.area);
            }
            else if(this.isRegion){
                this.dataVal = (result.region);
            }
            else if(this.isCustomer){
                this.dataVal = (result.acc);
                this.formattedRegionData = result.formattedRegionData; 
                this.formattedAreaData = result.formattedAreaData;
            }
            this.originalData = this.dataVal;
            this.isDisable.allFields = false;
            this.isPageLoaded = false;
        })
        .catch(error => {
            this.isDisable.allFields = true;
            this.isPageLoaded = false;
            console.log(error);
        });
    }
    handleSearch(event){
        const val = event.target.value;
        this.values.search = val;
        if(val != ''){

            var serchedDta = this.originalData.filter(obj => obj.name && obj.name.toLowerCase().includes(val.toLowerCase()));
            //this.searchText(this.originalData,val);
            this.dataVal = serchedDta;
        }else{
            this.dataVal = this.originalData;
        }
    }

    searchText(objData,serchTxt){
        if(objData == undefined) return;
        return objData.filter(obj => obj.Name && obj.Name.toLowerCase().includes(serchTxt.toLowerCase()));
    }

    handleCheckBoxValue(event) {
        const index = parseInt(event.currentTarget.dataset.index, 10);
        this.dataVal[index].isMapped = event.target.checked;
        
        const ids = event.currentTarget.dataset.id;
        this.originalData = this.originalData.map(item => {
            if (item.Id === ids) {
                return { ...item, isMapped: event.target.checked }; // Update isMapped while preserving other properties
            }
            return item;
        });
        const mappingId = event.currentTarget.dataset.mappingid;
        
        if (mappingId) { // Ensure mappingId exists
            if (!this.dataVal[index].isMapped) {
                // If unchecked, add to delete list if not already present
                if (!this.delete.includes(mappingId)) {
                    this.delete.push(mappingId);
                }
            } else {
                // If checked, remove from delete list
                this.delete = this.delete.filter(id => id !== mappingId);
            }
        }
    }

    handleAreaChange(event){
        const val = event.detail.value;
        if(val != 'All'){
            var serchedDta = this.originalData.filter(obj => obj.area && obj.area.toLowerCase().includes(val.toLowerCase()));
            this.dataVal = serchedDta;
        }else{
            this.dataVal = this.originalData; 
        }
    }
    handleRegionChange(event){
        const val = event.detail.value;
        if(val != 'All'){
            var serchedDta = this.originalData.filter(obj => obj.region && obj.region.toLowerCase().includes(val.toLowerCase()));
            this.dataVal = serchedDta;
        }else{
            this.dataVal = this.originalData; 
        }
    }
    saveMapping(){
        const mappedData = this.originalData.filter(item => item.isMapped);
        console.log(mappedData);
        if(mappedData.length == 0 && this.delete.length == 0){
            alert('Nothing to save. Try again');
            return;
        }
        this.isDisable.allFields =true;
        const data = mappedData.map(item => ({
            Id: item.mappingId || null,
            Region__c: this.isRegion ? item.id : null,
            Account__c: this.isCustomer ? item.id : null,
            Area__c: this.isArea ? item.id : null,
            Product_Category__c: this.proCatId || null,
            Scheme__c: this.schemeId
        }));
        
        SAVEMAP_DATA({
            mapping : data,
            deleteData : this.delete,
            schemeId : this.schemeId
        })
        .then(result => {
            console.log(result)
            this.isDisable.allFields = false;
            const msg = {
                message: 'mapRegion_Save',
            }
            this.genericDispatchEvent('clickfunc', msg);
        })
        .catch(error => {
            this.isDisable.allFields = true;
            console.log(error);
        });
    }
    closePopup(){
        const msg = {
            message: 'mapRegion_close',
        }
        this.genericDispatchEvent('clickfunc', msg);
    }
    genericDispatchEvent(eventName, msg) {
        // Creating a custom event with a dynamic name and payload
        const event = new CustomEvent(eventName, { 
            detail : msg
         });
    
        // Dispatching the event
        this.dispatchEvent(event);
    }
}