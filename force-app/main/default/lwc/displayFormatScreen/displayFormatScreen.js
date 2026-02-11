import { LightningElement, wire, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import deleteFile from '@salesforce/apex/beatPlannerlwc.deleteFile';
import getDisplayFormats from '@salesforce/apex/beatPlannerlwc.getDisplayFormats';
import saveDisplayFormat from '@salesforce/apex/beatPlannerlwc.saveDisplayFormat';
import { NavigationMixin } from 'lightning/navigation';
import Id from '@salesforce/user/Id';
import getFiles from '@salesforce/apex/beatPlannerlwc.getFilescompetetion';
import updateDocument from '@salesforce/apex/beatPlannerlwc.updateDocument';
import VALIDATE_FILE from '@salesforce/apex/beatPlannerlwc.validateVisitFileUpload';

export default class DisplayFormatScreen extends NavigationMixin(LightningElement) {
    userId = Id;
    @track uniqueId='';
    @track formatData = [];
    @track selectedItem = {};
    @track isLoading = true;
    @track isModalOpen = false;
    @track isDeleteModalOpen = false;
    @track showPopup = false;
    @track formatDataExisted = false;
    @track uploadedDocIds = [];
    @track modalTitle = 'Add Display Format';
    @track sku = '';
    @track displayValue = '';
    @track selectedId;
    isimagecapture;
    loadingScreenSize = 2;

    searchedSKUData = [];
    isSKUValueSearched = false;
    selectedSKUId = null;

    @api isDesktop;
    @api recordId;
    @api acccountId; 
    @api visitId; 
    @api visitData;
    @track productList = [];
    searchValueName = ''
    showUploadedFiles = false;
    showCameraModal = false;
    isPopLoading = false;
    uploadedFiles = [];
    displayFormatData = {};
    isCameraOpen = true;


    connectedCallback() {
        this.containerClass = this.isDesktop ? 'slds-modal__container' : '';
        this.loadFormats();
    }

    loadFormats() {
        this.isLoading = true;
        console.log(this.acccountId);
        getDisplayFormats({visitId: this.visitId,accountId:this.recordId})
        .then(result => {
            this.productList = result.productList;
            this.formatData = result.displayformatData.map(item => ({
                id: item.Id,
                skuid : item.SKU__c,
                skuName: item.SKU__r.Name ,
                displayValue: item.Display__c,
                openPopup: false
            }));
            this.formatDataExisted = this.formatData.length > 0;
            setTimeout(() => {
                window.scrollTo({
                    top: 0,
                    behavior: 'smooth'
                });
            }, 0);
        })
        .catch(error => {
            console.error('Error loading formats', error);
        })
        .finally(() => {
            this.isLoading = false;
        });
    }
    openMenu(event) {
        const index = event.currentTarget.dataset.index;
        this.formatData = this.formatData.map((item, idx) => {
            return {
                ...item,
                openPopup: idx == index ? !item.openPopup : false
            };
        });
    }
   
    handleOnclickMenu(event) {
        if (!navigator.onLine) {
            this.showToast('Error', 'No internet connection. Please check your network and try again.', 'error');
            return;
        }
        this.formatDataExisted = false;
        this.showCameraModal = false;
        const action = event.currentTarget.dataset.name;
        const itemId = event.currentTarget.dataset.id;
        const UniqueIdValue = 'FILE-' + Date.now()+ '-' +this.userId + '-' + Math.random().toString(36).substring(2, 10);
        if (action === 'Add') {
            this.modalTitle = 'Add Display Format';
            this.sku = '';
            this.selectedSKUId = null;
            this.displayValue = '';
            this.selectedId=null;
            this.uploadedDocIds = [];
            this.isModalOpen = true;
            this.uniqueId = UniqueIdValue;
        }
        else if (action === 'Edit') {
            const index = event.currentTarget.dataset.index;
            const item = this.formatData[index];
            this.sku = item.skuName;
            this.selectedSKUId = item.skuid;
            this.displayValue = item.displayValue;
            this.modalTitle = 'Edit Display Format';
            this.isModalOpen = true;
            this.selectedId = itemId;
            this.uniqueId = '';
            this.userId = action === 'Edit' ?itemId : Id;          
        }
        this.loadAllFiles();
    }
    closeModal() {
        if (!this.isDesktop) {
            const cameraCmp = this.template.querySelector('c-capture-image-lwc');
            if (cameraCmp) {
                cameraCmp.stopCamerafromParent();
            }
        }
        this.resetform();
        
    }
    resetform()
    {
        this.isModalOpen = false;
        this.formatDataExisted = true;
        this.selectedId = null;
        this.searchedSKUData = [];
        this.isSKUValueSearched = false;
        this.selectedSKUId = null;
    }


    handleInputChange(event) {
        let value = event.target.value;
        this.displayValue = value;
    }
    // Product Search
    handleSKUSearch(event) {
        let searchValueName = event.target.value ? event.target.value.trim() : '';
        console.log('this.productList'+this.productList);
        if (searchValueName) {
            
            if(this.productList)
            {
                const lowerCaseSearch = searchValueName.toLowerCase();
                const storeData = [];

                for (let i = 0; i < this.productList.length; i++) {
                    const product = this.productList[i];
                    if (product.Name && product.Name.toLowerCase().includes(lowerCaseSearch)) {
                        storeData.push(product);
                        if (storeData.length >= 50) break;
                    }
                }
                console.log('storeData'+storeData);
                this.isSKUValueSearched = storeData.length !== 0;
                this.searchedSKUData = storeData;
            }
        } else {
            this.searchedSKUData = [];
            this.isSKUValueSearched = false;
            this.sku = '';
        }
    }
    selectSKU(event) {
        const selectedId = event.currentTarget.dataset.id;
        const selectedName = event.currentTarget.dataset.name;

        this.sku = selectedName;
        this.selectedSKUId = selectedId;
        this.isSKUValueSearched = false;
    }

    //Camera
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
        if (!navigator.onLine) {
            this.showToast('Error', 'No internet connection. Please check your network and try again.', 'error');
            return;
        }
        const files = event.detail.files;
        const fileIds = files.map(file => file.documentId);
        if( this.selectedId )
        {
            this.showToast('Success','Files uploaded successfully!', 'success');
            this.loadAllFiles();
        }
        else
        {
            this.isPopLoading = true;
            updateDocument({ idList: fileIds, uniqueId: this.uniqueId })
            .then(() => {
                this.showToast('Success','Files uploaded successfully!', 'success');
                this.loadAllFiles();
            })
            .catch(err => {
                console.error('Upload error:', err);
                this.showToast('Upload failed', 'error');
                this.isPopLoading = false; // stop loader if upload fails
            });
        }
    
    }  
    loadAllFiles() {
        if (!navigator.onLine) {
            this.showToast('Error', 'No internet connection. Please check your network and try again.', 'error');
            return;
        }
        this.uploadedFiles = [];
        this.isPopLoading = true;
        getFiles({ uniqueId: this.uniqueId,recordId : this.selectedId })
        .then(result => {
            this.uploadedFiles = result || [];
            this.showUploadedFiles = this.uploadedFiles.length > 0;
        })
        .catch(error => {
            console.error('Error loading files:', error);
        })
        .finally(() => {
            this.isPopLoading = false;
        });
    }
    async deleteFile(event) {
        if (!navigator.onLine) {
            this.showToast('Error', 'No internet connection. Please check your network and try again.', 'error');
            return;
        }
        if (confirm('Confirm deleting this file?')) {
            const fileId = event.currentTarget.dataset.id;
            this.isPopLoading = true;
            try {
                await deleteFile({ contentDocumentId: fileId });
                this.showToast('Success','File has been deleted successfully!', 'Success');
                this.loadAllFiles();
            } catch (err) {
                console.error('Delete error', err);
                this.showToast('Error','Deletion failed', 'error');
            }
            this.isPopLoading = false;
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



    saveDisplayFormat() {
        if (!this.isDesktop) {
            const cameraCmp = this.template.querySelector('c-capture-image-lwc');
            if (cameraCmp) {
                cameraCmp.stopCamerafromParent();
            }
        }
        if (!navigator.onLine) {
            this.showToast('Error', 'No internet connection. Please check your network and try again.', 'error');
            return;
        }
        this.displayFormatData = {
            'sObjectType': 'Display_Format__c',
            Id: this.selectedId,
            SKU__c: this.selectedSKUId ? this.selectedSKUId : this.sku,
            Display__c: this.displayValue,
            Visit__c: this.visitId,
            UniqueFileId__c:this.uniqueId,
        };
        if(!this.displayFormatData.SKU__c  || !this.displayFormatData.Display__c) {
            this.showFieldError('displayformatfields');
            this.showToast('Error', 'Please fill all the Mandatory fields', 'error' );
            return;
        }
        else if (isNaN(this.displayFormatData.Display__c) || Number(this.displayFormatData.Display__c) < 1) {
            this.showFieldError('displayformatfields');
            this.showToast('Error', 'Please enter display value greater than zero', 'error');
            return;
        }


         // Duplication check
        const isDuplicate = this.formatData.some(item => {
            return item.skuid === this.displayFormatData.SKU__c && item.id !== this.selectedId;
        });

        if (isDuplicate) {
            this.showToast('Error', 'A display format already exists for this SKU', 'error');
            return;
        }





        //validate file Upload
        this.validateFileUpload();
        
       
    }

    validateFileUpload()
    {
        if (!navigator.onLine) {
            this.showToast('Error', 'No internet connection. Please check your network and try again.', 'error');
            return;
        }
        this.isPopLoading = true;
        getFiles({uniqueId : this.uniqueId,recordId : this.selectedId})
        .then(result => {
            let uploadedFilessize = result.length || 0;
            if(uploadedFilessize > 0)
            {
                saveDisplayFormat({ format:  this.displayFormatData })
                .then((result) => {
                    console.log('Save result:', result); // Log the result to verify the response

                    const skuName = result.SKU__r && result.SKU__r.Name ? result.SKU__r.Name : 'No SKU Name';

                    // Create the new format object
                    const newFormat = {
                        id: result.Id,
                        visit: result.Visit__c,
                        skuid: result.SKU__c,
                        skuName: skuName, // Use the safely fetched skuName
                        displayValue: result.Display__c,
                        openPopup: false
                    };

                    // Update the formatData array with the new or updated record
                    if (this.selectedId) {
                        // If editing, update the record in the list
                        this.formatData = this.formatData.map(item =>
                            item.id === this.selectedId ? newFormat : item
                        );
                    } else {
                        // If creating, add the new record to the top of the list
                        this.formatData = [newFormat, ...this.formatData];
                    }

                    // Refresh formatDataExisted based on the updated formatData
                    this.formatDataExisted = this.formatData.length > 0;
                    this.isPopLoading = false;
                    // Show success toast and close modal
                    this.resetform();
                    
                    
                    this.showToast('Success', 'Display Format saved successfully', 'success');
                })
                .catch(error => {
                    console.error('Error saving format:', error);
                })
                .finally(() => {
                    this.isLoading = false;
                });
            }
            else
            {
                this.isPopLoading = false;
                this.showToast('Error', 'Please upload an image to save display format', 'error');
            }
        })
        .catch(error => {
            console.error(error);
            this.isPopLoading = false;
            this.isLoading = false;
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
    showFieldError(fieldPrefix) {
        const inputFields = this.template.querySelectorAll(`[data-id^="${fieldPrefix}"]`); 
        if (inputFields.length > 0) {
            inputFields.forEach(input => {
                input.reportValidity(); // Show validation error
            });
        }
    }

}