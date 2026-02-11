import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { updateRecord, deleteRecord, createRecord } from 'lightning/uiRecordApi';

import ADD_VISIT_DATA from '@salesforce/apex/userProfileLWC.AddVisitData';
import GET_SEC_ACCS from '@salesforce/apex/userProfileLWC.getRelatedAccs';
//import SAVE_VISIT from '@salesforce/apex/userProfileLWC.saveVisit';
import SAVE_BEAT from '@salesforce/apex/userProfileLWC.saveBeat';
import CH_BEAT_OBJECT from '@salesforce/schema/Child_beat__c';

export default class UserProfile_BeatPlan extends LightningElement {

    @api isDesktop = false;
    @api isMobile = false;
    @api isNewBeatCreate = false;
    @api isCloneBeat = false;
    @api beats = [];
    @api selectedId;
    @api calenderBeatId;
    isCreateNewVisit = [];
    isDateDisabled = true; isButton = false; isDSM = false;
    newBeatName = ''; newBeatType = ''; primaryCustomer = ''; secCustomer = '';
    headerName = 'New Beat';

    @track mainBeat = {};

    @api isBeatButton;
    @track filterBeatData = {
        beatSearchKeyword: '',
        beatVal: ''
    };
    @track showDropdown = false; showDropdown2 = false; fieldDisable = false; showCustomerSel = false;
    @track isLoading = false;
    @track filteredBeatOptions = [];

    @track primaryCustomers = [];
    @track filteredCustOptions = [];

    @track secCustomers = [];
    @track filteredSecCustOptions = [];

    showSubStock = false;
    showCustomers = false;


    @track data = {
        acc: [],
        originalAcc: [],
        filteredAcc: [],
        areaPick: [],
        citiesPick: [],
        category: [],
        beatOptions: [],
        regionPick: [],
        typePick: [],
        primTypePick: [],
        LoggedInUser: {}
    }
    filterData = {
        beatVal: '',
        beatValId: '',
        dateVal: new Date().toISOString().split('T')[0],
        citiesPick: 'All',
        category: 'All',
        areaPick: 'All',
        citiesPickVal: 'All',
        categoryValVal: 'All',
        areaPickVal: 'All',
        Name: '',
        regionPickVal: 'All',
        typePickVal: 'All',
        primTypePickVal: 'All',
        regionPick: 'All',
        typePick: 'All'
    };
    isSubPartLoad = false;
    deleteJun = null; selectedAcc = {};

    // Define the options for the object selection dropdown
    get BeatTypeOptions() {
        return [
            { label: 'Select One..', value: '' },
            { label: 'Primary', value: 'Primary' },
            { label: 'Secondary', value: 'Secondary' }
        ];
    }


    handleBeatNameChange(event) {
        this.newBeatName = event.target.value;
        this.mainBeat.Name = this.newBeatName;
    }

    handleBeatTypeChange(event) {
        this.isSubPartLoad = true;
        this.newBeatType = event.target.value;
        this.mainBeat.Beat_Type__c = this.newBeatType;

        //  this.showCustomerSel = this.newBeatType == 'Secondary' ? true : false;

        if (this.newBeatType == 'Primary') {
            this.showCustomerSel = false;
            this.data.acc = [...this.primaryCustomers];
            this.showCustomers = true;

            this.primaryCustomer = null;
            this.mainBeat.Primary_Customer__c = null;
            this.mainBeat.Sub_Stockist__c = null;
            this.secCustomer = null;
            this.data.originalAcc = this.data.acc;

        }
        else if (this.newBeatType == 'Secondary') {
            this.showCustomerSel = true;
            this.showCustomers = false;

        }
        else {
            this.showCustomerSel = false;
            this.showCustomers = false;
            this.primaryCustomer = null;
            this.mainBeat.Primary_Customer__c = null;
            this.mainBeat.Sub_Stockist__c = null;
            this.secCustomer = null;

        }

        this.isSubPartLoad = false;

    }


