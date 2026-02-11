import { LightningElement, api } from 'lwc';
import FORM_FACTOR from '@salesforce/client/formFactor';
import GET_ALL_DATA from '@salesforce/apex/EmployeeeController.getRecordViewFormData';

export default class EmployeeViewForm extends LightningElement {
    @api objectName;
    @api recordId; // Record ID for the Employee__c record
    @api customClass = 'slds-size_1-of-2'; // Default grid sizing
    @api isLoading = false; // Loading state
    @api mandateReplacedFor = false; // Control visibility of Replaced For
    @api mandateContractType = false; // Control visibility of Contract Type
    @api showEditFields = false; // Control visibility of Relieving Date
    @api isShowDistrictInCharge = false; // Control visibility of District In Charge
    @api isShowRegion = false; // Control visibility of Region
    @api isShowArea = false; // Control visibility of Area
    @api isShowDistrict = false; // Control visibility of Working District
    @api isShowTerritory = false; // Control visibility of Territory
    @api isShowAllSections = false; // Control visibility of additional approval sections
    @api isRegionRequired = false; // Control required attribute for Region
    @api isAreaRequired = false; // Control required attribute for Area
    @api isTerritoryRequired = false; // Control required attribute for Territory
    isLoading = false;
    isDesktop = false;
    isPhone = false;
    size = 6;
    employeerecordId;
    objectApiName = 'Employee__c'
    isSystemAdmin = false;
    isEmployeeFound = false;
    isAdmin = false;
    //On loading this method will be called
    connectedCallback() {
         this.isLoading = true;
        this.isDesktop = FORM_FACTOR === 'Large'? true : false;
        this.isPhone = FORM_FACTOR === 'Small'? true : false;
        if (FORM_FACTOR === 'Medium') this.isDesktop = true;
        this.customClass = this.isDesktop ? 'slds-size_1-of-2' : 'slds-size_1-of-1';
        this.size = this.isDesktop ? 6 :12;
        this.isLoading = false;
        this.getAllData();
    }
    @api getAllData(){
        if (!navigator.onLine) {
            this.isLoading = false;
            this.showToast('Error', 'No internet connection. Please check your network and try again.', 'error');
            return;
        }
        this.isLoading = true;
        GET_ALL_DATA({recordId:this.recordId,objectName:this.objectName
        })
        .then(result => {
            this.isEmployeeFound = result.isEmployeeFound;
            //When Employee record is Exited
            if (this.recordId && result.employee && result.isEmployeeFound) {
                this.objectApiName = 'Employee__c';
                const emp = result.employee;
                this.employeerecordId =  result.employee.Id;
                this.isShowAllSections = (emp.Profile__c == 'SSA' || emp.Profile__c == 'DSM') ? false : true ;
                this.isShowDistctInchage = emp.Profile__c === 'Sr. TSE';
                this.mandateContractType = emp.Payroll__c === 'No';
                this.mandateReplacedFor = emp.User_Type__c === 'Replacement';
                this.isAdmin = result.profileName;
                this.updateProfileBasedValues(emp.Profile__c)
            }
            else
            {
                const emp = result.userRecord;
                this.employeerecordId =  emp.Id;
                this.objectApiName = 'User';
            }
            this.isLoading = false;
        })
        .catch(error => {
            console.error(error);
            this.isLoading = false;
        });
    }  

    updateProfileBasedValues(fieldValue)
    {
        //Show and hide fields
        this.isShowRegion = false;
        this.isShowArea = false;
        this.isShowDistrict = false;
        this.isShowTerritory = false;
        if(fieldValue == 'RSM' || fieldValue == 'Sr. RSM' || fieldValue == 'Deputy RSM')
        {
            this.isShowRegion = true;
            this.isRegionRequired = true;
        }
        else if(fieldValue == 'ASM' || fieldValue == 'Sr. ASM' || fieldValue == 'Deputy ASM')
        {
            this.isShowRegion = true;
            this.isShowArea = true;
        }
        else if(fieldValue == 'TSM' || fieldValue == 'Sr. TSM' || fieldValue == 'Deputy TSM' ||
            fieldValue == 'Sr. TSE' || fieldValue == 'TSE' || fieldValue == 'Jr. TSE' || 
            fieldValue == 'ISR' ||  fieldValue == 'SR')
        {
            this.isShowRegion = true;
            this.isShowArea = true;
            this.isShowDistrict = true;
            this.isShowTerritory = true;
        }
        else if(fieldValue == 'SSA' || fieldValue == 'DSM')
        {
            this.isShowRegion = true;
            this.isShowArea = true;
            this.isShowDistrict = true;
            this.isShowAllSections = false;

        }
    }

}