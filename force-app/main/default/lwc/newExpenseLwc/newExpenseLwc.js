import { LightningElement,api,track,wire } from 'lwc';
import FORM_FACTOR from '@salesforce/client/formFactor';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getData from '@salesforce/apex/ExpenseLwcController.getAllData';
import validateExpense from '@salesforce/apex/ExpenseLwcController.validateExpenseDate';

export default class NewExpenseLwc extends LightningElement
{

    @api recordId;
    isDesktop = false;
    isPhone = false; 
    isLoading = false;
    subLoading = false;
    currentStep = '1';
    @track expense = {};
    @track travelEligibility = {};
    @track expItems = [];
    @track DeleteExpLine = [];
    //Picklist values
    travelTypes = [];
    expenseTypes = [];
    allTravelModes = [];
    travelModes = [];
    listId;
    profileName;
    backDatedEntry = 1;
    perKMChargeBike = 0;
    perKMChargeCar = 0;
    daAmount = 0;
    localConveyanceAmont = 0;
    isDisabled = false;
    cities = [];
    searchedCities = [];
    dailyLogRecord ={};

    //disabling Properties
    expenseDateDisabled=false;
    expenseTitle ='New Expense';
    computedCardClass ='slds-p-horizontal_x-small groove';
    customClass='slds-size_1-of-3 slds-p-horizontal_small';

    
    grandTotal=0;
    showExpense = true;
    showUpdate = false;
    isButtonDisabled =false;
    showUpload = false;
    showExpeneItems = false;

    //Intally this method will be called
    connectedCallback(){
        this.isDesktop = FORM_FACTOR === 'Large'? true : false;
        this.isPhone = FORM_FACTOR === 'Small'? true : false;
        this.computedCardClass = this.isDesktop ? 'slds-p-horizontal_x-small groove customMargin' : 'slds-p-horizontal_x-small';
        this.customClass = this.isDesktop ? 'slds-size_1-of-3 slds-p-horizontal_small' : 'slds-size_1-of-2 slds-p-horizontal_small';
        this.expense = {
            Expense_Date__c: '',
            Travel_Type__c: '',
            TA_Amount__c: 0.00,
            DA_Amount__c: 0.00,
            Local_Conveyance_Amount__c : 0.00,
            Other_Misc_Expense_Amount__c : 0.00,
            Courier_Charges__c  : 0.00,
            Mobile_Charges__c  : 0.00,
            Food_Expense_Amount__c   : 0.00,
            Lodging_Expense_Amount__c : 0.00,
            Total_Expense_Amount__c: 0.00,
            Id:null
        };
        //Getting All the Data
        this.fetchAllData();
        //Adding the Line Item Record
        this.addExpenseRecord(-1);
    }
    
    //fetching All Data
    fetchAllData() {
        this.isLoading = true;
        getData({recordId:this.recordId})
        .then((result) => {
            console.log(JSON.stringify(result));
            this.listId = result.listId;
            this.profileName = result.profileName;
            this.backDatedEntry = result.backDatedEntry;
            this.travelTypes = result.travelTypes;
            this.expenseTypes = result.expenseTypes;
            this.allTravelModes = result.travelModes;
            this.travelEligibility = result.travelEligibility;
            this.cities = result.cities;
            this.perKMChargeBike = this.travelEligibility.Conveyance_Allowance_per_KM_Bike__c || 0;
            this.perKMChargeCar = this.travelEligibility.Conveyance_Allowance_per_KM_Own_Car__c || 0;
            this.localConveyanceAmont = this.travelEligibility.Local_Conveyance__c || 0;
            this.isLoading = false;
        })
        .catch((error) => {
            this.isLoading = false;
            console.log('error'+JSON.stringify(error));
            this.showToast(
                'Error',
                'Error fetching Expenses: ' + (error.body ? error.body.message : JSON.stringify(error)), 
                'error'
            );
            
        });
    }

