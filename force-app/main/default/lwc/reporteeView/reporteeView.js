import { LightningElement, track } from 'lwc';
import getSubordinates from '@salesforce/apex/ReporteeViewController.getSubordinates';
import getSubordinateBeats from '@salesforce/apex/ReporteeViewController.getSubordinateBeats';

export default class ReporteeView extends LightningElement {
    @track subordinates = [];
    @track beats = [];
    @track selectedSubordinateId = null;
    @track searchTerm = '';
    @track isLoadingSubordinates = false;
    @track isLoadingBeats = false;
    @track errorMessage = '';

    connectedCallback() {
        this.loadSubordinates();
    }

    loadSubordinates() {
        this.isLoadingSubordinates = true;
        getSubordinates()
            .then(result => {
                this.subordinates = result;
                this.isLoadingSubordinates = false;
            })
            .catch(error => {
                this.errorMessage = error.body ? error.body.message : error.message;
                this.isLoadingSubordinates = false;
            });
    }

    get filteredSubordinates() {
        if (!this.searchTerm) return this.subordinates;
        const term = this.searchTerm.toLowerCase();
        return this.subordinates.filter(s => s.name.toLowerCase().includes(term));
    }

    handleSearch(event) {
        this.searchTerm = event.target.value;
    }

    handleSubordinateSelect(event) {
        this.selectedSubordinateId = event.currentTarget.dataset.userid;
        this.beats = [];
        this.isLoadingBeats = true;
        getSubordinateBeats({ subordinateUserId: this.selectedSubordinateId })
            .then(result => {
                this.beats = result;
                this.isLoadingBeats = false;
            })
            .catch(error => {
                this.errorMessage = error.body ? error.body.message : error.message;
                this.isLoadingBeats = false;
            });
    }

    handleStartVisit(event) {
        const beatId = event.currentTarget.dataset.beatid;
        const beat = this.beats.find(b => b.beatId === beatId);
        const subordinateUserId = this.selectedSubordinateId;
        this.dispatchEvent(new CustomEvent('startsubordinatevisit', {
            bubbles: true,
            composed: true,
            detail: { beatId, subordinateUserId, beatName: beat ? beat.beatName : '' }
        }));
    }

    get hasSubordinates() {
        return this.filteredSubordinates && this.filteredSubordinates.length > 0;
    }

    get hasBeats() {
        return this.beats && this.beats.length > 0;
    }

    get selectedSubordinateName() {
        if (!this.selectedSubordinateId) return '';
        const sub = this.subordinates.find(s => s.userId === this.selectedSubordinateId);
        return sub ? sub.name : '';
    }
}
