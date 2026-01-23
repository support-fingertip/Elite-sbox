import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import { CurrentPageReference } from 'lightning/navigation';


import getUserData from '@salesforce/apex/NewBeatController.getUserData';
import upsertAssignments from '@salesforce/apex/NewBeatController.upsertAssignments';
import isAdminOrTSE from '@salesforce/apex/NewBeatController.isAdminOrTSE';
import GET_BEAT_DATA from '@salesforce/apex/NewBeatController.getBeatData';

export default class UserAssignmentPage extends NavigationMixin(LightningElement) {
  @api recordId;
  @api editBeat;

  @track nameFilter = '';
  @track usernameFilter = '';
  @track regionFilter = '';

  @track data = {
    users: [],
    originalUsers: [],
    regionPick: [],
    LoggedInUser: {}
  };

  @track isCreateAssignments = [];
  @track deleteAssignments = [];
  @track canDelete = false;
  isDesktop = true; isSubPartLoad = false;

  connectedCallback() {
    this.isSubPartLoad = true;
    this.fetchPermissions();

    this.getMainUserData();
    /* if (this.recordId) {

      await GET_BEAT_DATA({ beatId: this.recordId }).then(result => {
        console.log(JSON.stringify(result))
        this.beatName = result.beat.Name;
        this.data.beat = result.beat;
        this.data.beatItems = result.beatItems;
        this.data.beatAssignments = result.assignments;

      })
        .then(() => {
          alert(1)
          this.loadExistingBeat();
        });

    } */
  }

  @wire(CurrentPageReference)
  getStateParameters(currentPageReference) {

    if (currentPageReference && !this.editBeat) {
      this.recordId = currentPageReference.state.recordId;

    }
  }

  fetchPermissions() {
    isAdminOrTSE().then(role => {
      this.canDelete = role === 'Admin';
    });
  }

  getMainUserData() {
    this.isSubPartLoad = true;
    getUserData().then(result => {
      console.log(JSON.stringify(result))
      this.data.users = result.users.map(u => {
        return { ...u, isAddButtonShow: true, AssignId: '', Order_Number__c: '' };
      });
      this.data.originalUsers = [...this.data.users];

      this.data.regionPick = [
        { label: 'All', value: 'All' },
        ...result.regionPickList.map(r => ({ label: r, value: r }))
      ];
      this.data.LoggedInUser = result.LoggedInUser;
      this.isSubPartLoad = false;
    }).then(() => {
      if (this.recordId) {

        GET_BEAT_DATA({ beatId: this.recordId }).then(result => {
          console.log(JSON.stringify(result))
          this.beatName = result.beat.Name;
          this.data.beat = result.beat;
          this.data.beatItems = result.beatItems;
          this.data.beatAssignments = result.assignments;

        })
          .then(() => {
            alert(1)
            this.loadExistingBeat();
          });

      }
    });
  }

  handleUserFilterChange(event) {
    const { label, value } = event.target;
    if (label === 'Search by name') this.nameFilter = value;
    if (label === 'Search by Username') this.usernameFilter = value;
    if (label === 'Search by Region') this.regionFilter = value;
    this.applyUserFilters();
  }

  applyUserFilters() {
    this.isSubPartLoad = true;
    let filtered = [...this.data.originalUsers];

    if (this.nameFilter) {
      filtered = filtered.filter(u => u.Name?.toLowerCase().includes(this.nameFilter.toLowerCase()));
    }
    if (this.usernameFilter) {
      filtered = filtered.filter(u => u.Username?.toLowerCase().includes(this.usernameFilter.toLowerCase()));
    }
    if (this.regionFilter && this.regionFilter !== 'All') {
      filtered = filtered.filter(u => u.Region__c?.toLowerCase().includes(this.regionFilter.toLowerCase()));
    }

    this.data.users = filtered;
    this.isSubPartLoad = false;
  }

  handleAddUser(event) {
    const index = parseInt(event.currentTarget.dataset.index, 10);
    this.data.users[index].isAddButtonShow = false;
    this.data.originalUsers.find(u => u.Id === this.data.users[index].Id).isAddButtonShow = false;
    this.updateCreateAssignments();
  }

  handleRemoveUser(event) {
    const index = parseInt(event.currentTarget.dataset.index, 10);
    const user = this.data.users[index];

    user.isAddButtonShow = true;
    this.data.originalUsers.find(u => u.Id === user.Id).isAddButtonShow = true;

    // Initialize deleteAssignments as array if not already
    if (!this.deleteAssignments) {
      this.deleteAssignments = [];
    }

    // Push existing deleteAssignments values
    if (this.deleteAssignments && !Array.isArray(this.deleteAssignments)) {
      this.deleteAssignments = this.deleteAssignments.split(','); // Just in case it's a string somehow
    }

    if (user.AssignId) {
      this.deleteAssignments.push(user.AssignId);
    }

    // Update originalAcc
    const originalIndex = this.data.originalUsers.findIndex(u => u.Id === this.data.users[index].Id);
    if (originalIndex !== -1) {
      this.data.originalUsers[originalIndex].isAddButtonShow = true;
    }


    this.updateCreateAssignments();
  }

