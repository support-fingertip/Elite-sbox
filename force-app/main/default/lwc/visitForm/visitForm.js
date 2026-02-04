import { LightningElement, wire, track } from 'lwc';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import VISIT_OBJECT from '@salesforce/schema/Visit_Form__c';

export default class VisitForm extends LightningElement {

    @track recordTypeOptions = [];
    @track selectedRecordTypeId;
    @track showForm = false;

    // Get Record Types
    @wire(getObjectInfo, { objectApiName: VISIT_OBJECT })
    objectInfo({ data, error }) {
        if (data) {

            const rtInfos = data.recordTypeInfos;

            this.recordTypeOptions = Object.keys(rtInfos)
                .filter(id => rtInfos[id].available === true && !rtInfos[id].master)
                .map(id => {
                    return {
                        label: rtInfos[id].name,
                        value: id
                    };
                });
        }
    }

    handleRecordTypeChange(event) {
        this.selectedRecordTypeId = event.detail.value;
        this.showForm = true;
    }

    handleSuccess(event) {

        // Send created record id to parent if needed
        this.dispatchEvent(new CustomEvent('close', {
            detail: {
                recordId: event.detail.id
            }
        }));
    }

    handleCancel() {
        this.dispatchEvent(new CustomEvent('close'));
    }
}