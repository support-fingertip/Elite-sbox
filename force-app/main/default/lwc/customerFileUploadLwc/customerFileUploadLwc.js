import { LightningElement, api, track,wire  } from 'lwc';
import getFiles from '@salesforce/apex/CustomerFileUploadController.getFiles';
import getFilesBatch from '@salesforce/apex/CustomerFileUploadController.getFilesBatch';
import deleteFile from '@salesforce/apex/CustomerFileUploadController.deleteFile';
import updateDocument from '@salesforce/apex/CustomerFileUploadController.updateDocument';
import getCustomerType from '@salesforce/apex/CustomerFileUploadController.getCustomerType';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import FORM_FACTOR from '@salesforce/client/formFactor';

export default class CustomerFileUploadLwc extends NavigationMixin(LightningElement){
    @api recordId;
    @api uniqueId;
    @api customerPremises;
    @api childComponent= false;
    @api customerType = 'Primary Customer';
    @track isLoading = false;
    @track showFiles = true;
    @track cardTitle = '';
    @track showDelete = true;
    @track profileName = '';    
    isDesktop = false;
    isPhone = false;
    customClass = 'slds-size_1-of-2';
    cameraclss = 'slds-p-around_medium';
    @track showCameraModal = false;
    @track selectedCategory = '';
    isCameraPermission = false;
    allCategories = [
        { name: 'Store-Image', label: 'Store Image', files: [], hasFiles: false, showCamera: true, required:true },
        { name: 'Pan-Card', label: 'PAN Card', files: [], hasFiles: false, showCamera: false, required:true },
        { name: 'Aadar-Card', label: 'Aadhar Card', files: [], hasFiles: false, showCamera: false, required:true },
        { name: 'Commercial-Certificate', label: 'Commercial Certificate', files: [], hasFiles: false, showCamera: false, required:true },
        { name: 'GST-Certificate', label: 'GST Certificate', files: [], hasFiles: false, showCamera: false, required:true },
        { name: 'Cheque-Copy', label: 'Cheque Copy', files: [], hasFiles: false, showCamera: false, required:true },
        { name: 'Additional-Documents', label: 'Additional Documents', files: [], hasFiles: false, showCamera: false, required:false },
    ];

    @track fileCategories = [];


    connectedCallback() {
        if (!navigator.onLine) {
            this.showToast('Error', 'No internet connection. Please check your network and try again.', 'error');
            return;
        }
        this.isDesktop = FORM_FACTOR === 'Large'? true : false;
        this.isPhone = FORM_FACTOR === 'Small'? true : false;
        if (FORM_FACTOR === 'Medium') this.isDesktop = true;
        this.customClass = this.isDesktop ? 'slds-size_1-of-2' : 'slds-size_1-of-1';
        if (!this.childComponent) {
            this.cardTitle = 'Mandatory Document Upload';
            this.cameraclss = 'slds-p-around_medium';
            this.showFiles = false;
            this.getCustomerType();
        } else {
            this.cardTitle = ''; 
            this.cameraclss = '';
            if (this.customerType === 'Primary Customer') {
                if (this.customerPremises === false) {
                    this.fileCategories = this.allCategories.filter(
                        category => category.name !== 'Store-Image'
                    );
                } else {
                    this.fileCategories = this.allCategories;
                }
            } else if (this.customerType === 'Secondary Customer') {
                // Only Store-Image
                this.fileCategories = this.allCategories.filter(cat => cat.name === 'Store-Image' || cat.name === 'Additional-Documents'  );
            }
            this.loadAllFiles();
        }

       
    }
    async getCustomerType() {
        this.isLoading = true;
        try {
            const result = await getCustomerType({
                recordId: this.recordId
            });
            this.customerType = result.customerType;
            this.profileName = result.profileName;
            this.customerPremises = result.customerPremises;
            if (this.customerType === 'Primary Customer') {
                if (this.customerPremises === false) {
                    this.fileCategories = this.allCategories.filter(
                        category => category.name !== 'Store-Image'
                    );
                } else {
                    this.fileCategories = this.allCategories;
                }
            } else if (this.customerType === 'Secondary Customer') {
                // Only Store-Image
                this.fileCategories = this.allCategories.filter(cat => cat.name === 'Store-Image' || cat.name === 'Additional-Documents'  );
            }
            if(this.profileName == 'System Administrator')
            {
                this.showDelete = true;
            }
            else
            {
                this.showDelete = false;
            }
            this.loadAllFiles();
        
        } catch (err) {
            console.error('Error loading files', err);
        }
        this.isLoading = false;
    }

    get toggleLabel() {
        return this.showFiles ? 'Hide Files' : 'Show Files';
    }

    toggleShowFiles() {
        this.showFiles = !this.showFiles;
    }

    async loadAllFiles() {
        if (!navigator.onLine) {
            this.showToast('Error', 'No internet connection. Please check your network and try again.', 'error');
            return;
        }
        this.isLoading = true;
        try {
            const categoryNames = this.fileCategories.map(cat => cat.name);
            const resultMap = await getFilesBatch({
                recordId: this.recordId,
                filterNames: categoryNames,
                uniqueId: this.uniqueId
            });
    
            this.fileCategories = this.fileCategories.map(category => {
                const files = resultMap[category.name] || [];
                files.forEach(file => {
                    file.SystemModstamp = new Date(file.SystemModstamp);
                });
                return {
                    ...category,
                    files,
                    hasFiles: files.length > 0
                };
            });
        } catch (err) {
            console.error('Error loading files', err);
        }
        this.isLoading = false;
    }


    async handleUploadFinished(event) {
        if (!navigator.onLine) {
            this.showToast('Error', 'No internet connection. Please check your network and try again.', 'error');
            return;
        }
        const sectionName = event.target.name;
        const files = event.detail.files;
        const fileIds = files.map(file => file.documentId);

        try {
            await updateDocument({ prefixName: sectionName, idList: fileIds,uniqueId:this.uniqueId });
            this.showToast('Files uploaded successfully!', 'success');
            await this.loadAllFiles();
        } catch (err) {
            console.error('Upload error', err);
            this.showToast('Upload failed', 'error');
        }
    }

    async deleteFile(event) {
        if (!navigator.onLine) {
            this.showToast('Error', 'No internet connection. Please check your network and try again.', 'error');
            return;
        }
        if (confirm('Confirm deleting this file?')) {
        const fileId = event.currentTarget.dataset.id;
        this.isLoading = true;
        try {
            await deleteFile({ contentDocumentId: fileId });
            this.showToast('File has been deleted successfully!', 'success');
            await this.loadAllFiles();
        } catch (err) {
            console.error('Delete error', err);
            this.showToast('Deletion failed', 'error');
        }
        this.isLoading = false;
        }
    }

    previewFile(event) {
        if (!navigator.onLine) {
            this.showToast('Error', 'No internet connection. Please check your network and try again.', 'error');
            return;
        }
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
    
    handleCameraStopped()
    {
        this.showCameraModal = false;
        this.loadAllFiles();
    }
    openCameraForCategory()
    {
        this.showCameraModal = true;
    }


    showToast(message, type) {
        this.dispatchEvent(new ShowToastEvent({
            message,
            variant: type,
            duration: 2000
        }));
    }
}