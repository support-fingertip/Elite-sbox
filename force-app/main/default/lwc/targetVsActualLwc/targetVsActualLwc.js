import { LightningElement,track,wire,api } from 'lwc';
import getData from '@salesforce/apex/TargetVsActualLwc.getAllData';
import getTargetActuals from '@salesforce/apex/TargetVsActualLwc.getTargetActuals';
import getUserTargetActuals from '@salesforce/apex/TargetVsActualLwc.getUserTargets';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import saveTargets from '@salesforce/apex/TargetVsActualLwc.saveTargets'; 
import saveAdminTargetActuals from '@salesforce/apex/TargetVsActualLwc.saveAdminTargets';
import FORM_FACTOR from '@salesforce/client/formFactor';
import TargetPlanIcon from '@salesforce/resourceUrl/TargetPlanIcon';
import { CurrentPageReference } from 'lightning/navigation';

export default class TargetVsActualLwc extends LightningElement {
    currentPageRef;
    periodId;
    executiveId;

    @wire(CurrentPageReference)
    wiredCurrentPageRef(result) {
        if (result) {
            this.currentPageRef = result;
            this.extractParams();
        }
    }

    extractParams() {
        if (this.currentPageRef && this.currentPageRef.state) {
            this.periodId = this.currentPageRef.state.c__periodId;
            this.executiveId = this.currentPageRef.state.c__ExecutiveId;
        }
    }

    targetPlanIcon = TargetPlanIcon;
    isDisabled = false;
    selectedUser = '';
    selectedPeriod = '';
    selectedAdminPeriod = '';
    isLoading = false;
    isPopupLoading = false;
    isDesktop = false;
    isPhone = false;
    @track userOptions = [];
    @track userList = [];
    @track periodOptions = [];
    @track currentPeriodOptions = [];
    @track targetLogics = [];
    @track targetList = [];
    @track curTargets = [];
    @track adminTargets = [];
    @track adminTargetItems = [];
    userTargetsLogicsExisted = false;
    currentTargetExisted = false;
    openDistrbutionTable= false;
    @track subOrdinateUserList = [];
    @track uniqueTargetLogics = [];
    @track targetLogicsWithManagerMap = new Map();
    @track userColumns = [];
    @track targetLogicColumns = [];
    @track targetLogicArray = [];
    logicListSize =0;
    subordinateUsersExisted = false;
    @track targetLogicMap = new Map();
    @track isDropdownOpen = true;
    containerClass;
    adminTarget = false;
    showAddTarget = false;
    showDistibuteTarget = false;
    initialTargetAssignmentProfile;
    @track parentToTotalTargetValueMap = new Map();
    @track parentwithtargetValueOfSubodinates = new Map();
    
    