    //Remove Row
    removeRow(event) {
        let index = event.currentTarget.dataset.index;
        let items = [...this.expItems];
        if (items[index].Id) {
            this.DeleteExpLine = [...(this.DeleteExpLine || []), items[index].Id];
        }
        items.splice(index, 1);
        
        // Recalculate index values
        items = items.map((item, i) => ({
            ...item,
            expenseTypeId:'Expense_Type'+i,
            travelModeId:'Travel_Mode'+i,
            indexvalue: i + 1
        }));
        this.expItems = items;

        if (items.length < 1) {
            this.addRow();
        }
        //this.getGrandTotal();
    }
    //Add Row
    addRow(event){
        const index = event.target.dataset.index;
        this.addExpenseRecord(index);
    }
    //Adding new Record
    addExpenseRecord(index) {
        let items = [...this.expItems];
        if (index === -1) {
            items.push({
                sObjectType: 'Expense_Line_Item__c',
                Id: null,
                Expense_Date__c: '',
                Expense_Type__c: '',
                Travel_Mode__c: '',
                City__c: '',
                City_Name__c : '',
                From__c:'',
                To__c:'',
                Description__c: '',
                Total_KM__c: null,
                Calculated_KM__c: null,
                Amount__c: null,
                lodging_Limit__c:0,
                Local_Conveyance_Limit__c:0,
                Remarks__c : '',
                isTA:false,
                isDA:false,
                isLodging:false,
                isShowCity:false,
                isCityReadOnly:false,
                isTransportCarBike : false,
                isOtherExpense :false,
                isTransportNotBikeCar:false,
                isDisabled:false,
                hideDelete:false,
                indexvalue:1,
                expenseTypeId:'Expense_Type'+Number(items.length),
                travelModeId:'Travel_Mode'+Number(items.length)
            });
        } else {
            let from = items[index].From__c != null &&  items[index].From__c != undefined ? items[index].From__c : '';
            let to = items[index].To__c != null &&  items[index].To__c != undefined ? items[index].To__c : '';

            items.push({
                sObjectType: 'Expense_Line_Item__c',
                Id: null,
                Expense_Date__c: '',
                Expense_Type__c: '',
                Travel_Mode__c: '',
                City__c: '',
                City_Name__c : '',
                From__c:from,
                To__c:to,
                Description__c: '',
                Total_KM__c: null,
                Calculated_KM__c: null,
                Amount__c: null,
                lodging_Limit__c:0,
                Local_Conveyance_Limit__c:0,
                Remarks__c : '',
                isTA:false,
                isDA:false,
                isLodging:false,
                isShowCity:false,
                isCityReadOnly:false,
                isTransportCarBike : false,
                isOtherExpense :false,
                isTransportNotBikeCar:false,
                isDisabled:false,
                hideDelete:false,
                indexvalue: Number(items.length)+1,
                expenseTypeId:'Expense_Type'+Number(items.length),
                travelModeId:'Travel_Mode'+Number(items.length)
            });
        }
        this.expItems = items;
    }

