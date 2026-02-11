import { LightningElement, api, track } from 'lwc';
import getExpneseData from '@salesforce/apex/ExpenseListViewController.getAllData';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { deleteRecord } from 'lightning/uiRecordApi';
import saveExpenseItem from '@salesforce/apex/ExpenseListViewController.insertExpenseItem';


export default class ExpenseDetailedPage extends LightningElement {
    @api recordId ;
    @api isDesktop;
    @track expItems = [];
    @track dailyLogs = [];
    @track expenseItem = {};
    @track expense = {};


    /**Picklist List **/
    allowanceOptions = [];
    transportOptions = [];
    expenseOptions = [];

    profileName;
    priceMaster;
    backDatedEntry = 1;
    perKMChargeBike = 0;
    perKMChargeCar = 0;
    daAmount = 0;
  
    expenseDataExisted = true;
    isModalOpen = false;
    isDeleteModalOpen = false;
    isLoading = false;
    expectedAmount = '';
    customClass='slds-size_1-of-2 slds-p-horizontal_small';
    comments = '';
    modalTitle = '';
    itemtId = '';
    @track showPopup = false;
    @track selectedItem = {};
    containerClass;
    isDisabled = false;
    showUpload = false;
    approvalStatus ='';
    get showExpenseItems() {
        return !( (this.isModalOpen || this.showPopup || this.isDeleteModalOpen) && !this.isDesktop );
    }
   
    @api refreshData() {
        // Logic to refresh expense data
        this.getExpenseLineItems();
    }
    //On starting it will call this method
    connectedCallback() {
        this.containerClass = this.isDesktop ? 'slds-modal__container ' : '';
        this.customClass = this.isDesktop ? 'slds-size_1-of-2 slds-p-horizontal_small' : 'slds-size_1-of-1 slds-p-horizontal_small';
        this.getExpenseLineItems();
        this.disablePullToRefresh();
    }
   

