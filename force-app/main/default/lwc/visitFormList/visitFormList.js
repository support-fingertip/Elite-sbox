import { LightningElement, track } from 'lwc';
import getTodayVisitForms from '@salesforce/apex/VisitFormController.getTodayVisitForms';
import GOOGLE_ICONS from '@salesforce/resourceUrl/googleIcons';

export default class VisitFormList extends LightningElement {
    @track visitForms = [];
    @track searchTerm = '';
    accountIcon = GOOGLE_ICONS + '/googleIcons/apartment.png';
    forwardIcon = GOOGLE_ICONS + '/googleIcons/forward.png';
    isPageLoaded = false;

    connectedCallback() {
        this.fetchVisitForms();
    }

    fetchVisitForms() {
        this.isPageLoaded = true;
        getTodayVisitForms({ searchTerm: this.searchTerm })
            .then(result => {
                this.visitForms = result.map(vf => ({
                    Id: vf.Id,
                    AccountName: vf.Customer_Name__c ? vf.Customer_Name__c : '',
                    VisitType: vf.Visit_Type__c,
                    Status: 'Completed',
                    CreatedTime: vf.CreatedDate ? new Date(vf.CreatedDate).toLocaleTimeString() : ''
                }));
                this.isPageLoaded = false;
            })
            .catch(error => {
                this.visitForms = [];
            });
    }

    handleSearch(event) {
        this.searchTerm = event.target.value;
        this.fetchVisitForms();
    }

    handleVisitClick(event) {
        const id = event.currentTarget.dataset.id;
        this.dispatchEvent(new CustomEvent('visitselect', { detail: { id } }));
    }
}