    connectedCallback() {
        this.handleAddBeat();
        if (!this.isNewBeatCreate && !this.isCloneBeat) {
            this.headerName = 'Edit Beat'; this.fieldDisable = true;
        }
        else if (this.isCloneBeat && !this.isNewBeatCreate) {
            this.headerName = 'Clone Beat'; this.fieldDisable = true;
        }
        else { this.fieldDisable = false; }
    }

    handleAddBeat() {

        this.isSubPartLoad = true;
        ADD_VISIT_DATA({
            ownerId: this.selectedId,
        })
            .then(result => {
                this.data.acc = result.accounts.map(acc => {
                    return { ...acc, isAddButtonShow: true, JunctionId: '', Order_Number__c: '' };
                });

                this.data.originalAcc = this.data.acc;
                console.log(JSON.stringify(this.data.acc))

                this.primaryCustomers = this.data.acc.filter(acc => acc.Customer_Type__c === 'Primary Customer');
                this.secCustomers = this.data.acc.filter(acc => acc.Customer_Type__c === 'Secondary Customer');


                var cat = [{
                    label: 'All',
                    value: 'All'
                }];
                const category = result.categoryPickList;
                for (let i = 0; i < category.length; i++) {
                    cat.push({
                        label: category[i],
                        value: category[i]
                    });
                }

                var reg = [{
                    label: 'All',
                    value: 'All'
                }];
                const region = result.regionPickList;
                for (let i = 0; i < region.length; i++) {
                    reg.push({
                        label: region[i],
                        value: region[i]
                    });
                }

                var div = [{
                    label: 'All',
                    value: 'All'
                }];
                const division = result.typePickList;
                for (let i = 0; i < division.length; i++) {
                    div.push({
                        label: division[i],
                        value: division[i]
                    });
                }

                var div2 = [{
                    label: 'All',
                    value: 'All'
                }];
                const division2 = result.primTypePickList;
                for (let i = 0; i < division2.length; i++) {
                    div2.push({
                        label: division2[i],
                        value: division2[i]
                    });
                }

                /*  var ar = [{
                    label: 'All',
                    value: 'All'
                }];
                const area = JSON.parse(result.addVisitPicklistData[0].Areas);
                 for (let i = 0; i < area.length; i++) {
                     ar.push({
                         label: area[i],
                         value: area[i]
                     });
                 }
 
                 var ct = [{
                     label: 'All',
                     value: 'All'
                 }];
                 const cities = JSON.parse(result.addVisitPicklistData[0].Cities); // Fixed to use Cities
                 for (let i = 0; i < cities.length; i++) {
                     ct.push({
                         label: cities[i],
                         value: cities[i]
                     });
                 }
             */
                // Assign back to data
                this.data.category = cat;
                this.data.regionPick = reg;
                this.data.typePick = div;
                this.data.primTypePick = div2;
                /*   this.data.areaPick = ar;
                  this.data.citiesPick = ct; */
                this.data.LoggedInUser = result.LoggedInUser;
                this.isDSM = this.data.LoggedInUser.Profile.Name === 'DSM' || this.data.LoggedInUser.Profile.Name === 'SSA';

                const dta = this.beats;
                console.log('beatOptions:===========' + this.beats)
                /*  var beatOptions = [];
 
                 for (let i = 0; i < dta.length; i++) {
                     var option = {
                         label: dta[i].beatName,
                         value: dta[i].beatId
                     };
                     beatOptions.push(option);
                 } */
                this.data.beatOptions = dta;

                this.isSubPartLoad = false;
            })
            .catch(error => {
                console.error(error);
                this.isSubPartLoad = false;
            });
    }
    handleCustomerChange(event) {
        this.isSubPartLoad = true;
        const searchKey = event.target.value;
        this.primaryCustomer = searchKey;


        if (searchKey.length > 0) {


            this.filteredCustOptions = this.primaryCustomers.filter(opt =>
                opt.Name.toLowerCase().includes(searchKey.toLowerCase()) ||
                (opt.SAP_Customer_Code__c && opt.SAP_Customer_Code__c.toLowerCase().includes(searchKey.toLowerCase()))
            );

            this.showDropdown = this.filteredCustOptions.length > 0;
        } else {
            this.filteredCustOptions = this.primaryCustomers;
            this.showDropdown = false;
            this.mainBeat.Primary_Customer__c = null;
        }
        this.isSubPartLoad = false;
    }