  loadExistingBeat() {
    this.isSubPartLoad = true;
    // alert(1)
    const userMap = {};
    this.data.beatAssignments.forEach(u => {
      userMap[u.User__c] = {
        AssignId: u.Id,
        Order_Number__c: u.Order_Number__c
      };
    });

    this.data.users = this.data.users.map(user => {
      const existingUser = userMap[user.Id];
      const updatedUser = {
        ...user,
        isAddButtonShow: !existingUser, // Show add button for new users
        AssignId: existingUser ? existingUser.AssignId : null, // Use existing AssignId or null for new users
        Order_Number__c: existingUser ? existingUser.Order_Number__c : null // Keep existing Order Number or null for new users
      };

      return updatedUser;
    });
    console.log('1111111--------' + JSON.stringify(this.data.users))


    // Update original users with the modified data
    this.data.originalUsers = this.data.originalUsers.map(user => {
      const updatedUser = this.data.users.find(u => u.Id === user.Id);
      return updatedUser ? updatedUser : user;
    });


    /*  // Update account data
     this.data.users = this.data.users.map(user => {
       return {
         ...user,
         isAddButtonShow: !(user.Id in userMap),
         AssignId: userMap[user.Id] || user.AssignId
       };
     }); */


    /*  // ✅ Optimized version of the nested loop using a Map
     const usMap = new Map();
     this.data.users.forEach(user => {
       usMap.set(user.Id, {
         isAddButtonShow: user.isAddButtonShow,
         AssignId: user.AssignId,
         Order_Number__c: user.Order_Number__c
 
       });
     });
 
     this.data.originalUsers = this.data.originalUsers.map(user => {
       const updated = usMap.get(user.Id);
       if (updated) {
         return {
           ...user,
           isAddButtonShow: updated.isAddButtonShow,
           AssignId: updated.AssignId,
           Order_Number__c: updated.Order_Number__c
         };
       }
       return user;
     });
  */
    // this.updateCreateAssignments();
  }

  updateCreateAssignments() {
    this.isSubPartLoad = true;

    this.isCreateAssignments = this.data.originalUsers.filter(acc => acc.isAddButtonShow === false);
    let latestOrderNumber = Math.max(...this.isCreateAssignments.map(user => user.Order_Number__c || 0)); // Default to 0 if Order Number is null
    let newOrderNumber = latestOrderNumber + 1;
    alert('newOrderNumber:' + newOrderNumber)

    this.isCreateAssignments = this.isCreateAssignments.map(pl => {
      return {
        ...pl,
        Order_Number__c: pl.Order_Number__c==0 || !pl.Order_Number__c ? newOrderNumber++: pl.Order_Number__c
      };
    });

  console.log('isCreateAssignments:====' + this.isCreateAssignments);

    this.isSubPartLoad = false;
    /* this.isCreateAssignments = this.data.originalUsers
      .filter(u => u.isAddButtonShow === false)
      .map((u, i) => {
        return {
          User__c: u.Id,
          Beat__c: this.recordId,
          Id: u.AssignmentId || null,
          Order_Number__c: i + 1,
          Active__c: 'Yes'
        };
      }); */
  }

  handleSave() {
    this.isSubPartLoad = true;
    if (this.isCreateAssignments.length === 0) {
      // alert('Please select at least one user.');
      this.genericToastDispatchEvent('Error', 'Please select at least one user.', 'error');
      this.isSubPartLoad = false;
      return;

    }
    const dta = this.isCreateAssignments;

    let beatPlan = dta.map(pl => {
      return {
        User__c: pl.Id,
        Beat__c: this.recordId,
        Id: pl.AssignId || null,
        Order_Number__c: pl.Order_Number__c,
        Active__c: 'Yes',
        OwnerId: pl.Id
      };
    });

    upsertAssignments({
      beatId: this.recordId,
      deleteIds: this.deleteAssignments,
      jnB: beatPlan
    })
      .then(() => {
        this.genericToastDispatchEvent('Success', 'User assignments saved successfully!', 'success');
        this.isSubPartLoad = false;

        this[NavigationMixin.Navigate]({
          type: 'standard__recordPage',
          attributes: {
            recordId: this.recordId,
            objectApiName: 'Child_Beat__c', // your object API name
            actionName: 'view'
          }
        });
      })

      .catch(console.error);
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