    expenseDateChangeHandler(event) {
        let expenseDate = event.target.value; // Selected Date
        const selectedDate = new Date(expenseDate);
        this.expense.Expense_Date__c  = selectedDate.toISOString().split('T')[0];
        // --- Backdated validation ---
        if (this.backDatedEntry && this.backDatedEntry > 0) {
            const today = new Date(); 
           
            // Calculate min allowed date (today - backDatedEntry days)
            const minAllowedDate = new Date();
            minAllowedDate.setDate(today.getDate() - this.backDatedEntry);

            // Reset time for clean comparison
            today.setHours(0, 0, 0, 0);
            selectedDate.setHours(0, 0, 0, 0);
            minAllowedDate.setHours(0, 0, 0, 0);

            // Validate
            if (selectedDate < minAllowedDate || selectedDate > today) {
                this.expense.Expense_Date__c = '';
                this.template.querySelector('[data-id="Expense_Date__c"]').value = '';
                this.showToast('Error',"You are not Allowed to Add Expense for the Selected Date", "error");
                return; // Stop further execution
            }
        }
        this.subLoading = true;
        validateExpense({expenseDate:expenseDate})
        .then((result) => {
            console.log(JSON.stringify(result));
            if (result.dailyLogList.length > 0) {
                this.showExpeneItems = true;
                this.dailyLogRecord = result.dailyLogList[0];
                this.expense.Travel_Type__c = this.dailyLogRecord.Travel_Type__c; 
                if( this.expense.Travel_Type__c == 'Up country')
                {
                    this.daAmount = this.travelEligibility.Dearness_Allowance__c || 0;
                    // Split the string by semicolon
                    let selectedModes = this.travelEligibility.Travel_Mode_UC__c 
                        ? this.travelEligibility.Travel_Mode_UC__c.split(';') 
                        : [];

                    // Filter from allTravelModes where value matches
                    this.travelModes = this.allTravelModes.filter(mode =>
                        selectedModes.includes(mode.value)
                    );

                }
                else if( this.expense.Travel_Type__c == 'Headquarters')
                {
                    this.daAmount = this.travelEligibility.Daily_Allowance_HQ__c || 0;
                    this.travelModes = this.allTravelModes;
                    
                    // Split the string by semicolon
                    let selectedModes = this.travelEligibility.Travel_Mode_HQ__c 
                        ? this.travelEligibility.Travel_Mode_HQ__c.split(';') 
                        : [];

                    // Filter from allTravelModes where value matches
                    this.travelModes = this.allTravelModes.filter(mode =>
                        selectedModes.includes(mode.value)
                    );
                }
                else
                {
                    this.daAmount = 0;
                    this.travelModes = this.allTravelModes
                }

                if (result.expenseItems && result.expenseItems.length > 0) {
                    // Get the first Expense__c (since query is filtered by expenseDate)
                    let expenseRecord = result.expenseItems[0];
                    this.expense.Id = expenseRecord.Id;
                    this.expense.Travel_Type__c = expenseRecord.Travel_Type__c; 
                    if (expenseRecord.Expenses_line_items__r && expenseRecord.Expenses_line_items__r.length > 0) {
                        this.expItems = expenseRecord.Expenses_line_items__r.map((item, index) => {
                            let flags = this.getBooleanFlags(item); // custom method for boolean logic
                            return {
                                ...item,
                                ...flags,
                                indexvalue: index + 1,
                                isDisabled: false,
                                hideDelete: true,
                                expenseTypeId: 'Expense_Type' + index,
                                travelModeId: 'Travel_Mode' + index
                            };
                        });
                    }
                }
                else
                {

                }
            }
            else
            {
                this.showToast('Error','There is no attendence for the selected date', 'error');
                this.expense.Expense_Date__c = '';
                this.template.querySelector('[data-id="Expense_Date__c"]').value = '';
            }

            this.subLoading = false;
        })
        .catch((error) => {
            this.subLoading = false;
            console.log('error'+JSON.stringify(error));
            this.showToast(
                'Error',
                'Error fetching Expenses: ' + (error.body ? error.body.message : JSON.stringify(error)), 
                'error'
            );
            
        });
    }

