import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import cloneBeatAndItems from '@salesforce/apex/CloneBeatController.cloneBeatAndItems'; // Apex controller method
import getActiveUsers from '@salesforce/apex/CloneBeatController.getActiveUsers'; // Apex to fetch active users
import { NavigationMixin } from 'lightning/navigation';
import { CurrentPageReference } from 'lightning/navigation';
import { getRecord } from 'lightning/uiRecordApi'; // Get record from Lightning Data Service

// Fields to get from the Beat__c record
const BEAT_FIELDS = ['Beat__c.Name'];

export default class CloneBeatToNewUser extends NavigationMixin(LightningElement) {
    @api recordId;  // The beat Id passed from the page context
    @track clonedBeatName;  // Cloned Beat Name
    @track userOptions = [];  // Options for the combobox (active users)
    selectedUserId = '';  // Store the selected user's Id
    @track beatId = '';
    searchQuery = '';  // User input for searching users
    @track filteredUsers = [];  // Filtered users for search

    // Fetch the active users list on component load
    connectedCallback() {
        this.fetchActiveUsers();

    }
    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {

        if (currentPageReference && !this.editBeat) {
            const beatId = currentPageReference.state.recordId;
            this.beatId = beatId; // Store the beat Id
            this.clonedBeatName = 'Cloned - ' + beatId; // Auto-fill with a placeholder name

        }
    }

    // Use Lightning Data Service to fetch the current Beat Name
    @wire(getRecord, { recordId: '$beatId', fields: BEAT_FIELDS })
    wiredBeat({ error, data }) {
        if (data) {
            this.clonedBeatName = data.fields.Name.value; // Prefill with the current Beat's name
        } else if (error) {
            console.error('Error fetching beat name:', error);
        }
    }

    // Fetch active users from the Apex method
    fetchActiveUsers() {
        getActiveUsers()
            .then(data => {
                this.userOptions = data.map(user => ({
                    label: user.Name,  // Display the user's name
                    value: user.Id     // Store the user's ID
                }));
                this.filteredUsers = this.userOptions; // Initially show all users
            })
            .catch(error => {
                console.error('Error fetching active users:', error);
            });
    }

    // Handle search input change
    handleSearchQueryChange(event) {
        this.searchQuery = event.target.value;
        // Filter users based on the search query
        this.filterUsers();
    }

    // Filter users based on the search query
    filterUsers() {
        if (this.searchQuery) {
            this.filteredUsers = this.userOptions.filter(user =>
                user.label.toLowerCase().includes(this.searchQuery.toLowerCase())
            );
        } else {
            this.filteredUsers = this.userOptions; // Show all users if no search query
        }
    }

    // Handle user selection from listbox
    handleUserSelection(event) {
        this.selectedUserId = event.target.value;
    }

    // Handle cloned Beat name change
    handleClonedBeatNameChange(event) {
        this.clonedBeatName = event.target.value;
    }

    // Handle cloning logic when button is clicked
    handleClone() {
        if (!this.clonedBeatName || !this.selectedUserId) {
            //  alert('Please fill in both the cloned beat name and select a user.');
            return;
        }

        // Call the Apex method to clone the Beat and its related items
        cloneBeatAndItems({
            beatId: this.recordId,
            clonedBeatName: this.clonedBeatName,
            userName: this.selectedUserId
        })
            .then(result => {
                //  alert('Cloned Beat successfully! New Beat ID: ' + result);
                console.log('Cloned Beat ID: ', result); // You can redirect to the new Beat page or perform further actions
            })
            .catch(error => {
                console.error('Error cloning Beat: ', error);
                // alert('Error cloning Beat');
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
}