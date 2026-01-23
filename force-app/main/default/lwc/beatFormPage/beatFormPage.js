import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';

import saveOrUpdateBeat from '@salesforce/apex/NewBeatController.saveOrUpdateBeat';
import GET_VALUES from '@salesforce/apex/NewBeatController.getValues';
import isAdminOrTSE from '@salesforce/apex/NewBeatController.isAdminOrTSE';
import GET_MAIN_DATA from '@salesforce/apex/NewBeatController.getData';
import GET_BEAT_DATA from '@salesforce/apex/NewBeatController.getBeatData';
import GET_Acc_Map from '@salesforce/apex/NewBeatController.getAccountMap';

export default class BeatFormPage extends NavigationMixin(LightningElement) {
    @api recordId;
    isDesktop = true;
    isMobile = false; isSubPartLoad = false;
    @track mainBeat = {};
    @track beatName = '';
    @track beatRegion = '';
    @track accounts = [];
    @track accountNameFilter = '';
    @track customerTypeFilter = '';
    @track regionFilter = '';
    @track existingAccountIds = [];
    @track existingBeatAccounts = [];
    @track canDelete = false;
    @track isNewBeatCreate = false;
    isCreateNewVisit = [];
    deleteJun = null;
    headerName = 'New Beat';
    filterData = {
        beatVal: '',
        beatValId: '',
        Name: '',
        regionPickVal: 'All',
        typePickVal: 'All',
        regionPick: 'All',
        typePick: 'All'
    };
    @track data = {
        acc: [],
        originalAcc: [],
        filteredAcc: [],
        beatOptions: [],
        regionPick: [],
        typePick: [],
        LoggedInUser: {},
        beat: {},
        beatItems: [],
        beatAssignments: []
    }
    @track showDropdown = false;
    @track isLoading = false;
    @track filteredUserOptions = [];

    @track primaryCustomers = [];
     @track filteredCustOptions = [];


    connectedCallback() {
        this.isSubPartLoad = true;
        this.checkPermissions();

        this.getValues();

        // this.getMainData();
        if (this.recordId) {
            GET_BEAT_DATA({ beatId: this.recordId }).then(result => {
                console.log(JSON.stringify(result))
                this.beatName = result.beat.Name;
                this.beatRegion = result.beat.Region__c;
                this.data.beat = result.beat;
                this.data.beatItems = result.beatItems;
                this.data.beatAssignments = result.assignments;

                this.loadExistingBeat();
            });
            this.headerName = 'Edit Beat';
        }
    }

    getValues() {
        GET_VALUES({}).then(result => {

            var reg = [];
            const region = result.regionPickList;
            for (let i = 0; i < region.length; i++) {
                reg.push({
                    label: region[i],
                    value: region[i]
                });
            }

            var custType = [{
                label: 'All',
                value: 'All'
            }];
            const type = result.custTypePickList;
            for (let i = 0; i < type.length; i++) {
                custType.push({
                    label: type[i],
                    value: type[i]
                });
            }

            this.data.regionPick = reg;
            this.data.typePick = custType;
            this.data.LoggedInUser = result.LoggedInUser;
            this.isSubPartLoad = false;


        }).catch(console.error);
    }

    getMainData() {
        GET_MAIN_DATA({ region: this.mainBeat.Region__c }).then(result => {
            this.data.acc = result.accounts.map(acc => {
                return { ...acc, isAddButtonShow: true, JunctionId: '', Order_Number__c: '' };
            });
            this.data.originalAcc = this.data.acc;
            this.data.users = result.users;
            this.data.orginalUsers = result.users;
            // Store accounts with customer type 'primary customer' in a separate list
            this.primaryCustomers = this.data.acc.filter(acc => acc.Customer_Type__c === 'Primary Customer');


            this.isSubPartLoad = false;

            /*   var reg = [{
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
  
              var custType = [{
                  label: 'All',
                  value: 'All'
              }];
              const type = result.custTypePickList;
              for (let i = 0; i < type.length; i++) {
                  custType.push({
                      label: type[i],
                      value: type[i]
                  });
              }
  
              this.data.regionPick = reg;
              this.data.typePick = custType;
              this.data.LoggedInUser = result.LoggedInUser;
  
              console.log(JSON.stringify(this.data)) */


            /* 
            this.accounts = result.map(acc => ({
                ...acc,
                isAdded: this.existingAccountIds.includes(acc.Id)
            })); */

        }).catch(console.error);
    }

    onSearchName(event) {
        const { name, value } = event.target;
        this.filterData.Name = value


        if (value == "" && !this.filterData.userName) {
            console.log(1)
            this.filterFunValues();
        }
        else if (value == "" && this.filterData.userName) {
            console.log(2)
            this.data.acc = this.accounts;
        }
        else if (value != "" && this.filterData.userName) {
            console.log(3)
            var filteredDta = this.accounts;
            filteredDta = filteredDta.filter(acc =>
                acc.Name && acc.Name.toLowerCase().includes(value.toLowerCase())
            );
            this.data.acc = filteredDta;
        }
        else {
            console.log(4)
            var filteredDta = this.data.acc;
            filteredDta = filteredDta.filter(acc =>
                acc.Name && acc.Name.toLowerCase().includes(value.toLowerCase())
            );
            this.data.acc = filteredDta;
        }
    }