    //expenseTypechanged
    expenseTypeChangeHandler(event) {
        const id = event.target.dataset.id;
        const index = event.target.dataset.index; // Get index from dataset
        let expItems = [...this.expItems]; // Clone array for reactivity
    
        let expenseType = event.target.value;
        expItems[index].Expense_Type__c = expenseType;
    
        // Reset values
        expItems[index].Amount__c = null;
        expItems[index].Travel_Mode__c = '';
        expItems[index].Total_KM__c = null;
        expItems[index].City__c = '';
        expItems[index].City_Name__c = '';
    
    
        expItems[index].isTA = false;
        expItems[index].isLodging = false;
        expItems[index].isOtherExpense = false;
        expItems[index].isDA = false;
        expItems[index].isTransportNotBikeCar = false;
        expItems[index].isTransportCarBike = false;

        // Clear old validity first
        const amountField = this.template.querySelector(
            `lightning-input[data-id="Amount"][data-index="${index}"]`
        );
        if (amountField) {
            amountField.setCustomValidity(""); 
            amountField.reportValidity();
        }

        // Set Amount__c if Allowance_Type__c is 'DA'
        if (expenseType === 'DA') {
            expItems[index].Amount__c = this.daAmount;
            expItems[index].isDA = true;
        }
        else if (expenseType === 'TA'){
            expItems[index].isTA = true;
        }
        else if(expenseType === 'Other/MISC' || expenseType === 'Local Conveyance' || expenseType === 'Lodging'
             || expenseType === 'Courier Charges' ||  expenseType === 'Mobile Charges' || 
            expenseType === 'Food')
        {
            expItems[index].isOtherExpense = true;
            if(expenseType === 'Lodging')
            {
                expItems[index].isLodging = true;
            }
            else if(expenseType === 'Local Conveyance')
            {
                expItems[index].Local_Conveyance_Limit__c = this.localConveyanceAmont || 0; 

            }

        }
      
    
        // Validate duplicate Expense_Type__c 
        let count = expItems.filter(item => 
            item.Expense_Type__c === 'DA'
        ).length;
    
        if (count > 1) {
            expItems[index].Expense_Type__c = '';
            expItems[index].Amount__c = null;
            expItems[index].isDA = false;
            const inputField = this.template.querySelector(`[data-id="${id}"]`);
            if (inputField) {
                inputField.value = ''; 
            }
            this.showToast('Error',"DA for the Selected Date is Already Added", "error");
        }
    
        this.expItems = expItems;
    
        //this.getGrandTotal(); 
    }

    //searchedCities 
    handleCitySearch(event){
        const index = event.target.dataset.index;
        let searchValueName = event.target.value;
        if(searchValueName){
            let objData = this.cities;
     
            let searchedData = [];
            if(objData)
            {
                let searchLower = searchValueName.toLowerCase();
                for (let i = 0; i < objData.length; i++) {
                    const name = objData[i].Name ? objData[i].Name.toLowerCase() : '';
                    if (name.includes(searchLower)) {
                        searchedData.push(objData[i]);
                        if (searchedData.length >= 25) break;
                    }
                }
                this.expItems[index].isShowCity = searchedData != 0 ? true : false;
                this.searchedCities = searchedData;
            }
       
        }
        else
        {
            this.expItems[index].isShowCity = false;
            this.expItems[index].City_Name__c = '';
            this.expItems[index].City__c = '';
            this.expItems[index].isCityReadOnly = false;

        }

    }
    selectCity(event) {
        const index = parseInt(event.currentTarget.dataset.index, 10);
        const selectedCityId = event.currentTarget.dataset.id;
        const selectedCityName = event.currentTarget.dataset.name;
        const type = event.currentTarget.dataset.type;
        this.expItems[index].City_Name__c = selectedCityName;
        this.expItems[index].City__c = selectedCityId;
        this.expItems[index].isCityReadOnly = true;
        this.expItems[index].isShowCity = false;

        if(type == 'Metro')
        {        
            this.expItems[index].lodging_Limit__c = this.travelEligibility.Lodging_Expense_per_Day_Metro__c || 0;
        }
        else if( type == 'Non-Metro' )
        {
            this.expItems[index].lodging_Limit__c = this.travelEligibility.Lodging_Expense_per_Day_Non_Metro__c || 0;
        }
    }