    //it will get the expense line items
    getExpenseLineItems() {
        this.isLoading = true;
        getExpneseData({ recordId: this.recordId })
            .then((result) => {
                console.log(JSON.stringify(result));
                this.profileName = result.ProfileName;
                this.backDatedEntry = result.BackDatedEntry;
                this.expense = result.expense;
                this.dailyLogs = result.dailyLogList;
                this.approvalStatus = result.expense.Approval_Status__c;
    
                // Convert result arrays into key-value objects for picklist
                this.expenseOptions = this.addAllOption(result.ExpTypes);
                this.transportOptions = this.addAllOption(result.ModOfTrans);
                this.allowanceOptions = this.addAllOption(result.AllwTypes);

                this.expItems = result.ExlineItems.map(item => ({
                    ...item,  
                    openPopup: false,
                    sObjectType: 'Expense_Line_Item__c'

                }));
                this.sortExpenseItems();
                this.expenseDataExisted = this.expItems.length > 0;
                this.isLoading = false;
                this.sendApprovalStatusToParent();
            })
            .catch((error) => {
                this.isLoading = false;
                console.error(error);
                this.showToast('Error', 'Error fetching expense line items: ' + JSON.stringify(error), 'error');
            });
    }
    // Getter to check Approval Status
    get isApprovalStatusValid() {
        return (this.approvalStatus === 'Not Submitted' || this.approvalStatus === 'Admin Rejected');
    }
    //Once we clicked on the 3 dots
    openMenu(event) {
        const index = parseInt(event.currentTarget.dataset.index, 10);
        this.expItems = this.expItems.map((item, i) => ({
            ...item,
            openPopup: i === index ? !item.openPopup : false
        }));
    }
    //once we click on add or edit or delete buttons
    handleOnclickMenu(event) {
        const action = event.currentTarget.dataset.name;
        if(this.isApprovalStatusValid)
        {
            const itemId = event.currentTarget.dataset.id;
            const exLineItem = this.expItems.find(item => item.id === itemId);
            this.showUpload = false;
            this.resetForm();
            if (action === 'Edit' && exLineItem) {
                this.modalTitle = 'Edit Expense';
                this.expenseItem = {
                    Expense_Date__c: exLineItem.Expense_Date__c,
                    Expense_Type__c: exLineItem.Expense_Type__c,
                    With_Companion__c: exLineItem.With_Companion__c,
                    Colleague_Name__c: exLineItem.Colleague_Name__c,
                    Colleague_Name_2__c: exLineItem.Colleague_Name_2__c,
                    Allowance_Type__c: exLineItem.Allowance_Type__c,
                    Area_Name__c: exLineItem.Area_Name__c,
                    City__c: exLineItem.City__c,
                    Description__c: exLineItem.Description__c,
                    Mode_of_transport__c:exLineItem.Mode_of_transport__c,
                    Total_KM__c: exLineItem.Total_KM__c,
                    Amount__c: exLineItem.Amount__c,
                    Calculated_KM__c: exLineItem.Calculated_KM__c,
                    AddtionalKMWith20__c:exLineItem.AddtionalKMWith20__c,
                    Id: exLineItem.Id,
                    isTA: exLineItem.Allowance_Type__c == 'TA',
                    isDA: exLineItem.Expense_Type__c == 'DA',
                    isOtherExpense: exLineItem.Expense_Type__c == 'Other',
                    isTransportCarBike: exLineItem.Mode_of_transport__c == 'Car' || exLineItem.Mode_of_transport__c == 'Bike',
                    isCompanionExisted: exLineItem.With_Companion__c == 'Yes',
                    allownceDisabled: false,
                    isTransportNotBikeCar: exLineItem.Mode_of_transport__c != 'Car' && exLineItem.Mode_of_transport__c != 'Bike',
                    isDisabled: false,
                    sObjectType: 'Expense_Line_Item__c'
                };
                this.itemtId = exLineItem.Id;
                this.isModalOpen = true;
            } else if (action === 'Add') {
                this.modalTitle = 'New Expense';
                this.itemtId = null;
                this.isModalOpen = true;
            }else {
                console.error('Invalid action or item not found.');
            }
                    
        }
        else{
            let actionValue = action.toLowerCase();

            this.showToast('Error', `Expense is ${this.expense.Approval_Status__c}, you can't ${actionValue} the expense`, 'error');
        }
       
    }
    //When Line Item Date Selected
    validateLog(event) {
        const id = event.target.dataset.id;
        console.log('Id:', id);
    
        let expenseDate = event.target.value;
        let expenseDateObject = new Date(expenseDate);
        let backDatedEntry = this.backDatedEntry || 1;
    
        // Ensure reactive updates by creating a new object
        let updatedExpenseItem = { ...this.expenseItem };
    
        updatedExpenseItem.Allowance_Type__c = '';
        updatedExpenseItem.Amount__c = null;
        updatedExpenseItem.isTA = false;
        updatedExpenseItem.isOtherExpense = false;
        updatedExpenseItem.isDA = false;
        updatedExpenseItem.isTransportNotBikeCar = false;
        updatedExpenseItem.isTransportCarBike = false;

        let matchedDialog = this.dailyLogs.find(dialog => dialog.LogDate__c === expenseDate);
        console.log('matchedDialog:', JSON.stringify(matchedDialog));
    
        let expenseDateField = this.template.querySelector('[data-id="Expense_Date"]');
    
        if (matchedDialog) {
            let XDaysAgo = new Date();
            XDaysAgo.setDate(XDaysAgo.getDate() - parseInt(backDatedEntry));
    
            if (expenseDateObject < XDaysAgo) {
                if (expenseDateField) {
                    expenseDateField.value = '';
                }
                this.showToast('Error', "You are not allowed to add expense for the selected date", "error");
    
                updatedExpenseItem.allownceDisabled = true;
                updatedExpenseItem.Expense_Date__c = null;
                updatedExpenseItem.isCompanionExisted = false;
            } else {
                updatedExpenseItem.allownceDisabled = false;
                updatedExpenseItem.Expense_Date__c = expenseDateObject.toISOString().split('T')[0];
                updatedExpenseItem.Expense_Type__c = matchedDialog.Travel_Type__c;
                updatedExpenseItem.Calculated_KM__c = matchedDialog.Today_Day_Travelled_Distance_KM__c || 0;
    
              
            }
        } else {
            if (expenseDateField) {
                expenseDateField.value = '';
            }
            this.showToast('Error', "There is no log for the selected date", "error");
    
            updatedExpenseItem.Expense_Date__c = null;
            updatedExpenseItem.allownceDisabled = true;
            updatedExpenseItem.isCompanionExisted = false;
            updatedExpenseItem.Allowance_Type__c = '';
        }
    
        // Assign updated object back to trigger UI reactivity
        this.expenseItem = updatedExpenseItem;
    }
    //Allowance Type changed
    allowanceTypeChangeHandler(event) {
        let expItems = [...this.expItems]; 
        let allowanceType = event.target.value;
        let updatedExpenseItem = { ...this.expenseItem };
        updatedExpenseItem.Allowance_Type__c = allowanceType;
    
        // Reset values
        updatedExpenseItem.Amount__c = null;
        updatedExpenseItem.Mode_of_transport__c = '';
        updatedExpenseItem.Total_KM__c = null;
        updatedExpenseItem.isTA = false;
        updatedExpenseItem.isOtherExpense = false;
        updatedExpenseItem.isDA = false;
        updatedExpenseItem.isTransportNotBikeCar = false;
        updatedExpenseItem.isTransportCarBike = false;

        // Set Amount__c if Allowance_Type__c is 'DA'
        if (allowanceType === 'DA') {
            updatedExpenseItem.Amount__c = this.daAmount;
            updatedExpenseItem.isDA = true;
        }
        else if (allowanceType === 'TA'){
            updatedExpenseItem.isTA = true;
        }
        else if(allowanceType === 'Other')
        {
            updatedExpenseItem.isOtherExpense = true;
        }
    
        // Validate duplicate Allowance_Type__c for the same Expense_Date__c
        let count = expItems.filter(item => 
            item.Expense_Date__c === updatedExpenseItem.Expense_Date__c && 
            item.Allowance_Type__c === 'DA'&& updatedExpenseItem.Allowance_Type__c =='DA'
            &&  item.Id != updatedExpenseItem.Id
        ).length;
        console.log('count'+count);
        console.log('updatedExpenseItem.Expense_Date__c'+updatedExpenseItem.Expense_Date__c);
        if (count > 0) {
            updatedExpenseItem.Allowance_Type__c = '';
            updatedExpenseItem.Amount__c = null;
            updatedExpenseItem.isDA = false;
            let inputfield = this.template.querySelector('[data-id="Allowance_Type"]');
            if (inputfield) {
                inputfield.value = '';
            }
            this.showToast('Error',"DA for the Selected Date is Already Added", "error");
        }
    
        this.expenseItem = updatedExpenseItem;
    }
    //Mode Of Transport and Distance Travelled Change Handler
    modeOfTransportChangeHandler(event) {
        const id = event.target.dataset.id;
        let expItems = [...this.expItems]; 
        let updatedExpenseItem = { ...this.expenseItem };
        const field = event.currentTarget.dataset.id;
        if (field.includes('Mode_of_transport')) { 
            updatedExpenseItem.Mode_of_transport__c = event.target.value;
        } else if (field === 'Total_KM') {
            updatedExpenseItem.Total_KM__c = event.currentTarget.value;
        }
        const CarPerKm = this.perKMChargeCar;
        const BikePerKm = this.perKMChargeBike;
        updatedExpenseItem.Amount__c = null;
 
    
        let SystemCalculatedKm = updatedExpenseItem.Calculated_KM__c || 0;
        let ExpDate = updatedExpenseItem.Expense_Date__c;
    
        let WithAdditonalSystemKM = SystemCalculatedKm + ((20 * SystemCalculatedKm) / 100);
        let TotalKmManuallyEntered = 0;
    
        // Restricting user from entering more than system-calculated KM
        expItems.forEach(item => {
            if (
                item.Expense_Date__c === ExpDate &&
                item.Allowance_Type__c === 'TA'
            ) {
                TotalKmManuallyEntered += Number(item.Total_KM__c) || 0;
            }
        });

        let kmEntered = TotalKmManuallyEntered +  updatedExpenseItem.Total_KM__c;

        console.log('TotalKmManuallyEntered'+ TotalKmManuallyEntered);
        console.log('kmEntered'+ kmEntered);
    
        if (kmEntered > WithAdditonalSystemKM) {
            this.showToast(
                "Info",
                "You can enter up to 20% more than the system-calculated distance for the selected day. Please decrease the distance traveled.",
                "info"
            );
            this.template.querySelector('[data-id="Total_KM"]').value = null;
            updatedExpenseItem.Total_KM__c = null;
        } else {
            if (!updatedExpenseItem.Mode_of_transport__c) {
                updatedExpenseItem.Total_KM__c = null;
                updatedExpenseItem.Amount__c = null;
            } else {
                updatedExpenseItem.isTransportNotBikeCar = false;
                updatedExpenseItem.isTransportCarBike = false;
                if (updatedExpenseItem.Mode_of_transport__c === 'Bike') {
                    updatedExpenseItem.Amount__c = updatedExpenseItem.Total_KM__c * BikePerKm;
                    updatedExpenseItem.isTransportCarBike = true;

                } else if (updatedExpenseItem.Mode_of_transport__c === 'Car') {
                    updatedExpenseItem.Amount__c = updatedExpenseItem.Total_KM__c * CarPerKm;
                    updatedExpenseItem.isTransportCarBike = true;
                }
                else{

                    updatedExpenseItem.isTransportNotBikeCar = true;
                }
            }
        }
    
        // Validate duplicate Mode of Transport for the same date
        let count = expItems.filter(item => 
            item.Expense_Date__c === ExpDate &&
            item.Allowance_Type__c === 'TA' &&
            item.Mode_of_transport__c === updatedExpenseItem.Mode_of_transport__c &&
            item.Id != updatedExpenseItem.Id &&
            updatedExpenseItem.Mode_of_transport__c
        ).length;
    
        if (count > 0) {
            
            let errorMsg = `TA by ${updatedExpenseItem.Mode_of_transport__c} for the Selected Date is Already Added`;
            this.showToast('Error',errorMsg, "error");
            updatedExpenseItem.Mode_of_transport__c = '';
            updatedExpenseItem.isTransportNotBikeCar = false;
            updatedExpenseItem.isTransportCarBike = false;

            let inputfield = this.template.querySelector('[data-id="Mode_of_transport"]');
            if (inputfield) {
                inputfield.value = '';
            }
        }
        this.expenseItem = updatedExpenseItem;
    }