    handleSearchChange(event) {
        this.isLoading = true;
        const searchKey = event.target.value;
        this.filterData.userName = searchKey;


        if (searchKey.length > 0) {


            this.filteredUserOptions = this.data.users.filter(opt =>
                opt.Name.toLowerCase().includes(searchKey.toLowerCase())/*  ||  opt.Username.toLowerCase().includes(searchKey.toLowerCase()) */
            );
            console.log(JSON.stringify(this.data.users))
            this.showDropdown = this.filteredUserOptions.length > 0;
        } else {
            this.filterFunValues();
            this.showDropdown = false;
        }
        this.isLoading = false;
    }

    handleOptionSelect(event) {
        const selectedVal = event.currentTarget.dataset.id;
        // alert(selectedVal)

        this.filterData.userName = event.currentTarget.dataset.name;

        GET_Acc_Map({ userId: selectedVal }).then(result => {
            console.log(JSON.stringify(result))
            this.data.acc = result.accounts.map(acc => {
                return { ...acc, isAddButtonShow: true };
            });

            if (this.recordId) {
                this.loadExistingBeat();
            }

            this.accounts = this.data.acc;
        });
        this.showDropdown = false;

        // Dispatch or call your existing handler
        const changeEvent = new CustomEvent('change', {
            detail: { name: 'user', value: selectedVal }
        });
        this.dispatchEvent(changeEvent);
    }

    handleFilterChange(event) {
        const { name, value } = event.target;

        // Update selected filter values
        this.filterData = { ...this.filterData, [name]: value };

        if (name == 'reg') {
            this.filterData.regionPickVal = value;
            // this.filterDataVal(value,'Area');
        }
        else if (name == 'type') {
            this.filterData.typePickVal = value;
            // this.filterDataVal(value,'City');            
        }
        this.filterFunValues();

    }

    filterFunValues() {
        this.isSubPartLoad = true;
        // Extract filter values
        const { regionPickVal = 'All', typePickVal = 'All' } = this.filterData;

        // Start with original data
        let filteredDta = [...this.data.originalAcc];
        let filteredUsers = [...this.data.orginalUsers];

        if (regionPickVal !== 'All') {
            filteredDta = filteredDta.filter(acc =>
                acc.Region__c && acc.Region__c.toLowerCase().includes(regionPickVal.toLowerCase())
            );
            filteredUsers = filteredUsers.filter(u =>
                u.Region__c && u.Region__c.toLowerCase().includes(regionPickVal.toLowerCase())
            );

        }

        if (typePickVal !== 'All') {
            filteredDta = filteredDta.filter(acc =>
                acc.Customer_Type__c && acc.Customer_Type__c.toLowerCase().includes(typePickVal.toLowerCase())
            );
        }

        // Update displayed data
        this.data.acc = filteredDta;
        this.data.users = filteredUsers;
        this.isSubPartLoad = false;
    }

    checkPermissions() {
        isAdminOrTSE().then(role => {
            this.canDelete = role === 'Admin';
        }).catch(console.error);
    }

