import { LightningElement,track,api } from 'lwc';
import getCompetionsData from '@salesforce/apex/beatPlannerlwc.getCompetions';
import saveCompetionsData from '@salesforce/apex/beatPlannerlwc.saveCompetition';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import Id from '@salesforce/user/Id';
import updateDocument from '@salesforce/apex/beatPlannerlwc.updateDocument';
import getFiles from '@salesforce/apex/beatPlannerlwc.getFilescompetetion';
import { NavigationMixin } from 'lightning/navigation';
import deleteFile from '@salesforce/apex/beatPlannerlwc.deleteFile';
import FORM_FACTOR from '@salesforce/client/formFactor';
import VALIDATE_FILE from '@salesforce/apex/beatPlannerlwc.validateVisitFileUpload';
export default class CompetitionScreen7 extends NavigationMixin(LightningElement){
    isLoading = false;
    @api recordId;
    isDesktop = false;
    isPhone = false;
    @api visitId;
    @api visitData;
    visitfor ='';
    @track isCameraOpen = true;

    @track statusOptions = [
        { label: 'Yes', value: 'Yes' },
        { label: 'No', value: 'No' },
    ];
    @track competitions = [];
    competitorList=[];
    products=[];
    productCategories=[];

    SearchedProductData = [];
    realatedProducts = [];
    SearchedProductCategoryData = [];
    SearchedCompetitorData = [];

    isModalOpen = false;
    competitionExisted=false;
    isValueSearched = false;
    productCategoryId = '';
    productCategory='';
    product='';
    productId='';
    competitorId='';
    competitorName='';
    displayBoard='Yes';
    specialOffersGoingOn='Yes';
    specialOfferDetails='';

    disableProcuctCategory = false;
    disableProduct = true;
    isproductsExisted = false;
    isCompetitorExisted = false;
    isSpecialOffersGoingOn = true;
    competitionId = '';
    isDeleteModalOpen = false;
    customClass='slds-col slds-size_1-of-2 slds-p-horizontal_small';
    isDropdownTargetOpen =true;
    @track showPopup = false;
    @track selectedItem = {};
    containerClass;
    remarks = '';
    customclassremarks='slds-col slds-size_1-of-2 slds-p-horizontal_small';
    showCameraModal = false;
    isPopLoading = false;
    showUploadedFiles = false; 
    @track uploadedFiles = [];
    uniqueId = '';
    loadingScreenSize = 2;
    currentCompetitonRecordId = '';
    competitionData = {};
    isProductReadOnly = false;
    isCompetitorReadOnly = false;

