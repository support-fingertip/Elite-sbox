import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getSubordinates from '@salesforce/apex/ReporteeViewController.getSubordinates';
import getSubordinateBeats from '@salesforce/apex/ReporteeViewController.getSubordinateBeats';

export default class ReporteeView extends LightningElement {
    @track subordinates = [];
    @track subordinateBeats = [];
    @track searchTerm = '';
    @track isLoading = false;
    @track isBeatsLoading = false;
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
                    listItemClass: 'subordinate-item'
                }));
            })
            .catch(error => {
                console.error('Error loading subordinates:', error);
                this.showToast('Error', error?.body?.message || 'Failed to load reportees.', 'error');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    get filteredSubordinates() {
        const term = (this.searchTerm || '').toLowerCase();
        return this.subordinates
            .filter(sub => !term || sub.userName.toLowerCase().includes(term))
            .map(sub => ({
                ...sub,
                listItemClass: sub.userId === this.selectedSubordinateId
                    ? 'subordinate-item selected'
                    : 'subordinate-item'
            }));
    }

    get hasSubordinates() {
        return this.filteredSubordinates.length > 0;
    }

    get hasBeats() {
        return this.subordinateBeats.length > 0;
    }

    handleSearch(event) {
        this.searchTerm = event.detail.value;
    }

    handleSubordinateSelect(event) {
        const userId = event.currentTarget.dataset.id;
        if (!userId) return;
        this.selectedSubordinateId = userId;
        const sub = this.subordinates.find(s => s.userId === userId);
        this.selectedSubordinateName = sub ? sub.userName : '';
        this.loadSubordinateBeats(userId);
    }

    loadSubordinateBeats(userId) {
        this.isBeatsLoading = true;
        this.subordinateBeats = [];
        getSubordinateBeats({ subordinateUserId: userId })
            .then(result => {
                this.subordinateBeats = result;
            })
            .catch(error => {
                console.error('Error loading beats:', error);
                this.showToast('Error', error?.body?.message || 'Failed to load beats.', 'error');
            })
            .finally(() => {
                this.isBeatsLoading = false;
            });
    }

    handleStartVisit(event) {
        const beatId = event.currentTarget.dataset.beatId;
        // Dispatch event to parent beatPlannerLWC to start visit for this beat
        this.dispatchEvent(new CustomEvent('reporteestarvisit', {
            detail: { beatId: beatId, subordinateUserId: this.selectedSubordinateId }
        }));
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}