    loadExistingBeat() {
        // alert(1)
        this.isSubPartLoad = true;

        const accountMap = {};
        this.data.beatItems.forEach(account => {
            accountMap[account.Account__c] = {
                JunctionId: account.Id,
                Order_Number__c: account.Order_Number__c

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


        /*   // Update account data
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
   */


        // this.updateCreateNewVisit();
    }

    handleBeatNameChange(event) {
        this.beatName = event.target.value;
        this.mainBeat.Name = this.beatName;
    }
    handleBeatRegChange(event) {
        this.isSubPartLoad = true;
        this.beatRegion = event.target.value;
        this.mainBeat.Region__c = this.beatRegion;

        this.getMainData();

    }

    handleCustomerChange(event) {
        this.isLoading = true;
        const searchKey = event.target.value;
        this.filterData.userName = searchKey;


        if (searchKey.length > 0) {


            this.filteredCustOptions = this.data.primaryCustomers.filter(opt =>
                opt.Name.toLowerCase().includes(searchKey.toLowerCase())/*  ||  opt.Username.toLowerCase().includes(searchKey.toLowerCase()) */
            );
            console.log(JSON.stringify(this.data.users))
            this.showDropdown = this.filteredCustOptions.length > 0;
        } else {
            this.filteredCustOptions = this.data.primaryCustomers;
            this.showDropdown = false;
        }
        this.isLoading = false;
    }

    handleCustomerSelect(event) {
        const selectedVal = event.currentTarget.dataset.id;
        // alert(selectedVal)

        this.filterData.userName = event.currentTarget.dataset.name;

        GET_Acc_Map({ userId: selectedVal }).then(result => {
            console.log(JSON.stringify(result))
            this.data.acc = result.accounts.map(acc => {
                return { ...acc, isAddButtonShow: true };
            });

            if (this.recordId) {
                this.loadExistingBeat();
            }

            this.accounts = this.data.acc;
        });
        this.showDropdown = false;

        // Dispatch or call your existing handler
        const changeEvent = new CustomEvent('change', {
            detail: { name: 'user', value: selectedVal }
        });
        this.dispatchEvent(changeEvent);
    }

    addData(event) {

        const index = parseInt(event.currentTarget.dataset.index, 10);
        this.data.acc[index].isAddButtonShow = false;
        this.data.originalAcc.find(u => u.Id === this.data.acc[index].Id).isAddButtonShow = false;
        this.updateCreateNewVisit();

        /* const { beatValId } = this.filterData;

        if (!beatValId && !this.isNewBeatCreate) {
            this.genericToastDispatchEvent('Error', 'Please select Beat', 'error');
            return;
        } */

        /*  const index = parseInt(event.currentTarget.dataset.index, 10);
         console.log('Add button clicked at index:', index);
 
         // Update displayed data
         this.data.acc[index].isAddButtonShow = false;
         if (!this.isNewBeatCreate) {
             let latestOrderNumber = Math.max(...this.data.acc.map(vis => vis.Order_Number__c));
             this.data.acc[index].Order_Number__c = latestOrderNumber + 1
 
         }
 
         // Update originalAcc
         const originalIndex = this.data.originalAcc.findIndex(acc => acc.Id === this.data.acc[index].Id);
         if (originalIndex !== -1) {
             this.data.originalAcc[originalIndex].isAddButtonShow = false;
         }
         const junctionId = this.data.acc[index].JunctionId;
         if (junctionId) {
             const deleteIndex = this.deleteJun.indexOf(junctionId);
             if (deleteIndex !== -1) {
                 this.deleteJun.splice(deleteIndex, 1);
             }
             // this.deleteJun = this.deleteJun.length != 0? this.deleteJun : [];
         }
         // Update isCreateNewVisit (Only keep records where isAddButtonShow is true)
         this.updateCreateNewVisit(); */
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
        let latestOrderNumber = Math.max(...this.isCreateNewVisit.map(acc => acc.Order_Number__c || 0));
        let newOrderNumber = latestOrderNumber + 1;
        //  alert('newOrderNumber:'+newOrderNumber)

        this.isCreateNewVisit = this.isCreateNewVisit.map(pl => {
            return {
                ...pl,
                Order_Number__c: pl.Order_Number__c == 0 || !pl.Order_Number__c ? newOrderNumber++ : pl.Order_Number__c
            };
        });

        console.log('Updated isCreateNewVisit:', this.isCreateNewVisit);
        this.isSubPartLoad = false;
    }

    handleSaveAndNext() {

        this.isSubPartLoad = true;

        const dta = this.isCreateNewVisit;

        let beatPlan = dta.map(pl => {
            return {
                Account__c: pl.Id,
                Child_beat__c: this.recordId,
                Id: pl.JunctionId != '' ? pl.JunctionId : null,
                Order_Number__c: pl.Order_Number__c
            };
        });

        if (!this.beatName) {
            //alert('Please enter a Beat Name and select at least one Account.');
            this.genericToastDispatchEvent('Error', 'Please enter a Beat Name.', 'error');
            this.isSubPartLoad = false;
            return;
        }
        else if (this.isCreateNewVisit.length === 0) {
            this.genericToastDispatchEvent('Error', 'Please select at least one Account.', 'error');
            this.isSubPartLoad = false;
            return;
        }

        saveOrUpdateBeat({
            name: this.beatName, region: this.beatRegion, beatId: this.recordId, deleteIds: this.deleteJun,
            jnB: beatPlan
        })
            .then(result => {

                console.log('result: ' + JSON.stringify(result));

                this.data.beat = result.beat;
                this.data.beatItems = result.beatItems;
                this.recordId = result.beatId;

                this.genericToastDispatchEvent('Success', 'Beat Saved Successfully!', 'success');
                this.isSubPartLoad = false;

            })
            .then(() => {

                this.dispatchEvent(new CustomEvent('nextpage', {
                    detail: { beatId: this.recordId }
                }));
            })
            .catch(console.error);
    }

    handleSaveAndNew() {

    }

    handleSave() {

    }

    handleCancel() {
        if (this.recordId) {
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: this.recordId,
                    objectApiName: 'Child_Beat__c', // your object API name
                    actionName: 'view'
                }
            });
        }
        else {
            this[NavigationMixin.Navigate]({
                type: 'standard__objectPage',
                attributes: {
                    objectApiName: 'Child_Beat__c',
                    actionName: 'list'
                },
                state: {
                    filterName: 'All' // Optional: filter like 'All' or a custom list view Id
                }
            });
        }

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