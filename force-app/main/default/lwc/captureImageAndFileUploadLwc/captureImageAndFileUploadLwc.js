import { LightningElement,api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import FORM_FACTOR from '@salesforce/client/formFactor';
import getFiles from '@salesforce/apex/beatPlannerlwc.getFiles';
import deleteFile from '@salesforce/apex/beatPlannerlwc.deleteFile';
import updateDocument from '@salesforce/apex/beatPlannerlwc.updateDocument';

export default class CaptureImageAndFileUploadLwc extends NavigationMixin(LightningElement){
    showCameraModal = false;
    @api recordId;
    @api uniqueId;
    isLoading = false;
    isDesktop = false;
    isPhone = false;   
    isCameraOpen = true;
    loadingScreenSize = 2;
    uploadedFiles = [];
    showUploadedFiles = false;
    
    connectedCallback() {
        this.isDesktop = FORM_FACTOR === 'Large'? true : false;
        this.isPhone = FORM_FACTOR === 'Small'? true : false;
        if (FORM_FACTOR === 'Medium') this.isDesktop = true;
        this.loadingScreenSize =   this.isDesktop ? 2 : 3;
        this.customClass = this.isDesktop ? 'slds-size_1-of-2' : 'slds-size_1-of-1';
    }
    openCamera()
    {
        this.showCameraModal = true;
    }
    handleCameraStopped()
    {
        this.showCameraModal = false;
            this.loadAllFiles();
    }
    handleUploadFinished(event) {
        const files = event.detail.files;
        const fileIds = files.map(file => file.documentId);
        
        if(this.uniqueId )
        {
            this.isLoading = true;
            updateDocument({ idList: fileIds, uniqueId: this.uniqueId })
            .then(() => {
                this.showToast('Success','Files uploaded successfully!', 'success');
                this.loadAllFiles();
            })
            .catch(err => {
                console.error('Upload error:', err);
                this.showToast('Upload failed', 'error');
                this.isLoading = false;
            });
        }
    }  
    loadAllFiles() {
        this.isLoading = true;
    
        getFiles({ uniqueId: this.uniqueId, recordId : this.recordId})
        .then(result => {
            this.uploadedFiles = result || [];
            this.showUploadedFiles = this.uploadedFiles.length > 0;
        })
        .catch(error => {
            console.error('Error loading files:', error);
        })
        .finally(() => {
            this.isLoading = false;
        });
    }
    async deleteFile(event) {
        if (confirm('Confirm deleting this file?')) {
            const fileId = event.currentTarget.dataset.id;
            this.isLoading = true;
            try {
                await deleteFile({ contentDocumentId: fileId });
                this.showToast('Success','File has been deleted successfully!', 'Success');
                this.loadAllFiles();
            } catch (err) {
                console.error('Delete error', err);
                this.showToast('Error','Deletion failed', 'error');
            }
            this.isLoading = false;
        }
    }
    previewFile(event) {
        let recordId = event.currentTarget.dataset.id;
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


    /**Helper Methods**/
    showToast(message, type) {
        this.dispatchEvent(new ShowToastEvent({
            message,
            variant: type,
            duration: 2000
        }));
    }

}