    handleCustomerSelect(event) {
        this.isSubPartLoad = true;
        const selectedVal = event.currentTarget.dataset.id;
        // alert(selectedVal)

        this.primaryCustomer = event.currentTarget.dataset.name;
        this.mainBeat.Primary_Customer__c = selectedVal;

        // alert(this.mainBeat.Primary_Customer__c)

        const selectedCust = this.primaryCustomers.find(cust => cust.Id === selectedVal);


        if (selectedCust) {
            // Example: checking a field 'Customer_Type__c' for "Super Stockist"
            this.showSubStock = selectedCust.Primary_Customer_Type__c === 'Superstockiest';

            GET_SEC_ACCS({ accId: selectedVal, ownerId: this.selectedId }).then(result => {
                console.log(JSON.stringify(result))
                this.data.acc = result.accounts.map(acc => {
                    return { ...acc, isAddButtonShow: true, JunctionId: '', Order_Number__c: '' };
                });

                this.data.originalAcc = this.data.acc;

                this.secCustomers = this.data.acc.map(acc => ({ ...acc }));

            });

            this.showCustomers = true;

            /*  if (!this.showSubStock) {
                 //we need to filter out the Outlets under the selected Distributor here------------PENDING
                 this.showCustomers = true;
 
             } */
        }
        this.showDropdown = false;
        this.isSubPartLoad = false;

        // Dispatch or call your existing handler
        const changeEvent = new CustomEvent('change', {
            detail: { name: 'primCutomer', value: selectedVal }
        });
        this.dispatchEvent(changeEvent);



    }
    handleSecCustomerChange(event) {
        this.isSubPartLoad = true;
        const searchKey = event.target.value;
        this.secCustomer = searchKey;

        let secCustomers = this.secCustomers.filter(acc => acc.Secondary_Customer_Type__c === 'Sub Stockiest');
        //we need to filter out the Sub-stockist under the selected Super-Stockist here------------PENDING

        if (searchKey.length > 0) {

            this.filteredSecCustOptions = secCustomers.filter(opt =>
                opt.Name.toLowerCase().includes(searchKey.toLowerCase())/*  ||  opt.Username.toLowerCase().includes(searchKey.toLowerCase()) */
            );

            this.showDropdown2 = this.filteredSecCustOptions.length > 0;
        } else {
            this.filteredSecCustOptions = secCustomers;
            console.log('secCustomers:=====' + JSON.stringify(this.secCustomers))
            this.data.acc = [...this.secCustomers];

            this.data.originalAcc = this.data.acc;
            this.mainBeat.Sub_Stockist__c = null;

            this.showDropdown2 = false;
        }
        this.isSubPartLoad = false;
    }

    handleSecCustomerSelect(event) {
        this.isSubPartLoad = true;
        const selectedVal = event.currentTarget.dataset.id;
        // alert(selectedVal)

        this.secCustomer = event.currentTarget.dataset.name;
        this.mainBeat.Sub_Stockist__c = selectedVal;

        const selectedCust = this.secCustomers.find(cust => cust.Id === selectedVal);


        if (selectedCust) {

            GET_SEC_ACCS({ accId: selectedVal, ownerId: this.selectedId }).then(result => {
                console.log(JSON.stringify(result))
                this.data.acc = result.accounts.map(acc => {
                    return { ...acc, isAddButtonShow: true, JunctionId: '', Order_Number__c: '' };
                });

                this.data.originalAcc = this.data.acc;

                // this.secCustomers = this.data.acc;

            });
            this.showCustomers = true;
        }


        this.showDropdown2 = false;
        this.isSubPartLoad = false;


        // Dispatch or call your existing handler
        const changeEvent = new CustomEvent('change', {
            detail: { name: 'secCutomer', value: selectedVal }
        });
        this.dispatchEvent(changeEvent);
    }
    clearSelection() {
        // this.primaryCustomer = null;
        this.secCustomer = null;
        // this.mainBeat.Primary_Customer__c = null;
        this.mainBeat.Sub_Stockist__c = null;

        if (this.newBeatType == 'Primary') {

            this.data.acc = this.primaryCustomers.map(acc => {
                return { ...acc, isAddButtonShow: true, JunctionId: '', Order_Number__c: '' };
            });
        }
        else {
            this.data.acc = this.secCustomers.map(acc => {
                return { ...acc, isAddButtonShow: true, JunctionId: '', Order_Number__c: '' };
            });
        }

        //this.showCustomers = false;

        if (!this.isNewBeatCreate) {
            this.filterData.beatValId = null;
            this.filterBeatData.beatVal = null;
            this.filterBeatData.beatSearchKeyword = null;
            this.mainBeat.Primary_Customer__c = null;
            this.newBeatType = '';
            this.mainBeat.Beat_Type__c = '';
            this.primaryCustomer = null;
            this.showCustomers = false;
            // Dispatch or call your existing handler

        }

    }
    get isSysAdmin() {
        return this.data?.LoggedInUser?.Profile?.Name === 'System Administrator';
    }