    //On loading this method will be called
    connectedCallback(){
        this.isDesktop = FORM_FACTOR === 'Large'? true : false;
        this.isPhone = FORM_FACTOR === 'Small'? true : false;
        if(FORM_FACTOR === 'Medium')
        {
            this.isDesktop = true;
        }
        this.containerClass = this.isDesktop ? 'slds-modal__container ' : 'mobilePopup';
        //Getting All the Data     
        this.fetchAllData();
        this.disablePullToRefresh();
    }
    //fetching All Data while loading
    fetchAllData() {
        this.isLoading = true;
        getData({})
            .then((result) => {
                console.log("Fetched Data:", JSON.stringify(result));
    
                 // Populate User Options
                this.userOptions = this.populateOptions(result?.userList, 'Name', 'Id');
                this.userList = result?.userList || [];

                // Populate Period Options
                this.periodOptions = this.populateOptions(result?.periodsList, 'Name', 'Id');

                const currentDate = new Date();

                // Filter and populate current or future periods
                this.currentPeriodOptions = this.populateOptions(
                    result?.periodsList?.filter(period => new Date(period.End_Date__c) >= currentDate), 
                    'Name', 
                    'Id'
                );
    
                // Assign selected user and period
                this.selectedUser = result?.currentUserId || '';
                this.selectedPeriod = result?.period || '';
                this.selectedAdminPeriod = result?.period || '';
                this.initialTargetAssignmentProfile =  result?.initialTargetAssignmentProfile || '';
                
                this.targetList = result?.targetItems || [];
                this.setCurrentTarget();
                this.getProfileName();
                this.aggregateSubordinateTargets();
                this.isLoading = false;

                //When we are redirecting from User detailed page this method will be called
                if(this.periodId != null && this.executiveId != null){
                    this.selectedPeriod = this.periodId;
                    this.selectedUser = this.executiveId;
                    this.setTargetVsActualData();
                }
            })
            .catch((error) => {
                this.isLoading = false;
                console.error("Error fetching data:", error);
                
                this.showToast(
                    'Error',
                    `Error fetching targets: ${error.body?.message || JSON.stringify(error)}`, 
                    'error'
                );
            });
    }
    //Setting the current Target Values
    setCurrentTarget()
    {
        // Filter based on selectedUser (Executive_Id__c)
        this.curTargets = this.targetList.filter(item => item.Executive_Id__c === this.selectedUser);

        // Extract unique Target Logics
        this.uniqueTargetLogics = this.curTargets.reduce((acc, t) => {
            if (t.Target_Logic__c && !acc.some(item => item.Id === t.Target_Logic__c)) {
                acc.push({ Id: t.Target_Logic__c, Name: t.Target_Logic__r?.Name || 'N/A' });
            }
            return acc;
        }, []);

        // Create a Target Logic Map to add the parent Id in Suborinate Target items
        this.targetLogicsWithManagerMap = new Map(
            this.curTargets.map(target => [target.Target_Logic__c, target])
        );

        // Check if current targets exist to show the table
        this.currentTargetExisted = this.curTargets.length > 0;
    }
    //Once Period is changed we are calling this method
    getTargetVsActualData(event) {
        this.selectedPeriod = event.target.value;
        this.selectedAdminPeriod = event.target.value;
        this.setTargetVsActualData();
     
    }
    setTargetVsActualData(){
        this.isLoading = true;
        getTargetActuals({
            period: this.selectedPeriod,
            userId:this.selectedUser
        })
        .then((result) => {
            this.targetList = result;
            this.setCurrentTarget();
            this.aggregateSubordinateTargets();
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

    //Getting the profile permission to show the admin target adding 
    getProfileName() {
        // Find the user in userList that matches selectedUser
        let selectedUserObj = this.userList.find(user => user.Id === this.selectedUser);

        // Check if the profile name is equal to profile name defined in Custom label
        if (selectedUserObj && selectedUserObj.Profile.Name === this.initialTargetAssignmentProfile) {
            this.showAddTarget = true;
        } else {
            this.showAddTarget = false;
        }
    }
    //Getter property to get dynamic class
    get comboboxContainerClass() {
        return this.showAddTarget ? 'combobox-container' : 'combobox-container-no-admin';
    }
    //Once User is Selected 
    userChangeHandler(event) {
        this.selectedUser = event.target.value;
        this.setCurrentTarget();
        this.getProfileName();
    }
   
    
    //Open Subodinate Table   
    openModal() {
        this.resetAll();
        this.openDistrbutionTable = true;
        this.subordinateUsersExisted = false;
        
        // 1st: Get subordinates based on selected manager
        this.subOrdinateUserList = this.userList.filter(user => user.ManagerId === this.selectedUser);
        console.log('Users:', JSON.stringify(this.subOrdinateUserList));
    
        // 2nd: Create a map of existing target items using Target Logic ID + User ID as key
        let targetListCopy = this.targetList.map(target => ({ ...target })); // Create a copy
        let targetMap = new Map();
        targetListCopy.forEach(target => {
            let extId = target.Executive_Id__c + target.Target_Logic__c; // Flip Key to Exec First
            targetMap.set(extId, target);
        });
    
        // 3rd: Create a new map where the key is now Executive Id
        let userTargetMap = new Map();
    
        for (let user of this.subOrdinateUserList) {
            let targetItems = [];
            for (let targetLogic of this.uniqueTargetLogics) {
                let extId = user.Id + targetLogic.Id;
                if (!targetMap.has(extId)) {
                    let newTarget = this.addSubTargetItem(targetLogic, user);
                    targetItems.push(newTarget);
                } else {
                    targetItems.push(targetMap.get(extId));
                }
            }
            // Store user with related target items (including target logics)
            userTargetMap.set(user.Id, { id: user.Id, name: user.Name, targets: targetItems });
        }
    
        // 4th: Convert map to an array for table rendering
        this.targetLogicArray = Array.from(userTargetMap.values());
        console.log('Reversed Target Logic Array:', JSON.stringify(this.targetLogicArray));
    
        // Ensure table header contains only target logics present in data
        this.targetLogicColumns = this.uniqueTargetLogics.map(targetLogic => ({
            Id: targetLogic.Id,
            Name: targetLogic.Name
        }));
        this.logicListSize = 1 + this.targetLogicColumns.length;
        this.subordinateUsersExisted = this.subOrdinateUserList.length > 0 &&
                               this.targetLogicArray.some(item => item.targets && item.targets.length > 0);

    
    }
    //Add Subodinate TargetItem
    addSubTargetItem(logic, user) {
        let newTarget = {
            sobjectType: 'Target_Item__c',
            Target_Logic__r: {
                Id: logic.Id,
                Name: logic.Name
            },
            Target_Logic__c: logic.Id,
            Target_Value__c: '',
            Actual_Value__c: 0,
            Achieved_Percentage__c: 0.0,
            Target__r: {
                Executive__c: user.Id
            },
            Executive_Id__c: user.Id,
            UserName: user.Name,
            Parent__c: this.targetLogicsWithManagerMap.get(logic.Id).Id 
        };
        return newTarget;
    }
    //Target Distribution Value Change
    handleInputChange(event) { 
        const targetLogicId = event.target.dataset.targetlogic;  // Target Logic ID
        const executiveId = event.target.dataset.userid;         // Executive ID
        let newValue = event.target.value ? Number(event.target.value) : ''; // Convert input to number
        const targetId = event.target.dataset.targetid;

        // Get the parent target value (maximum allowed total)
        let parentTarget = this.targetLogicsWithManagerMap.get(targetLogicId);
        if (!parentTarget) {
            console.error("Parent target not found");
            return;
        }
        let parentTargetValue = parentTarget.Target_Value__c || 0; // Parent target max value

        // Get the total value of subordinate targets from the aggregated map
        let totalSubordinateValueOfCurrentTargetUser = this.parentwithtargetValueOfSubodinates.get(targetId) || 0;

    
        let totalSubordinateValue = 0;
        let lastEnteredTarget = null;
    
        // Sum up all existing subordinate values for this Target Logic
        for (let executive of this.targetLogicArray) {
            for (let targetItem of executive.targets) {
                if (targetItem.Target_Logic__c === targetLogicId) {
                    if (targetItem.Executive_Id__c === executiveId) {
                        lastEnteredTarget = targetItem; // Track the field being edited
                    } else {
                        totalSubordinateValue += Number(targetItem.Target_Value__c || 0);
                    }
                }
            }
        }
    
        // Calculate the new total if we accept this input
        let newTotal = totalSubordinateValue + newValue;
    
        if (newTotal > parentTargetValue) {
            let allowedValue = parentTargetValue - totalSubordinateValue;
            if (allowedValue < 0) allowedValue = 0; // Prevent negative values
    
            // Show a warning message
           // this.showToast('Info', `Total subordinate target exceeds Manager Target! Max allowed: ${allowedValue}`, 'info'); 
    
            // Reset the field value to the max allowed
            if (lastEnteredTarget) {
                lastEnteredTarget.Message = `Max value allowed: ${allowedValue}`
                lastEnteredTarget.Max_Value__c = allowedValue;
                lastEnteredTarget.Target_Value__c = newValue;
                //lastEnteredTarget.Target_Value__c = allowedValue;
                //event.target.value = allowedValue; // Update UI
            }
        } 
        else if (newValue < totalSubordinateValueOfCurrentTargetUser) {
            // 🚨 Check if the value is less than the aggregated subordinate value
            //this.showToast('Info', `Target distribution initiated. Minimum value allowed: ${totalSubordinateValueOfCurrentTargetUser}`, 'info');
            
            if (lastEnteredTarget) {
                lastEnteredTarget.Message = `Min value allowed: ${totalSubordinateValueOfCurrentTargetUser}`
                lastEnteredTarget.Min_Value__c = totalSubordinateValueOfCurrentTargetUser;
                lastEnteredTarget.Target_Value__c = newValue;
                //lastEnteredTarget.Target_Value__c = totalSubordinateValueOfCurrentTargetUser;
                //event.target.value = totalSubordinateValueOfCurrentTargetUser;
            }
        }
        else if (lastEnteredTarget) {
            // Update the value if within the limit
            lastEnteredTarget.Target_Value__c = newValue;
        }
    }
    // Save Distribution Target
    saveData() {
        this.isLoading = true;
        // Extract the targets from each targetLogicItem
        const targetItems = this.targetLogicArray.map(targetLogicItem => targetLogicItem.targets).flat();
        // Prepare the parameters
        const targetList = targetItems;

         // Validate if any Target_Value__c is less than Min_Value__c
         const invalidTargets = targetList.filter(
            target => ( target.Target_Value__c < target.Min_Value__c ||  target.Target_Value__c > target.Max_Value__c )
        );
        if (invalidTargets.length > 0) {
            this.isLoading = false;
            this.showToast('Error', 'Target distribution initiated. Please enter the targets in allowed range', 'error');
            return;
        }
        this.openDistrbutionTable = false;
       

        const selectedPeriod = this.selectedPeriod;

        console.log('TargetItems--->'+JSON.stringify(targetList));
        console.log('selectedPeriod--->'+selectedPeriod);

        // Call the Apex method
        saveTargets({ targetList: JSON.stringify(targetList), selctdperiod: selectedPeriod })
        .then(result => {
            this.targetList = result;
            this.resetAll();
            this.aggregateSubordinateTargets();
            this.isLoading = false;// Hide spinner after response
            this.showToast('Success', 'Targets updated sucessfully.', 'success'); // Show success toast
        })
        .catch(error => {
            this.isLoading = false;// Hide spinner on error
            this.showToast('Error', 'There was an issue saving the targets.', 'error'); // Show error toast
        });
    }
    //Clsing Distribution Table
    closeModal()
    {
        this.openDistrbutionTable = false;
        this.resetAll();
    }
    resetAll()
    {
        this.targetLogicArray = [];
        this.subOrdinateUserList = [];
        this.targetLogicColumns = [];
        this.targetLogicMap.clear();
    }

    //User Wise Intail Target Assignment
    //on click on Add Targets
    openAdmintargetPopup()
    {
        this.adminTarget = true;
        this.getUserTargetActuals(this.selectedPeriod);
    }
    //When Add Target Period Changes
    addTargetPeriodChangeHandler(event)
    {
        this.selectedAdminPeriod = event.target.value;
        this.getUserTargetActuals(this.selectedAdminPeriod);
    }
    //Getting user indivial Targets
    getUserTargetActuals(period)
    {
        this.isPopupLoading = true;
        getUserTargetActuals({period: period,userId:this.selectedUser})
        .then((result) => {
            console.log(JSON.stringify(result));
            this.adminTargetItems = result?.targetItems || [];
            this.targetLogics = result?.targetLogics || [];
            this.userTargetsLogicsExisted = this.targetLogics.length > 0 ? true : false;
            this.parentToTotalTargetValueMap = new Map(Object.entries(result?.parentToTotalTargetValueMap || {}));
            this.addAdminTarget();
            this.isPopupLoading = false;
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
    //Setting Targets
    addAdminTarget() {
        // Create a deep copy of targetList
        let targetListCopy = this.adminTargetItems.map(target => ({ ...target }));
    
        // Filter the copied list based on selectedUser
        let adminTargets = targetListCopy.filter(target => target.Executive_Id__c === this.selectedUser);
    
        // Create a map for existing target logics
        let targetMap = new Map();
        adminTargets.forEach(target => targetMap.set(target.Target_Logic__c, target));
    
        let targetItems = [];
    
        for (let targetLogic of this.targetLogics) {
            let extId = targetLogic.Id;
    
            if (!targetMap.has(extId)) {
                // If Target_Logic__c does not exist, add a new target item
                let newTarget = this.addAdminTargetItem(targetLogic, this.selectedUser);
                targetItems.push(newTarget);
            } else {
                // If already exists, use the existing one
                targetItems.push(targetMap.get(extId));
            }
        }
    
        // Store updated target list
        this.adminTargets = targetItems;
       
    
        console.log('Updated adminTargets:', this.adminTargets);
    }
    // Add User Target Item
    addAdminTargetItem(logic, userId) {
        return {
            sobjectType: 'Target_Item__c',
            Target_Logic__r: {
                Id: logic.Id,
                Name: logic.Name,
            },
            Target_Logic__c: logic.Id,
            Target_Value__c: '',
            Actual_Value__c: '',
            Achieved_Percentage__c: 0.0,
            'Target__r.Executive__c': userId
        };
    }
    closeAdminTarget()
    {
        this.adminTarget = false;
    }
    handleTargetChange(event) {
        let targetLogic = event.target.dataset.targetlogic; 
        let newValue = parseFloat(event.target.value) || '';
        let targetItemId = event.target.dataset.id;
    
        console.log('logic:', targetLogic, 'newValue:', newValue, 'targetItemId:', targetItemId);
    
        // Get the total value from the parentToTotalTargetValueMap
        let totalValue = this.parentToTotalTargetValueMap?.get(targetItemId) || 0;
        console.log('totalValue:', totalValue);
    
        if (newValue < totalValue) {
            // Set the minimum value and error message dynamically
            let targetItem = this.adminTargets.find(t => t.Id === targetItemId);
            if (targetItem) {
                targetItem.Min_Value__c = totalValue;
                targetItem.Message = `Min value allowed: ${totalValue}.`;
            }
        }
    
        // Update the adminTargets list
        this.adminTargets = this.adminTargets.map(t => 
            t.Target_Logic__c === targetLogic ? { ...t, Target_Value__c: newValue } : t
        );
    }
    

    //Save User indivial Targets
    saveAdminTarget() {
       
        // Validate if any Target_Value__c is less than Min_Value__c
        const invalidTargets = this.adminTargets.filter(
            target => target.Target_Value__c < target.Min_Value__c
        );
        if (invalidTargets.length > 0) {
            this.isLoading = false;
            this.showToast('Error', `Target distribution initiated. Please enter the targets greater than minimum allowed value.`, 'error');
            return;
        }

        this.adminTarget = false;
        this.isLoading = true;
        // Filter out targets where Target_Value__c > 0
        let filteredAdminTargets = this.adminTargets.filter(target => target.Target_Value__c > 0);
    
        // Call the Apex method with filtered data
        saveAdminTargetActuals({ 
            targetItems: filteredAdminTargets, 
            selectedAdminPeriod: this.selectedAdminPeriod, 
            selectedPeriod: this.selectedPeriod,
            userId:this.selectedUser
        })
        .then(result => {
            this.targetList = result;
            this.setCurrentTarget();
            this.resetAll();
            this.aggregateSubordinateTargets();
            this.isLoading = false; // Hide spinner after response
            this.showToast('Success', 'Admin targets updated successfully', 'success'); // Show success toast
        })
        .catch(error => {
            this.isLoading = false; // Hide spinner on error
            this.showToast('Error', 'There was an issue saving the targets.', 'error'); // Show error toast
        });
    }
    aggregateSubordinateTargets() {
        this.parentwithtargetValueOfSubodinates = new Map();
    
        this.targetList .forEach(target => {
            if (target.Parent__c) {
                let currentTotal = this.parentwithtargetValueOfSubodinates.get(target.Parent__c) || 0;
                this.parentwithtargetValueOfSubodinates.set(target.Parent__c, currentTotal + (target.Target_Value__c || 0));
            }
        });
    
        console.log('Aggregated Map:', this.parentwithtargetValueOfSubodinates);
    }

    //Genric method to get the picklist values
    populateOptions(dataList, labelField, valueField) {
        return dataList?.map(item => ({
            label: item[labelField],
            value: item[valueField]
        })) || [];
    }
    //disabling pul to refresh
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
    //Show Toast
    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
    
}