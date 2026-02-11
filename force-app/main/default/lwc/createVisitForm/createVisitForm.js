import { LightningElement,api,track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import deleteFile from '@salesforce/apex/beatPlannerlwc.deleteFile';
import createLead from '@salesforce/apex/beatPlannerlwc.createLead'; // Your custom save method


export default class CreateVisitForm extends NavigationMixin(LightningElement) {
    @api isDesktop;
    @track name = '';
    @track phone = '';
    @track location = '';
    @track photoDocId = '';
    @track photoUrl = '';
    @api recordId;
    @track isDisabled = false;
    containerClass;
    uploadedDocIds = [];
    acceptedFormats = ['.jpg', '.jpeg', '.png'];
    connectedCallback(){
        this.containerClass = this.isDesktop ? 'slds-modal__container ' : '';
        
    }
    handleInputChange(event) {
        const field = event.target.name;
        this[field] = event.target.value;
    }

    handleUploadFinished(event) {
        const uploadedFiles = event.detail.files;
    
        uploadedFiles.forEach(file => {
            let files = {name:file.name,id:file.documentId}
            this.uploadedDocIds.push(files);
        });
    
        // Trigger UI re-render if needed
        this.uploadedDocIds = [...this.uploadedDocIds];
    }

    async handleSave() {

        if (!this.name || this.name.trim() === '') {
            this.showToast('Error', 'Please enter the Mandatory Fields.', 'error');
            return;
        }
        const phoneRegex = /^\d{10}$/;
        if (!phoneRegex.test(this.phone)) {
            this.showToast('Error', 'Please Enter 10 Digit Mobile Number', 'error');
            return;
        }
        try {
            this.isDisabled = true;

            const result = await createLead({
                name: this.name,
                phone: this.phone,
                location: this.location,
                photoDocIds: this.uploadedDocIds.map(file => file.id),
                visitId: this.recordId
            });

            // Dispatch leadcreated event to parent
            this.dispatchEvent(new CustomEvent('leadcreated', {
                detail: {
                    Id: result.lead.Id,
                    LastName: result.lead.LastName,
                    Phone: result.lead.Phone,
                    Street: result.lead.Street,
                    Photo_URL__c: result.photoUrl
                },
                bubbles: true,
                composed: true
            }));

            this.closeModal();

        } catch (error) {
            console.error('Error saving lead:', error);
        } finally {
            this.isDisabled = false;
        }
    }

    closeModal() {
        // Dispatch closemodal event to parent
        this.dispatchEvent(new CustomEvent('closemodal', {
            bubbles: true,
            composed: true
        }));
    }
    previewFile(event) {
            const recordId = event.currentTarget.dataset.id;
          //  const filetype = event.currentTarget.id
            this[NavigationMixin.Navigate]({
                type: 'standard__namedPage',
                attributes: {
                    pageName: 'filePreview'
                },
                state: {
                    selectedRecordId: recordId
                }
            });
        }

        showToast(title, message, variant) {
            const evt = new ShowToastEvent({
                title,
                message,
                variant
            });
            this.dispatchEvent(evt);
        }

        async deleteFile(event) {
            console.log('Event received:', event);
            console.log('event.currentTarget.dataset:', event.currentTarget.dataset);
            
            const fileId = event.currentTarget.dataset.id;
            console.log('FileId::::::::::::::> ' + fileId);
        
            if (!fileId) {
                this.showToast('Error', 'File ID not found. Check the HTML data-id attribute.', 'error');
                return;
            }
        
            if (confirm('Confirm deleting this file?')) {
                this.isLoading = true;
                try {
                    await deleteFile({ contentDocumentId: fileId });
                    this.uploadedDocIds = this.uploadedDocIds.filter(file => file.id !== fileId);
                    this.showToast('Success', 'File has been deleted successfully!', 'success');
                } catch (err) {
                    console.error('Delete error', err);
                    this.showToast('Error', 'Deletion failed', 'error');
                } finally {
                    this.isLoading = false;
                }
            }
        }
}