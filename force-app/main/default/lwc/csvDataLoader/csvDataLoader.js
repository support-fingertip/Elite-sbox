import { LightningElement, track, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import importData from '@salesforce/apex/CSVCreator.ImportData'; // Import Apex method to handle data import
import getCSVObject from '@salesforce/apex/CSVCreator.getCSVObject'; // Import method to handle CSV parsing
import getCSVHeader from '@salesforce/apex/CSVCreator.getCSVHeader'; // Import method to handle CSV parsing


export default class CsvDataloader extends LightningElement {
    csvObject;
    csvString;
    @api objectName;
    @api selectedUser;
    spinner = false;
    disabledTrue = true;
    objectFieldDisabled = true;
    csvHeaders = [];  // Array to store field headers for the template

    connectedCallback() {
        this.objectFieldDisabled = this.objectName == null ? false : true;
    }

    // Define the options for the object selection dropdown
    get objectOptions() {
        return [
            { label: 'Beat Items', value: 'Junction_Beat__c' },
            { label: 'PJP Items', value: 'PJP_Item__c' },
            { label: 'Customer Mapping', value: 'Product_Mapping__c' },
            { label: 'DSM Primary Customer Mapping', value: 'Employee_Customer_Assignment__c' }
        ];
    }

    handleObjectChange(event) {
        this.objectName = event.detail.value;
    }

    getCSVHeaders() {
        getCSVHeader({ objectName: this.objectName, selectedUser: this.selectedUser })
            .then((result) => {
                this.csvHeaders = result;

                //   alert(JSON.stringify(this.csvHeaders))

                // Prepare the CSV content
                let csvContent = 'data:text/csv;charset=utf-8,';

                // Add the headers to the CSV content
                csvContent += this.csvHeaders.join(',') + '\n';

                // Encode URI and create a link to download the file
                const encodedUri = encodeURI(csvContent);
                const link = document.createElement('a');
                link.setAttribute('href', encodedUri);
                link.setAttribute('download', `${this.objectName}_Template.csv`);

                // Trigger the download
                link.click();

            })
            .catch((error) => {
                console.log('Error while server call', error);
                this.genericToastDispatchEvent('Error!', error.body.message, 'error');
                this.spinner = false; // Hide spinner on error
            });

    }

    // Handle file upload
    handleUploadFinished(event) {
        this.spinner = true; // Show loading spinner
        const fileInput = this.template.querySelector("input[type='file']");
        const file = fileInput.files[0];
        if (file) {
            console.log("UPLOADED");

            // Validate file type
            const fileExtension = file.name.split('.').pop().toLowerCase();
            if (fileExtension !== 'csv') {
                alert('Please upload a CSV file.');
                this.spinner = false; // Hide spinner after upload
                return;
            }

            const reader = new FileReader();
            reader.readAsText(file, 'UTF-8');
            reader.onload = (evt) => {
                const csv = evt.target.result;
                console.log('csv:' + csv)
                this.csvString = csv;
                this.disabledTrue = false;
                this.spinner = false; // Hide spinner after upload

                this.handleGetCSV();
            };
        }
    }

    // Handle CSV processing
    handleGetCSV() {
        this.spinner = true; // Show spinner while processing CSV
        const csv = this.csvString;
        console.log('csv2:' + csv)
        if (csv != null) {
            this.createCSVObject(csv);
        }
    }

    // Create CSV object
    createCSVObject(csv) {
        getCSVObject({ csv_str: csv, object_name: this.objectName })
            .then((result) => {
                this.csvObject = result; // Assign parsed CSV to csvObject property
                console.log(JSON.stringify(this.csvObject))
                this.spinner = false; // Hide the spinner after parsing
            })
            .catch((error) => {
                console.log('Error while server call', error);
                this.genericToastDispatchEvent('Error!', error.body.message, 'error');
                this.spinner = false; // Hide spinner on error
            });
    }

    // Handle import button click
    handleImportClick() {
        this.spinner = true;
        const csvObject = this.csvObject;
        console.log(JSON.stringify(csvObject));
        console.log('selectedUser:' + this.selectedUser);

        importData({ csvData: csvObject, selectedUser: this.selectedUser })
            .then((result) => {
                console.log('Server call was successful');
                this.genericToastDispatchEvent('Success!', 'Records have been processed in batch! Results are sent to your mail.', 'success');
                this.spinner = false; // Show spinner while processing CSV
                this.cleanData(); // Reset data after import
                this.goBack();
            })
            .catch((error) => {
                console.log('Error while server call', error);
                this.genericToastDispatchEvent('Error!', error.body.message, 'error');
                this.spinner = false; // Hide spinner after error
            });
    }

    // Show Toast message
    genericToastDispatchEvent(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant
            })
        );
    }

    // Reset data and UI state
    resetData() {
        this.csvString = null;
        this.csvObject = null;
        //this.objectName = '';
        this.disabledTrue = true;
        this.spinner = false; // Hide spinner
    }

    // Clean all data
    cleanData() {
        this.csvString = null;
        this.csvObject = null;
        //this.objectName = '';
        this.disabledTrue = true;
        this.spinner = false; // Hide spinner
        const fileInput = this.template.querySelector("input[type='file']");
        if (fileInput) fileInput.value = '';
    }
    goBack() {
        /*  if (this.isButton)
             return; */
        const message = {
            message: 'goBack',
        };
        this.genericDispatchEvent(message);
    }
    genericDispatchEvent(message) {
        // Creating a custom event with a payload (optional)
        const event = new CustomEvent('mycustomevent', {
            detail: message
        });

        // Dispatching the event
        this.dispatchEvent(event);
    }
}