    closeModal() {
        this.isModalOpen = false;
        this.resetForm();
    }

    resetForm() {
        this.expenseItem = {
            Expense_Date__c: '',
            Expense_Type__c: '',
            With_Companion__c: '',
            Colleague_Name__c: '',
            Colleague_Name_2__c: '',
            Allowance_Type__c: '',
            Area_Name__c: '',
            City__c: '',
            Description__c: '',
            Stay_Type__c: '',
            Mode_of_transport__c: '',
            Total_KM__c: null,
            Amount__c: null,
            Calculated_KM__c: null,
            AddtionalKMWith20__c: 0,
            Id: null,
            Expense__c:this.recordId,
            isTA: false,
            isDA: false,
            isTransportCarBike: false,
            isOtherExpense: false,
            isCompanionExisted: false,
            allownceDisabled: true,
            isTransportNotBikeCar: false,
            isDisabled: false,
            hideDelete: false,
            sObjectType: 'Expense_Line_Item__c'
        };
    }

    //Input field change
    handlerInputChange(event)
    {
        const field = event.currentTarget.dataset.id;
        let updatedExpenseItem = { ...this.expenseItem };
        if (field === 'City') {
            updatedExpenseItem.City__c = event.target.value;
        }
        else if (field === 'Area_Name') {
            updatedExpenseItem.Area_Name__c = event.target.value;
        }
        else if(field === "Amount")
        {
            updatedExpenseItem.Amount__c = event.target.value;
        }
        else if(field === "Description")
        {
            updatedExpenseItem.Description__c = event.target.value;
        }
        this.expenseItem = updatedExpenseItem;
    }