    //Mode Of Transport and Distance Travelled Change Handler
    travelModeChangeHandler(event) {
        const id = event.target.dataset.id;
        const index = event.target.dataset.index; 
        let expItems = [...this.expItems]; 
        const field = event.currentTarget.dataset.id;
        expItems[index].Calculated_KM__c = this.dailyLogRecord.Distance_Travelled__c || 0 ;
        if (field.includes('Travel_Mode')) { 
            expItems[index].Travel_Mode__c = event.target.value;
        } else if (field === 'Total_KM') {
            expItems[index].Total_KM__c = event.currentTarget.value;
        }
        const CarPerKm = this.perKMChargeCar;
        const BikePerKm = this.perKMChargeBike;
        // Reset amount initially
        expItems[index].Amount__c = null;


        if (!expItems[index].Travel_Mode__c) {
            expItems[index].Total_KM__c = null;
            expItems[index].Amount__c = null;
        } else {
            expItems[index].isTransportNotBikeCar = false;
            expItems[index].isTransportCarBike = false;
            if (expItems[index].Travel_Mode__c === 'Bike') {
                expItems[index].Amount__c = expItems[index].Total_KM__c * BikePerKm;
                expItems[index].isTransportCarBike = true;

            } else if (expItems[index].Travel_Mode__c === 'Car') {
                expItems[index].Amount__c = expItems[index].Total_KM__c * CarPerKm;
                expItems[index].isTransportCarBike = true;
            }
            else{

                expItems[index].isTransportNotBikeCar = true;
            }
        }
        
    
        // Validate duplicate Mode of Transport for the same date
        let count = expItems.filter(item => 
            item.Expense_Type__c === 'TA' &&
            item.Travel_Mode__c === expItems[index].Travel_Mode__c &&
            expItems[index].Travel_Mode__c
        ).length;
    
        if (count > 1) {
            
            let errorMsg = `TA by ${expItems[index].Travel_Mode__c} for the Selected Date is Already Added`;
            this.showToast('Error',errorMsg, "error");
            expItems[index].Travel_Mode__c = '';
            expItems[index].isTransportNotBikeCar = false;
            expItems[index].isTransportCarBike = false;
            const inputField = this.template.querySelector(`[data-id="${id}"]`);
            if (inputField) {
                console.log('Inputfield'+JSON.stringify(inputField));
                inputField.value = ''; // This visually clears the field
            }
        }
    
        this.expItems = expItems; 
    
       // this.getGrandTotal(); 
    }


     //Input field change
    handlerInputChange(event)
    {
        const field = event.currentTarget.dataset.id;
        const index = event.target.dataset.index; 
        let expItems = [...this.expItems]; 
        if (field === 'From__c') {
            expItems[index].From__c = event.target.value;
        }
        else if (field === 'To__c') {
            expItems[index].To__c = event.target.value;
        }
        else if(field === "Amount")
        {
            let value = parseFloat(event.target.value);
            if ( expItems[index].Expense_Type__c == 'Lodging'  && expItems[index].lodging_Limit__c) {
                if (value > expItems[index].lodging_Limit__c) {
                    event.target.setCustomValidity("Lodging Limit has been exceeded");
                } else {
                    event.target.setCustomValidity(""); // clear error
                }
                event.target.reportValidity();
            }
            else if(expItems[index].Expense_Type__c == 'Local Conveyance'  && expItems[index].Local_Conveyance_Limit__c)
            {
                if (value > expItems[index].Local_Conveyance_Limit__c) {
                    event.target.setCustomValidity("Local Conveyance Limit has been exceeded");
                } else {
                    event.target.setCustomValidity(""); // clear error
                }
                event.target.reportValidity();
            }
            expItems[index].Amount__c = event.target.value;
            //this.getGrandTotal();
        }
        else if(field === "Remarks__c")
        {
            expItems[index].Remarks__c = event.target.value;
        }
    }


    getBooleanFlags(existingItem) {
        return {
            isTA: this.checkIsTA(existingItem),
            isDA: this.checkIsDA(existingItem),
            isOtherExpense: this.checkIsOtherExpense(existingItem),
            isTransportCarBike: this.checkIsTransportCarBike(existingItem),
            isTransportNotBikeCar: this.checkIsTransportNotBikeCar(existingItem)
        };
    }
    
    checkIsTA(existingItem) {
        return existingItem.Expense_Type__c == 'TA';
    }
    checkIsDA(existingItem) {
        return existingItem.Expense_Type__c == 'DA';
    }
    checkIsOtherExpense(existingItem) {
        return existingItem.Expense_Type__c == 'Other';
    }
    checkIsTransportCarBike(existingItem) {
        return existingItem.Travel_Mode__c == 'Car' || existingItem.Travel_Mode__c == 'Bike';
    }
    checkIsTransportNotBikeCar(existingItem) {
        return existingItem.Travel_Mode__c != 'Car' && existingItem.Travel_Mode__c != 'Bike';
    }
    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
    
}