import { LightningElement, api, wire, track } from 'lwc';
import getSubordinates from '@salesforce/apex/EmployeeSubordinateController.getSubordinates';

export default class EmployeeSubordinateList extends LightningElement {
    @api recordId;
    @track allUsers = [];
    @track visibleUsers = [];
    @track isExpanded = false;

    @wire(getSubordinates, { employeeId: '$recordId' })
    wiredUsers({ error, data }) {
        if (data) {
            this.allUsers = data;
            this.visibleUsers = data.slice(0, 2);
        } else if (error) {
            console.error('Error loading users:', error);
        }
    }
    get hasUsers() {
        return this.visibleUsers.length > 0;
    }

    toggleView() {
        this.isExpanded = !this.isExpanded;
        this.visibleUsers = this.isExpanded ? this.allUsers : this.allUsers.slice(0, 2);
    }

    get showToggle() {
        return this.allUsers.length > 2;
    }

    get toggleLabel() {
        return this.isExpanded ? 'View Less' : 'View More';
    }

    navigateToEmployee(event) {
        const empId = event.currentTarget.dataset.id;
        const url = `/lightning/r/Employee__c/${empId}/view`;
        window.open(url, '_blank');
    }
}