    save() {
        var ExpenseRecord = this.expenseItem;
    
        // Validations
        if (!ExpenseRecord.Expense_Date__c) {
            this.showToast('Error', 'Please select an Expense Date', 'error');
            return;
        }
        if (!ExpenseRecord.City__c) {
            this.showToast('Error', 'Please enter the From', 'error');
            return;
        }
        if (!ExpenseRecord.Allowance_Type__c) {
            this.showToast('Error', 'Please select the Allowance Type', 'error');
            return;
        }
        if (ExpenseRecord.Allowance_Type__c === 'TA' && !ExpenseRecord.Mode_of_transport__c) {
            this.showToast('Error', 'Please select the mode of transport', 'error');
            return;
        }
        if ( ExpenseRecord.Mode_of_transport__c == 'Car' ||
            ExpenseRecord.Mode_of_transport__c == 'Bike' &&   (!ExpenseRecord.Total_KM__c || ExpenseRecord.Total_KM__c == 0)) {
            this.showToast('Error', 'Please enter distance travelled', 'error');
            return;
        }

        if (
            ExpenseRecord.Mode_of_transport__c !== 'Car' &&
            ExpenseRecord.Mode_of_transport__c !== 'Bike' &&
            (!ExpenseRecord.Amount__c || ExpenseRecord.Amount__c == 0)
        ) {
            this.showToast('Error', 'Please enter the amount', 'error');
            return;
        }
    
        this.isLoading = true;
    
        saveExpenseItem({ expenseItem: ExpenseRecord })
            .then((result) => {
                console.log('Result:', JSON.stringify(result));
    
                const newExpenseItem = {
                    Expense_Date__c: result.Expense_Date__c,
                    Expense_Type__c: result.Expense_Type__c,
                    With_Companion__c: result.With_Companion__c,
                    Colleague_Name__c: result.Colleague_Name__c,
                    Colleague_Name_2__c: result.Colleague_Name_2__c,
                    Allowance_Type__c: result.Allowance_Type__c,
                    Area_Name__c: result.Area_Name__c,
                    City__c: result.City__c,
                    Description__c: result.Description__c,
                    Mode_of_transport__c: result.Mode_of_transport__c,
                    Total_KM__c: result.Total_KM__c,
                    Amount__c: result.Amount__c,
                    Calculated_KM__c: result.Calculated_KM__c,
                    AddtionalKMWith20__c: result.AddtionalKMWith20__c,
                    Id: result.Id,
                    isTA: result.Allowance_Type__c === 'TA',
                    isDA: result.Allowance_Type__c === 'DA',
                    isOtherExpense: result.Allowance_Type__c === 'Other',
                    isTransportCarBike: result.Mode_of_transport__c === 'Car' || result.Mode_of_transport__c === 'Bike',
                    isCompanionExisted: result.With_Companion__c === 'Yes',
                    allownceDisabled: false,
                    isTransportNotBikeCar: result.Mode_of_transport__c !== 'Car' && result.Mode_of_transport__c !== 'Bike',
                    isDisabled: false,
                };
    
                this.expenseItem = newExpenseItem;
    
                // Handle modal visibility
                this.isModalOpen = this.showUpload === false;
    
                if (this.itemtId) {
                    console.log('Id'+this.itemtId);
                    // Update existing record
                    this.expItems = this.expItems.map(item => (item.Id === this.itemtId ? newExpenseItem : item));
                } else {
                    // Add new record
                    this.expItems = [...this.expItems, newExpenseItem];
                    this.itemtId = result.Id;
                }
    
                this.sortExpenseItems();
    
                this.expenseDataExisted = this.expItems.length > 0;
                this.isLoading = false;
                if( this.showUpload == false)
                {
                    this.showToast("Success","Expense Created Successfully. Please upload bills", "success");
                }
                this.showUpload = true;
               
                
            })
            .catch((error) => {
                this.isLoading = false;
                console.error('Save Error:', JSON.stringify(error));
    
                let message = 'Unknown error';
                if (error.body && error.body.message) {
                    message = error.body.message;
                }
    
                this.showToast('Error', `Error while saving expense: ${message}`, 'error');
            });
    }
    