    //on loading we are quering the tasks
    connectedCallback() {
        this.isDesktop = FORM_FACTOR === 'Large'? true : false;
        this.isPhone = FORM_FACTOR === 'Small'? true : false;
        this.loadingScreenSize =   this.isDesktop ? 2 : 3;
        this.visitfor = this.visitData.visitTypes;
        this.fetchCompetitionData(); 
        this.containerClass = this.isDesktop ? 'slds-modal__container ' : '';
        this.customClass = this.isDesktop ? 'slds-size_1-of-2 slds-p-horizontal_small':'slds-size_1-of-1 slds-p-horizontal_small';
    }
    //fetch all the data 
    fetchCompetitionData() {
        if (!navigator.onLine) {
            this.showToast('Error', 'No internet connection. Please check your network and try again.', 'error');
            return;
        }
        this.isLoading = true;
        getCompetionsData({ recordId: this.recordId, visitId: this.visitId })
        .then((result) => {
            console.log(result);
            this.competitions = result.competitionList.map(item => ({
                id: item.Id,
                name:item.Name,
                productCategory: item.Product_Category_Text__c,
                productCatgoryId: item.Product_Category__c,
                product: item.Product_Text__c,
                productId: item.Product__c,
                competitor: item.Competitor__c,
                competitorName: item.Competitor_Name__c,
                SpecialOffersGoingOn: item.Special_offer_going_on__c,
                specialOfferDetails: item.Special_offer_details__c,
                displayBoard: item.Display_boards__c,
                remarks:item.Remarks__c,
                uniqueId:item.UniqueFileId__c,
                openPopup: false
            }));

            // Set competitionExisted based on competitionList length
            this.competitionExisted = result.competitionList.length > 0;

            this.products = result.productList;
            this.productCategories = result.productCategoryList;
            this.competitorList = result.competitorList;
            setTimeout(() => {
                window.scrollTo({
                    top: 0,
                    behavior: 'smooth'
                });
            }, 0);
            this.isLoading = false;
        })
        .catch((error) => {
            this.isLoading = false;
            this.showToast('Error', 'Error fetching Competitions: ' + error.body.message, 'error');
        });
    }
    //To openn the task menu
    openMenu(event) {
        //const itemId = event.currentTarget.dataset.id;
        const index1 = parseInt(event.currentTarget.dataset.index, 10); 
        console.log('entered'+index1);
        this.competitions = this.competitions.map((item, i) => {
            return {
                ...item,
                openPopup: i === index1 ? !item.openPopup : false
            };
        });
       
        
    }
    //Once we clicked on the popup
    handleOnclickMenu(event) {
        if (!navigator.onLine) {
            this.showToast('Error', 'No internet connection. Please check your network and try again.', 'error');
            return;
        }
        this.uniqueId = '';
        this.competitionId = '';
        this.isProductReadOnly = false;
        this.isCompetitorReadOnly = false;
        this.showCameraModal = false;
        let UniqueIdValue = 'FILE-' + Date.now()+'Competition'+ '-' +this.userId + '-' + Math.random().toString(36).substring(2, 10);
        this.competitionExisted = false;
        const action = event.currentTarget.dataset.name;
        const itemId = event.currentTarget.dataset.id;
        const competition = this.competitions.find(competition => competition.id == itemId);
        if (action === 'Edit' || action === 'Add') {
            this.modalTitle = action === 'Edit' ? 'Edit Competition' : 'New Competition';
            this.productCategory = action === 'Edit' ? competition.productCategory : '';
            this.productCategoryId =  action === 'Edit' ? competition.productCatgoryId : null;
            this.product = action === 'Edit' ? competition.product : '';
            this.productId = action === 'Edit' ? competition.productId : '';
            this.competitorName = action === 'Edit'? competition.competitorName : '';
            this.competitorId = action === 'Edit'? competition.competitor : null;
            this.displayBoard = action === 'Edit' ? competition.displayBoard : 'Yes';
            this.specialOffersGoingOn =  action === 'Edit' ? competition.SpecialOffersGoingOn : 'Yes';
            this.specialOfferDetails = action === 'Edit' ? competition.specialOfferDetails : '';
            this.remarks = action === 'Edit' ? competition.remarks : '';
            this.competitionId = action === 'Edit' ? competition.id : null;
            this.isModalOpen = true;
            this.disableProcuctCategory = action === 'Edit' ? true : false;
            this.uniqueId = action === 'Edit' ?'' : UniqueIdValue;
            this.userId = action === 'Edit' ?itemId : Id;
            this.isProductReadOnly = action === 'Edit' ? competition.product ? true : false:false;
            this.isCompetitorReadOnly = action === 'Edit' ? competition.competitor ? true: false :false;
            this.isSpecialOffersGoingOn = this.specialOffersGoingOn =='Yes' ? true : false;
            this.customclassremarks=  this.isDesktop ? this.specialOffersGoingOn =='Yes' ? 
                                    'slds-col slds-size_1-of-2 slds-p-horizontal_small' : 
                                    'slds-col slds-size_1-of-1 slds-p-horizontal_small':'slds-col slds-size_1-of-1 slds-p-horizontal_small';
        } 
        this.loadAllFiles();
    }
    //close the popup
    closeModal() {
        if (this.isPhone) {
            const cameraCmp = this.template.querySelector('c-capture-image-lwc');
            if (cameraCmp) {
                cameraCmp.stopCamerafromParent();
            }
        }
        this.isModalOpen = false;
        this.resetForm();
    }
    resetForm() {
        this.productCategory = '';
        this.product = '';
        this.competitorName = '';
        this.displayBoard='Yes';
        this.specialOffersGoingOn='Yes';
        this.specialOfferDetails='';
        this.disableProcuctCategory = false;
        this.disableProduct = true;
        this.isproductsExisted = false;
        this.isCompetitorExisted = false;
        this.isSpecialOffersGoingOn = true;
        this.competitionExisted = true;
    }
    //Product Search
    handleProductSearch(event){
        this.searchValueName = event.target.value;
        if(this.searchValueName){
            let objData = this.products || [];
            if(objData)
            {
                let storeData = [];
                for (let i = 0; i < objData.length; i++) {
                    const objName = objData[i];
                    if ((objName.Name && objName.Name.toLowerCase().indexOf(this.searchValueName.toLowerCase()) !== -1)) {
                        storeData.push(objName);
                    }
                }
                this.isproductsExisted = storeData != 0 ? true : false;
                this.SearchedProductData = storeData;
             }
        }
        else
        {
            
            this.product = '';
            this.productId=''
            this.isproductsExisted = false;
            this.disableProduct = false;
            this.isProductReadOnly = false;
        }

    }
    //Product click
    selectProduct(event){
        console.log('Name'+event.currentTarget.dataset.name);
        this.productId = event.currentTarget.dataset.id;
        this.product = event.currentTarget.dataset.name;
        this.isproductsExisted = false;
        this.disableProduct = true;
        this.isProductReadOnly = true;
    }
    //Competitor Search 
    handleCompetitorSearch(event){
        this.searchValueName = event.target.value;
        if(this.searchValueName){
            this.competitorName =event.target.value;
            let objData = this.competitorList;
            let storeData = [];
            for (let i = 0; i < objData.length; i++) {
                const objName = objData[i];
                if ((objName.Name && objName.Name.toLowerCase().indexOf(this.searchValueName.toLowerCase()) !== -1)) {
                    storeData.push(objName);
                }
            }
            this.isCompetitorExisted = storeData != 0 ? true : false;
            this.SearchedCompetitorData = storeData;
        }
        else
        {
            
            this.competitorId = '';
            this.competitorName=''
            this.isCompetitorExisted = false;
            this.isCompetitorReadOnly = false;
        }

    }
    //competitor click
    selectCompetitor(event){
        this.competitorId = event.currentTarget.dataset.id;
        this.competitorName = event.currentTarget.dataset.name;
        this.isCompetitorExisted = false;
        this.isCompetitorReadOnly = true;
    }
    //handle input changes
    handleInputChange(event)
    {
        const field = event.currentTarget.dataset.name;
        if (field === 'specialOffersGoingOn') {
            this.specialOffersGoingOn = event.currentTarget.value;
            this.isSpecialOffersGoingOn = this.specialOffersGoingOn =='Yes' ? true : false;
            this.customclassremarks=  this.isDesktop ? this.specialOffersGoingOn =='Yes' ? 'slds-col slds-size_1-of-2 slds-p-horizontal_small' : 'slds-col slds-size_1-of-1 slds-p-horizontal_small':'slds-col slds-size_1-of-1 slds-p-horizontal_small';
        } else if (field === 'displayBoard') {
            this.displayBoard = event.currentTarget.value;
        } else if (field === 'specialOfferDetails') {
            this.specialOfferDetails = event.currentTarget.value;
        }
        else if(field === 'remarks')
        {
            this.remarks = event.currentTarget.value;
        }
      
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
        if( this.competitionId )
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
        console.log('uniqueId'+this.uniqueId);
        console.log('competitionId'+this.competitionId );
        getFiles({ uniqueId: this.uniqueId,recordId : this.competitionId })
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



    //Saving competition change
    saveCompetition()
    {
        if (this.isPhone) {
            const cameraCmp = this.template.querySelector('c-capture-image-lwc');
            if (cameraCmp) {
                cameraCmp.stopCamerafromParent();
            }
        }
        if (!navigator.onLine) {
            this.showToast('Error', 'No internet connection. Please check your network and try again.', 'error');
            return;
        }
        // Create Competition__c object
        this.competitionData = {
            'sObjectType': 'Competition__c',
            Id:this.competitionId,
            Product_Text__c: this.product,
            Product__c: this.productId,
            Account__c:this.recordId,
            Competitor__c: this.competitorId,
            Competitor_Name__c: this.competitorName,
            Special_offer_going_on__c: this.specialOffersGoingOn,
            Special_offer_details__c: this.specialOfferDetails,
            Display_boards__c: this.displayBoard,
            Visit__c: this.visitId,
            Visit_for__c:this.visitfor,
            Remarks__c:this.remarks,
            UniqueFileId__c:this.uniqueId,
        };
        if (
            !this.competitionData.Product__c ||
            !this.competitionData.Competitor_Name__c || this.competitionData.Competitor_Name__c.trim() === '' ||
            !this.competitionData.Remarks__c || this.competitionData.Remarks__c.trim() === ''
        ) {
            this.showFieldError('competitonDetails');
            this.showToast('Error', 'Please fill in all mandatory fields', 'error');
        } else if (
            this.competitionData.Special_offer_going_on__c === 'Yes' &&
            (!this.competitionData.Special_offer_details__c || this.competitionData.Special_offer_details__c.trim() === '')
        ) {
            this.showFieldError('competitonDetails');
            this.showToast('Error', 'Please fill in Special Offer Details', 'error');
        } else {
            this.validateFileUpload();
        }
    }
    validateFileUpload()
    {
        if (!navigator.onLine) {
            this.showToast('Error', 'No internet connection. Please check your network and try again.', 'error');
            return;
        }
        this.isPopLoading = true;
        VALIDATE_FILE({uniqueId : this.uniqueId})
        .then(result => {
            if(result =='Success')
            {
                saveCompetionsData({ cmp: this.competitionData, visitId: this.visitId })
                .then((result) => {
                    this.competitions = result.competitionList.map(item => ({
                        id: item.Id,
                        name:item.Name,
                        productCategory: item.Product_Category_Text__c,
                        productCatgoryId: item.Product_Category__c,
                        product: item.Product_Text__c,
                        productId: item.Product__c,
                        competitor: item.Competitor__c,
                        competitorName: item.Competitor_Name__c,
                        SpecialOffersGoingOn: item.Special_offer_going_on__c,
                        specialOfferDetails: item.Special_offer_details__c,
                        displayBoard: item.Display_boards__c,
                        remarks:item.Remarks__c,
                        uniqueId:item.UniqueFileId__c,
                        openPopup: false
                    }));
                    // Set competitionExisted based on competitionList length
                    this.competitionExisted = result.competitionList.length > 0;
                    this.competitorList = result.competitorList;
                    this.isPopLoading = false;
                    this.isModalOpen = false;
                    this.resetForm();
                    this.showToast('success', 'Competition saved successfully', 'success');
                })
                .catch((error) => {
                    this.isPopLoading = false;
                    this.showToast('Error', 'Error fetching Competitions: ' + error.body.message, 'error');
                });
            }
            else
            {
                this.isPopLoading = false;
                this.showToast('Error', 'Please upload an image to complete the Competitor Activity', 'error');
            }
            
        })
        .catch(error => {
            console.error(error);
            this.isPopLoading = false;
            this.isLoading = false;
        });
    }


    togglecompetionDropdown(){
        this.isDropdownTargetOpen = !this.isDropdownTargetOpen;
        // Close all popups in the competitions array
        this.competitions = this.competitions.map((item) => {
            return {
                ...item,
                openPopup: false // Set openPopup to false for all items
            };
        });
        const dropdownBody = this.template.querySelector('.dropdown-body-ord');
        const chevronIcon = this.template.querySelector('.chevron-icon-ord');

        if (dropdownBody && chevronIcon) {
            if (this.isDropdownTargetOpen) {
                dropdownBody.classList.add('active');
                dropdownBody.classList.remove('deactive');
                chevronIcon.iconName = 'utility:chevronup'; // Switch to chevron up
            } else {
                dropdownBody.classList.add('deactive');
                dropdownBody.classList.remove('active');
                chevronIcon.iconName = 'utility:chevrondown'; // Switch to chevron down
            }
        }
    }
      // Open the popup and store selected item details
    openPopupDetails(event) {
         // Close all popups in the competitions array
        this.competitions = this.competitions.map((item) => {
            return {
                ...item,
                openPopup: false // Set openPopup to false for all items
            };
        });
        const itemId = event.currentTarget.dataset.id;
        this.selectedItem = this.competitions.find(item => item.id == itemId);
        this.showPopup = true;
    }

    // Close the popup
    closePopup() {
        this.showPopup = false;
        this.selectedItem = {};
    }
    
    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
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