    goBack() {
        if (this.isButton)
            return;
        const message = {
            message: 'goBack',
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
    addData(event) {

        const { beatValId } = this.filterData;

        if (!beatValId && !this.isNewBeatCreate) {
            this.genericToastDispatchEvent('Error', 'Please select Beat', 'error');
            return;
        }

        const index = parseInt(event.currentTarget.dataset.index, 10);
        console.log('Add button clicked at index:', index);

        console.log('accs:' + JSON.stringify(this.data.acc))
        console.log('beats:' + JSON.stringify(this.data.beatOptions))

        let account = this.data.acc[index];
        this.selectedAcc = account;

        // const existingBeat = this.data.beatOptions.find(beat => beat.accId === account.Id && account.JunctionId !== null);
        let isAccountAlreadyAssigned = false;

        // Iterate through beatOptions to check if the account is already assigned to a beat
        this.data.beatOptions.forEach(beat => {
            // Check if the account is linked in this beat and JunctionId is not null
            const beatItem = beat.accountList.find(item => item.accId === account.Id && account.JunctionId === "");

            if (beatItem) {
                isAccountAlreadyAssigned = true; // Account is already assigned to another beat
            }
        });

        if (isAccountAlreadyAssigned) {
            const modal = this.template.querySelector('c-custom-confirmation-modal');
            modal.openModal(`This account (${account.Name}) is already assigned to another beat. Are you sure you want to add it again?`);

            // If the account is already assigned to a beat, show a confirmation prompt
            /*  const result = window.confirm(`This account (${account.Name}) is already assigned to another beat. Are you sure you want to add it again?`);
             if (result) {
                 // If the user clicks "OK", proceed with adding the account to the beat
                 this.executeAddAccountToBeat(account);
             } else {
                 // If the user clicks "Cancel", do nothing
                 console.log('Account not added to this beat.');
             } */
        } else {
            // If the account is not assigned to another beat, proceed normally
            this.executeAddAccountToBeat(account);
        }


    }
    handleModalResponse(event) {
        if (event.detail) {
            // User clicked "Yes"
            this.executeAddAccountToBeat(this.selectedAcc);
        } else {
            // User clicked "No"
            console.log('Account not added to this beat.');
        }
    }

    executeAddAccountToBeat(account) {


        // Update displayed data
        account.isAddButtonShow = false;
        if (!this.isNewBeatCreate) {
            let latestOrderNumber = Math.max(...this.data.acc.map(vis => vis.Order_Number__c));
            account.Order_Number__c = latestOrderNumber + 1

        }

        // Update originalAcc
        const originalIndex = this.data.originalAcc.findIndex(acc => acc.Id === account.Id);
        if (originalIndex !== -1) {
            this.data.originalAcc[originalIndex].isAddButtonShow = false;
        }
        const junctionId = account.JunctionId;
        if (junctionId) {
            const deleteIndex = this.deleteJun.indexOf(junctionId);
            if (deleteIndex !== -1) {
                this.deleteJun.splice(deleteIndex, 1);
            }
            // this.deleteJun = this.deleteJun.length != 0? this.deleteJun : [];
        }
        console.log('secCustomers:=====' + JSON.stringify(this.secCustomers))
        // Update isCreateNewVisit (Only keep records where isAddButtonShow is true)
        this.updateCreateNewVisit();
    }


    removeData(event) {

        const index = parseInt(event.currentTarget.dataset.index, 10);
        console.log('Remove button clicked at index:', index);

        // Update displayed data
        this.data.acc[index].isAddButtonShow = true;
        // Initialize deleteJun as array if not already
        if (!this.deleteJun) {
            this.deleteJun = [];
        }

        // Push existing deleteJun values
        if (this.deleteJun && !Array.isArray(this.deleteJun)) {
            this.deleteJun = this.deleteJun.split(','); // Just in case it's a string somehow
        }

        // Push the new JunctionId to delete list
        if (this.data.acc[index].JunctionId !== '') {
            this.deleteJun.push(this.data.acc[index].JunctionId);
        }

        console.log('this.deleteJun:' + JSON.stringify(this.deleteJun))
        // Update originalAcc
        const originalIndex = this.data.originalAcc.findIndex(acc => acc.Id === this.data.acc[index].Id);
        if (originalIndex !== -1) {
            this.data.originalAcc[originalIndex].isAddButtonShow = true;
        }

        // Update isCreateNewVisit (Only keep records where isAddButtonShow is true)
        this.updateCreateNewVisit();
    }

    updateCreateNewVisit() {
        // Store only records where isAddButtonShow is true
        this.isCreateNewVisit = this.data.originalAcc.filter(acc => acc.isAddButtonShow === false);
        let latestOrderNumber = Math.max(...this.isCreateNewVisit.map(vis => vis.Order_Number__c || 0));
        let newOrderNumber = latestOrderNumber + 1;
        //  alert('newOrderNumber:'+newOrderNumber)

        this.isCreateNewVisit = this.isCreateNewVisit.map(pl => {
            return {
                ...pl,
                Order_Number__c: pl.Order_Number__c == 0 || !pl.Order_Number__c ? newOrderNumber++ : pl.Order_Number__c
            };
        });


        console.log('Updated isCreateNewVisit:', this.isCreateNewVisit);
    }

    handleSearchChange(event) {

        const searchKey = event.target.value;
        this.filterBeatData.beatSearchKeyword = searchKey;
        this.isSubPartLoad = true;


        if (searchKey.length > 0) {

            this.filteredBeatOptions = this.data.beatOptions.filter(opt =>
                opt.beatName.toLowerCase().includes(searchKey.toLowerCase())
            );

            this.showDropdown = this.filteredBeatOptions.length > 0;
        } else {
            this.showDropdown = false;
        }
        this.isSubPartLoad = false;
    }

    handleOptionSelect(event) {

        this.isSubPartLoad = true;

        const selectedVal = event.currentTarget.dataset.id;
        // alert('selectedVal:'+selectedVal)
        const selectedLabel = this.data.beatOptions.find(opt => opt.beatId === selectedVal)?.beatName;


        this.filterData.beatValId = selectedVal;
        this.filterBeatData.beatVal = selectedVal;
        this.filterBeatData.beatSearchKeyword = selectedLabel;
        this.showDropdown = false;
        this.showCustomers = true;



        // Update filter data and enable date

        this.isDateDisabled = false;

        // Find the selected beat data
        const beatData = this.beats.find(beat => beat.beatId === selectedVal);

        if (!beatData) return; // Exit if no beat found

        this.mainBeat.Name = selectedLabel;
        this.newBeatName = this.mainBeat.Name;
        this.newBeatType = beatData.mainBeat.Beat_Type__c;
        this.mainBeat.Beat_Type__c = beatData.mainBeat.Beat_Type__c;


        if (beatData.mainBeat.Primary_Customer__c) {
            this.showCustomerSel = true;
            this.mainBeat.Primary_Customer__c = beatData.mainBeat.Primary_Customer__c;
            this.primaryCustomer = beatData.mainBeat.Primary_Customer__r.Name;

            let accId = this.mainBeat.Primary_Customer__c;
            if (beatData.mainBeat.Sub_Stockist__c) {
                this.mainBeat.Sub_Stockist__c = beatData.mainBeat.Sub_Stockist__c;
                this.secCustomer = beatData.mainBeat.Sub_Stockist__r.Name;
                this.showSubStock = true;
                accId = this.mainBeat.Sub_Stockist__c;
            }

            GET_SEC_ACCS({ accId: accId, ownerId: this.selectedId }).then(result => {
                console.log(JSON.stringify(result))
                this.data.acc = result.accounts.map(acc => {
                    return { ...acc, isAddButtonShow: true, JunctionId: '', Order_Number__c: '' };
                });
                this.data.originalAcc = this.data.acc;
            }).then(() => {

                const accountMap = {};
                beatData.accountList.forEach(account => {
                    accountMap[account.accId] = {
                        JunctionId: this.isCloneBeat ? null : account.JuncId,
                        Order_Number__c: account.orderNumber

                    };
                });


                this.data.acc = this.data.acc.map(account => {
                    const existingAcc = accountMap[account.Id];
                    const updatedAcc = {
                        ...account,
                        isAddButtonShow: !existingAcc,
                        JunctionId: existingAcc ? existingAcc.JunctionId : null,
                        Order_Number__c: existingAcc ? existingAcc.Order_Number__c : null
                    };

                    return updatedAcc;
                });

                // Update original users with the modified data
                this.data.originalAcc = this.data.originalAcc.map(account => {
                    const updatedAcc = this.data.acc.find(a => a.Id === account.Id);
                    return updatedAcc ? updatedAcc : account;
                });
                this.isSubPartLoad = false;

                this.updateCreateNewVisit();

            });

        }
        else {
            this.primaryCustomer = null;
            this.mainBeat.Primary_Customer__c = null;
            this.mainBeat.Sub_Stockist__c = null;
            this.secCustomer = null;

            this.showCustomerSel = false;
            this.data.acc = [...this.primaryCustomers];
            this.data.originalAcc = this.data.acc;

            const accountMap = {};
            beatData.accountList.forEach(account => {
                accountMap[account.accId] = {
                    JunctionId: this.isCloneBeat ? null : account.JuncId,
                    Order_Number__c: account.orderNumber

                };
            });


            this.data.acc = this.data.acc.map(account => {
                const existingAcc = accountMap[account.Id];
                const updatedAcc = {
                    ...account,
                    isAddButtonShow: !existingAcc,
                    JunctionId: existingAcc ? existingAcc.JunctionId : null,
                    Order_Number__c: existingAcc ? existingAcc.Order_Number__c : null
                };

                return updatedAcc;
            });

            // Update original users with the modified data
            this.data.originalAcc = this.data.originalAcc.map(account => {
                const updatedAcc = this.data.acc.find(a => a.Id === account.Id);
                return updatedAcc ? updatedAcc : account;
            });
            this.isSubPartLoad = false;

            this.updateCreateNewVisit();

        }


        // Dispatch or call your existing handler
        const changeEvent = new CustomEvent('change', {
            detail: { name: 'beat', value: selectedVal }
        });
        this.dispatchEvent(changeEvent);
    }


    handleFilterChange(event) {

        const { name, value } = event.target;

        // Update selected filter values
        this.filterData = { ...this.filterData, [name]: value };
        if (name == 'cate') {
            this.filterData.categoryValVal = value;

            // this.filterDataVal(value,'CustomerCategory');
        }
        else if (name == 'area') {
            this.filterData.areaPickVal = value;
            // this.filterDataVal(value,'Area');
        }
        else if (name == 'city') {
            this.filterData.citiesPickVal = value;
            // this.filterDataVal(value,'City');            
        }
        else if (name == 'reg') {
            this.filterData.regionPickVal = value;
            // this.filterDataVal(value,'Area');
        }
        else if (name == 'div') {
            this.filterData.typePickVal = value;
            // this.filterDataVal(value,'City');            
        }
        else if (name == 'div2') {
            this.filterData.primTypePickVal = value;
            // this.filterDataVal(value,'City');            
        }
        this.filterFunValues();

    }
    filterFunValues() {
        this.isSubPartLoad = true;
        // Extract filter values
        const { areaPickVal = 'All', citiesPickVal = 'All', categoryValVal = 'All', regionPickVal = 'All', typePickVal = 'All', primTypePickVal = 'All' } = this.filterData;

        // Start with original data
        let filteredDta = [...this.data.originalAcc];

        // Apply filters dynamically (only filter if a value other than "All" is selected)
        if (areaPickVal !== 'All') {
            filteredDta = filteredDta.filter(acc =>
                acc.Area__c && acc.Area__c.toLowerCase().includes(areaPickVal.toLowerCase())
            );
        }

        if (citiesPickVal !== 'All') {
            filteredDta = filteredDta.filter(acc =>
                acc.City__c && acc.City__c.toLowerCase().includes(citiesPickVal.toLowerCase())
            );
        }

        if (categoryValVal !== 'All') {
            filteredDta = filteredDta.filter(acc =>
                acc.Customer_Category__c && acc.Customer_Category__c.toLowerCase().includes(categoryValVal.toLowerCase())
            );
        }

        if (regionPickVal !== 'All') {
            filteredDta = filteredDta.filter(acc =>
                acc.Region__c && acc.Region__c.toLowerCase().includes(regionPickVal.toLowerCase())
            );
        }

        if (typePickVal !== 'All') {
            filteredDta = filteredDta.filter(acc =>
                acc.Secondary_Customer_Type__c && acc.Secondary_Customer_Type__c.toLowerCase().includes(typePickVal.toLowerCase())
            );
        }
        if (primTypePickVal !== 'All') {
            filteredDta = filteredDta.filter(acc =>
                acc.Primary_Customer_Type__c && acc.Primary_Customer_Type__c.toLowerCase().includes(primTypePickVal.toLowerCase())
            );
        }

        // Update displayed data
        this.data.acc = filteredDta;
        this.isSubPartLoad = false;
    }
    onSearchName(event) {
        this.isSubPartLoad = true;
        const { name, value } = event.target;
        this.filterData.Name = value

        if (value == "") {
            this.filterFunValues();
        } else {
            var filteredDta = this.data.acc;
            filteredDta = filteredDta.filter(acc =>
                acc.Name && acc.Name.toLowerCase().includes(value.toLowerCase()) ||
                (acc.Customer_Code__c && acc.Customer_Code__c.toLowerCase().includes(value.toLowerCase())) ||
                (acc.SAP_Customer_Code__c && acc.SAP_Customer_Code__c.toLowerCase().includes(value.toLowerCase()))
            );
            this.data.acc = filteredDta;
        }
        this.isSubPartLoad = false;
    }

    handleNewBeat() {
        this.isSubPartLoad = true;
        const { beatValId } = this.filterData;
        console.log('beats400: ' + JSON.stringify(this.beats));
        let latestOrderNumber = this.beats.length > 0 ? Math.max(...this.beats.map(beat => beat.orderNumber)) : 0;
        let newOrderNumber = latestOrderNumber + 1;



        if (!this.mainBeat.Name) {
            this.genericToastDispatchEvent('Error', 'Please enter Beat Name', 'error');
            this.isSubPartLoad = false;
            return;
        }
        else if (this.mainBeat.Beat_Type__c == 'Secondary' && !this.mainBeat.Primary_Customer__c) {
            this.genericToastDispatchEvent('Error', 'Please select Primary Customer', 'error');
            this.isSubPartLoad = false;
            return;
        }


        if (this.isNewBeatCreate || this.isCloneBeat) {

            const fields = {
                OwnerId: this.selectedId,
                User__c: this.selectedId,
                /* Calendar_beat__c: this.calenderBeatId, */
                Name: this.mainBeat.Name,
                Beat_Type__c: this.mainBeat.Beat_Type__c,
                Primary_Customer__c: this.mainBeat.Primary_Customer__c,
                Sub_Stockist__c: this.mainBeat.Sub_Stockist__c,
                Order_Number__c: newOrderNumber++
            };
            const recordInput = { apiName: CH_BEAT_OBJECT.objectApiName, fields };
            createRecord(recordInput)
                .then((result) => {
                    console.log(result.id);
                    this.beatValId = result.id;

                    this.handleSaveVisit(this.beatValId);


                })
                .catch((error) => {

                    console.error('Error creating record:', error);
                    this.isSubPartLoad = false;
                });

        }
        else {

            this.handleSaveVisit(beatValId);
        }

        this.isSubPartLoad = false;

    }

    handleSaveVisit(beatValId) {

        this.isSubPartLoad = false;
        if (beatValId == '') {
            this.genericToastDispatchEvent('Error', 'Please select Beat', 'error');
            this.isSubPartLoad = false;
            return;
        }
        /*   if (!this.validateDate()) {
              return;
          } */

        const dta = this.isCreateNewVisit;
        /* if (dta.length == 0) {
            if (this.deleteJun == null) {
                this.genericToastDispatchEvent('', 'Please select Customer', 'info');
                return;
            }
    
        } */

        console.log('dta: ' + JSON.stringify(dta))
        const betDta = this.beats.find(b => b.beatId === beatValId);

        let beatPlan = dta.map(pl => {
            return {
                Account__c: pl.Id,
                Child_beat__c: beatValId,
                OwnerId: this.selectedId,
                Id: pl.JunctionId != '' ? pl.JunctionId : null,
                Order_Number__c: pl.Order_Number__c
            };
        });
        this.isButton = true;

        SAVE_BEAT({
            deleteIds: this.deleteJun,
            jnB: beatPlan
        })
            .then(result => {
                console.log(result);
                this.isButton = false;
                this.genericToastDispatchEvent('Success', 'Beat created', 'success');
                const message = {
                    message: 'visitCreated',
                };
                this.genericDispatchEvent(message);
                this.isSubPartLoad = false;
            })
            .catch(error => {
                console.log(error);
                this.isButton = false;
                this.isSubPartLoad = false;
            });

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


    /*   handleDateChange(event) {
     const { value } = event.target;
     this.filterData.dateVal = value;

     if (!this.validateDate()) {
         return;
     }
 }
 validateDate() {
     const value = this.filterData.dateVal;
     const selectedDate = new Date(value);
     const currentDate = new Date();

     // Get the start and end of the current month
     const startOfMonth = new Date(currentDate.getFullYear(), currentDate.getMonth(), 1);
     const endOfMonth = new Date(currentDate.getFullYear(), currentDate.getMonth() + 1, 0);

     // Check if selected date is within the current month
     if (selectedDate >= startOfMonth && selectedDate <= endOfMonth) {
         console.log("Valid Date Selected:", value);
         return true;
     } else {
         this.genericToastDispatchEvent('', 'Please select a date within the current month.', 'warning');
         return false;
     }
 }

handleBeatChange(event) {
        this.isSubPartLoad = true;
        // Get the selected value from the event
        const value = event.target.value;
 
        // Update filter data and enable date
        this.filterData.beatValId = value;
        this.isDateDisabled = false;
 
        // Find the selected beat data
        const beatData = this.beats.find(beat => beat.beatId === value);
 
        if (!beatData) return; // Exit if no beat found
 
 
        // Create account ID and junction ID map
        const accountMap = {};
        beatData.accountList.forEach(account => {
            accountMap[account.accId] = account.JuncId;
        });
 
 
        // Update account data
        this.data.acc = this.data.acc.map(account => {
            return {
                ...account,
                isAddButtonShow: !(account.Id in accountMap),
                JunctionId: accountMap[account.Id] || account.JunctionId,
            };
        });
 
 
        // ✅ Optimized version of the nested loop using a Map
        const accMap = new Map();
        this.data.acc.forEach(account => {
            accMap.set(account.Id, {
                isAddButtonShow: account.isAddButtonShow,
                JunctionId: account.JunctionId
            });
        });
 
        this.data.originalAcc = this.data.originalAcc.map(account => {
            const updated = accMap.get(account.Id);
            if (updated) {
                return {
                    ...account,
                    isAddButtonShow: updated.isAddButtonShow,
                    JunctionId: updated.JunctionId
                };
            }
            return account;
        });
        this.updateCreateNewVisit();
    } */

}