    deleteExpense() {
        const itemId = this.itemtId;
        this.isDeleteModalOpen = false;
        this.isLoading = true;
        console.log('itemId'+itemId);
        deleteRecord(itemId)
            .then(() => {
                this.expItems = this.expItems.filter(expense => expense.Id !== itemId);
                console.log('Entered');
                this.expenseDataExisted = this.expItems.length > 0;
                this.isLoading = false;
                this.sortExpenseItems();
                this.showToast('Success', 'Expense deleted successfully', 'success');
            })
            .catch(error => {
                this.isLoading = false;
                this.showToast('Error', 'Error deleting Payment Follow-up: ' + JSON.stringify(error), 'error');
            });
    }

    sortExpenseItems()
    {
        // Define sorting order for Allowance_Type__c
        const allowanceOrder = { 'TA': 1, 'DA': 2, 'Other': 3 };

        // Close all popups and sort by Expense_Date__c first, then by Allowance_Type__c (custom order)
        this.expItems = this.expItems
        .map(item => ({ ...item, openPopup: false , sObjectType: 'Expense_Line_Item__c'}))
        .sort((a, b) => {
            const dateA = new Date(a.Expense_Date__c);
            const dateB = new Date(b.Expense_Date__c);

            if (dateA - dateB !== 0) {
                return dateA - dateB; // Sort by date first (ascending)
            }

            // Get priority for Allowance_Type__c (default to a high number if not found)
            const typeA = allowanceOrder[a.Allowance_Type__c] || 99;
            const typeB = allowanceOrder[b.Allowance_Type__c] || 99;

            return typeA - typeB; // Sort by custom Allowance_Type__c order
        });
    }

