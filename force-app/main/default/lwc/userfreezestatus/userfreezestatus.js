import { LightningElement, api, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import getUserFreezeStatus from '@salesforce/apex/UserFreezeStatusController.getUserFreezeStatus';
import unfreezeUser from '@salesforce/apex/UserFreezeStatusController.unfreezeUser';

export default class UserFreezeStatus extends LightningElement {
    @api recordId; // Employee__c record Id

    @track isLoading = false;
    @track unfreezing = false;

    _wiredResult;

    @wire(getUserFreezeStatus, { employeeId: '$recordId' })
    wiredStatus(result) {
        this._wiredResult = result;
    }

    get freezeData() {
        return this._wiredResult?.data;
    }

    get isFrozen() {
        return this._wiredResult?.data?.isFrozen === true;
    }

    get freezeReason() {
        return this._wiredResult?.data?.freezeReason || 'suspicious activity';
    }

    get userName() {
        return this._wiredResult?.data?.userName || 'User';
    }

    get freezeReasonLabel() {
        const reason = this.freezeReason;
        if (reason === 'VPN') return 'VPN / Anonymizing Proxy Usage';
        if (reason === 'MultipleLogins') return 'Multiple Failed Login Attempts || VPN / Anonymizing Proxy Usage';
        return 'Suspicious Activity';
    }

    get freezeReasonIcon() {
        const reason = this.freezeReason;
        if (reason === 'VPN') return 'utility:shield';
        if (reason === 'MultipleLogins') return 'utility:key';
        return 'utility:warning';
    }

    get freezeReasonDescription() {
        const reason = this.freezeReason;
        if (reason === 'VPN') {
            return 'Salesforce detected login activity through an anonymizing proxy (e.g. TOR, Mullvad VPN). Access was suspended to protect your organization\'s data.';
        }
        if (reason === 'MultipleLogins') {
            return 'Multiple failed login attempts were detected on this account. Access was suspended as a security precaution.';
        }
        return 'Unusual activity was detected on this account. Access was suspended to protect your organization\'s data.';
    }

    async handleUnfreeze() {
        this.unfreezing = true;
        try {
            await unfreezeUser({ employeeId: this.recordId });
            this.dispatchEvent(new ShowToastEvent({
                title: 'User Unfrozen',
                message: `${this.userName} has been successfully unfrozen and can now access Salesforce.`,
                variant: 'success'
            }));
            await refreshApex(this._wiredResult);
        } catch (error) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error Unfreezing User',
                message: error?.body?.message || 'An unexpected error occurred.',
                variant: 'error'
            }));
        } finally {
            this.unfreezing = false;
        }
    }
}