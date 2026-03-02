import { LightningElement, track } from 'lwc';
import getTodayVisitForms from '@salesforce/apex/VisitFormController.getTodayVisitForms';
import GOOGLE_ICONS from '@salesforce/resourceUrl/googleIcons';

export default class VisitFormList extends LightningElement {
    @track visitForms = [];
    allVisitForms = [];
    @track searchTerm = '';
    accountIcon = GOOGLE_ICONS + '/googleIcons/apartment.png';
    forwardIcon = GOOGLE_ICONS + '/googleIcons/forward.png';
    isPageLoaded = false;

    connectedCallback() {
        this.fetchVisitForms();
    }

    fetchVisitForms() {
        this.isPageLoaded = true;
        getTodayVisitForms({ searchTerm: '' }) // Fetch ALL on first load
            .then(result => {
                this.allVisitForms = result.map(vf => ({
                    Id: vf.Id,
                    AccountName: vf.Customer_Name__c ? vf.Customer_Name__c : '',
                    VisitType: vf.Visit_Type__c,
                    Status: 'Completed',
                    CreatedTime: vf.CreatedDate ? new Date(vf.CreatedDate).toLocaleTimeString() : ''
                }));
                this.visitForms = [...this.allVisitForms];
                this.isPageLoaded = false;
            })
            .catch(error => {
                this.visitForms = [];
                this.allVisitForms = [];
            });
    }

    handleSearch(event) {
        this.searchTerm = event.target.value;
        const term = this.searchTerm ? this.searchTerm.toLowerCase() : '';
        if(term) {
            this.visitForms = this.allVisitForms.filter(form =>
                (form.AccountName && form.AccountName.toLowerCase().includes(term)) ||
                (form.VisitType && form.VisitType.toLowerCase().includes(term))
            );
        } else {
            this.visitForms = [...this.allVisitForms];
        }
    }

    handleVisitClick(event) {
        const id = event.currentTarget.dataset.id;
        this.dispatchEvent(new CustomEvent('visitselect', { detail: { id } }));
    }
}