    handleDeleteCancel() {
        this.isDeleteModalOpen = false;

    }

    openPopupDetails(event) {
        // Reset all items to have openPopup as false
        this.expItems = this.expItems.map(item => ({
            ...item,  
            openPopup: false 
        }));
    
        const itemId = event.currentTarget.dataset.id;
        const selectedItem = this.expItems.find(item => item.Id === itemId);
    
        if (selectedItem) {
            this.selectedItem = {
                ...selectedItem,
                isTA: selectedItem.Allowance_Type__c === 'TA',
                isTransportCarBike: selectedItem.Mode_of_transport__c === 'Car' || selectedItem.Mode_of_transport__c === 'Bike',
                isCompanionExisted: selectedItem.With_Companion__c === 'Yes'
            };
        } else {
            this.selectedItem = null; // Handle the case where no matching item is found
        }
    
        this.showPopup = true;
    }

    closePopup() {
        this.showPopup = false;
        this.selectedItem = {};

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
    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
    addAllOption(options) {
       return [{ label: 'Select an Option', value: '' }, ...options];
    }

    // Method to send status to parent component
    sendApprovalStatusToParent() {
        const event = new CustomEvent('approvalstatuschange', {
            detail: { isValid: this.isApprovalStatusValid }
        });
        this.dispatchEvent(event);
    }
}