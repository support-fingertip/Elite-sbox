import { LightningElement, track } from 'lwc';
import getSubordinates from '@salesforce/apex/ReporteeViewController.getSubordinates';
import getSubordinateBeats from '@salesforce/apex/ReporteeViewController.getSubordinateBeats';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class ReporteeView extends LightningElement {
    @track subordinates = [];
    @track filteredSubordinates = [];
    @track beats = [];
    @track isLoading = false;
    @track isBeatsLoading = false;
    @track searchTerm = '';
    @track selectedSubordinateId = null;
    @track selectedSubordinateName = '';

    connectedCallback() {
        this.loadSubordinates();
    }

    loadSubordinates() {
        this.isLoading = true;
        getSubordinates()
            .then(result => {
                this.subordinates = result.map(sub => ({
                    ...sub,
                    itemClass: 'subordinate-item'
                }));
                this.filteredSubordinates = [...this.subordinates];
            })
            .catch(error => {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error',
                    message: error.body ? error.body.message : error.message,
                    variant: 'error'
                }));
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    handleSearchSubordinate(event) {
        this.searchTerm = event.target.value;
        const searchLower = this.searchTerm.toLowerCase();
        this.filteredSubordinates = this.subordinates.filter(sub =>
            sub.userName.toLowerCase().includes(searchLower) ||
            (sub.roleName && sub.roleName.toLowerCase().includes(searchLower))
        );
    }

    handleSubordinateSelect(event) {
        const userId = event.currentTarget.dataset.id;
        this.selectedSubordinateId = userId;
        const sub = this.subordinates.find(s => s.userId === userId);
        this.selectedSubordinateName = sub ? sub.userName : '';

        // Highlight selected
        this.filteredSubordinates = this.filteredSubordinates.map(s => ({
            ...s,
            itemClass: s.userId === userId ? 'subordinate-item selected' : 'subordinate-item'
        }));

        this.loadSubordinateBeats(userId);
    }

    loadSubordinateBeats(userId) {
        this.isBeatsLoading = true;
        this.beats = [];
        getSubordinateBeats({ subordinateUserId: userId })
            .then(result => {
                this.beats = result;
            })
            .catch(error => {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error',
                    message: error.body ? error.body.message : error.message,
                    variant: 'error'
                }));
            })
            .finally(() => {
                this.isBeatsLoading = false;
            });
    }

    handleStartBeat(event) {
        const beatId = event.currentTarget.dataset.beatId;
        const beatName = event.currentTarget.dataset.beatName;
        this.dispatchEvent(new CustomEvent('reporteebeat', {
            detail: {
                beatId: beatId,
                beatName: beatName,
                subordinateUserId: this.selectedSubordinateId
            }
        }));
    }
}
