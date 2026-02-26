import { LightningElement, api, wire, track } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';

// FIX 1: Correct field API names — CreatedDate (capital C & D), Owner.Name added
const FIELDS = [
    'Visit_Form__c.Name',
    'Visit_Form__c.Customer_Name__c',
    'Visit_Form__c.Visit_Type__c',
    'Visit_Form__c.CreatedDate',
    'Visit_Form__c.Owner.Name'
];

export default class VisitDetail extends LightningElement {
    @api recordId;

    @track visitRecord = null;
    @track isLoading = true;
    @track hasError = false;

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredRecord({ error, data }) {
        if (data) {
            const fields = data.fields;
            this.visitRecord = {
                Customer_Name__c: fields.Customer_Name__c?.value || '—',
                Visit_Type__c:    fields.Visit_Type__c?.value || '—',
                createdDate:      fields.CreatedDate?.value,   // FIX 2: was fields.CreatedDate (correct now)
                Owner: {
                    Name: fields.Owner?.value?.fields?.Name?.value || '—'  // FIX 3: correct path
                }
            };
            this.isLoading = false;
            this.hasError = false;
        } else if (error) {
            this.hasError = true;
            this.isLoading = false;
            console.error('VisitDetail wire error:', JSON.stringify(error));
        }
    }

    get formattedDate() {
        if (!this.visitRecord?.createdDate) return '—';
        return new Date(this.visitRecord.createdDate).toLocaleDateString('en-IN', {
            day: '2-digit', month: 'short', year: 'numeric'
        });
    }

    get formattedTime() {
        if (!this.visitRecord?.createdDate) return '—';
        // FIX 4: CreatedDate is a full ISO string like "2024-01-15T09:36:00.000Z"
        // DO NOT split by ':' — use Date object instead
        return new Date(this.visitRecord.createdDate).toLocaleTimeString('en-IN', {
            hour: '2-digit', minute: '2-digit', hour12: true
        });
    }

    get statusBadgeClass() {
        const status = (this.visitRecord?.Status__c || '').toLowerCase();
        if (status === 'completed') return 'status-badge status-badge--completed';
        if (status === 'pending')   return 'status-badge status-badge--pending';
        if (status === 'cancelled') return 'status-badge status-badge--cancelled';
        return 'status-badge';
    }

    handleClose() {
        // FIX 5: Event name changed from 'back' → 'close' to match parent onclose={handleCloseDetail}
        this.dispatchEvent(new CustomEvent('close'));
    }
}