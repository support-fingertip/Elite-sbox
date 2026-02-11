import { LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getObjects from '@salesforce/apex/DataUploaderController.getObjects';
import getObjectFields from '@salesforce/apex/DataUploaderController.getObjectFields';
import uploadCSVData from '@salesforce/apex/DataUploaderController.uploadCSVData';
import fetchCSVContent from '@salesforce/apex/DataUploaderController.fetchCSVContent'; // ✅ Import missing

export default class DataUploader extends LightningElement {
    @track objectOptions = [];
    @track selectedObject;
    @track isLoading = false;
    @track showResults = false;
    @track isSuccess = false;
    @track hasErrors = false;
    @track successCount = 0;
    @track errorCount = 0;
    @track errors = [];
    @track allRecords = [];
    @track objectFields = [];
    @track csvHeaders = [];
    @track csvPreviewData = [];
    @track fieldMapping = {};
    @track showMapping = false;
    @track csvContent;
    @track selectedStatusFilter = 'all'; // Initialize the filter
    @track fieldMappingOptions = [];
    unmappedSet = new Set();

    
get isUploadDisabled() {
    return this.unmappedSet.size > 0 || this.isLoading;
}



validateMapping() {
    // start clean
    this.unmappedSet = new Set();

    // no CSV chosen yet → nothing to validate
    if (!this.csvHeaders) return;

    // loop over every header column in the CSV
    this.csvHeaders.forEach(header => {
        // if the mapping for this column is empty/null/undefined
        // put it on the "needs-attention" list
        if (!this.fieldMapping[header]) {
            this.unmappedSet.add(header);
        }
    });
}

getComboboxClass(header) {
    // If this header is still unmapped -> return 'unmapped'
    // (That class gives a red border/background via CSS.)
    return this.unmappedSet.has(header) ? 'unmapped' : '';
}
    acceptedFormats = ['.csv'];
    isUploadDisabled = true;
    statusFilterOptions = [
        { label: 'All', value: 'all' },
        { label: 'Success', value: 'success' },
        { label: 'Failed', value: 'failed' }
    ];



    get previewRows() {
        return this.csvPreviewData.map(row => ({
            id: row.id,
            values: this.csvHeaders.map(header => ({
                key: header,
                value: row[header]
            }))
        }));
    }

  refreshFieldMappingOptions() {
    this.fieldMappingOptions = this.csvHeaders.map(header => {
        const unmapped = !this.fieldMapping[header];
        const cssClass =
            'slds-col slds-size_1-of-2 slds-p-bottom_medium' +
            (unmapped ? ' unmapped' : '');
        return {
            header,
            value   : this.fieldMapping[header] || '',
            cssClass
        };
    });
}


    @wire(getObjects)
    wiredObjects({ error, data }) {
        if (data) {
            this.objectOptions = data.map(obj => ({
                label: obj.label,
                value: obj.apiName
            }));
        } else if (error) {
            this.showToast('Error', 'Error loading Salesforce objects', 'error');
            console.error('Error loading objects:', error);
        }
    }

    handleObjectChange(event) {
        this.selectedObject = event.detail.value;
        this.isUploadDisabled = !this.selectedObject;
        this.showResults = false;
        this.showMapping = false;
        this.csvHeaders = [];
        this.csvPreviewData = [];
        this.fieldMapping = {};
     

        if (this.selectedObject) {
            this.loadObjectFields();
        }
    }

    async loadObjectFields() {
        try {
            this.isLoading = true;
            const result = await getObjectFields({ objectApiName: this.selectedObject });
            this.objectFields = result.map(field => ({
                label: field.label,
                value: field.apiName,
                dataType: field.dataType
            }));
            this.autoMapFields();  
        } catch (error) {
            this.showToast('Error', 'Error loading object fields', 'error');
            console.error('Error loading fields:', error);
        } finally {
            this.isLoading = false;
        }
    }

    handleUploadFinished(event) {
        const uploadedFiles = event.detail.files;
        if (uploadedFiles.length > 0) {
            const contentVersionId = uploadedFiles[0].contentVersionId;

            if (!contentVersionId) {
                this.showToast('Error', 'contentVersionId not found in uploaded file', 'error');
                return;
            }

            fetchCSVContent({ contentVersionId })
                .then(result => {
                    this.processCSVData(result); // result is the raw CSV string
                })
                .catch(error => {
                    const message = error?.body?.message || error.message || 'Unknown error';
                    this.showToast('Error', 'Error fetching file content: ' + message, 'error');
                    console.error('File fetch error:', error);
                });
        }
    }

    processCSVData(csvData) {
        try {
            this.csvContent = csvData;
            const rows = csvData.split(/\r?\n/).filter(row => row.trim());

            if (rows.length === 0) {
                throw new Error('CSV file is empty');
            }

            const headers = rows[0].split(',').map(header =>
                header.trim().replace(/^"(.*)"$/, '$1')
            );
            this.csvHeaders = headers;

            const previewData = [];
            for (let i = 1; i < Math.min(rows.length, 6); i++) {
                if (!rows[i].trim()) continue;

                const values = this.parseCSVRow(rows[i]);
                const rowData = {};

                headers.forEach((header, index) => {
                    rowData[header] = values[index] || '';
                });

                rowData.id = 'row-' + i;
                previewData.push(rowData);
            }

            this.csvPreviewData = previewData;
            this.showMapping = true;
            this.fieldMapping = {};
            this.autoMapFields();   // try to map now that headers exist

        } catch (error) {
            this.showToast('Error', 'Error processing CSV: ' + error.message, 'error');
            console.error('CSV Processing Error:', error);
        }
    }

    parseCSVRow(row) {
        const values = [];
        let currentValue = '';
        let insideQuotes = false;

        for (let i = 0; i < row.length; i++) {
            const char = row[i];

            if (char === '"') {
                insideQuotes = !insideQuotes;
            } else if (char === ',' && !insideQuotes) {
                values.push(currentValue.trim().replace(/^"(.*)"$/, '$1'));
                currentValue = '';
            } else {
                currentValue += char;
            }
        }

        values.push(currentValue.trim().replace(/^"(.*)"$/, '$1'));
        return values;
    }

    handleFieldMapping(event) {
        const header = event.target.dataset.header;
        const selectedField = event.detail.value;

        if (selectedField) {
            this.fieldMapping = {
                ...this.fieldMapping,
                [header]: selectedField
            };
        } else {
            const { [header]: removed, ...rest } = this.fieldMapping;
            this.fieldMapping = rest;
        }
         this.validateMapping();
         this.refreshFieldMappingOptions(); 
    }



    

    async handleUpload() {


           this.validateMapping();

    // 2) If anything is still unmapped, stop right here
    if (this.unmappedSet.size) {
        this.showToast(
            'Error',
            'Please map every column before uploading. Unmapped columns are highlighted in red.',
            'error'
        );
        return;           // abort upload
    }

    // 3) All good → proceed with your existing upload logic
    this.isLoading = true;
        if (Object.keys(this.fieldMapping).length === 0) {
            this.showToast('Error', 'Please map at least one field before uploading', 'error');
            return;
        }

        try {
            this.isLoading = true;
            this.showResults = false;

            const result = await uploadCSVData({
                objectApiName: this.selectedObject,
                csvContent: this.csvContent,
                fieldMapping: this.fieldMapping
            });

            this.showResults = true;
            this.isSuccess = result.success;
            this.successCount = result.successCount;
            this.errorCount = result.errorCount;
            this.errors = result.errors || [];
            
            console.log('Raw failed records:', JSON.stringify(result.failedRecords));
            console.log('Raw successful records:', JSON.stringify(result.successfulRecords));
            
            // Transform successful records
            const successfulRecords = (result.successfulRecords || []).map(record => {
                const rowData = record.rowData || {};
                const normalizedRowData = {};
                Object.keys(rowData).forEach(key => {
                    normalizedRowData[key.toLowerCase()] = rowData[key];
                });
                // Build values object for dynamic columns
                const values = {};
                const cellValues = (this.csvHeaders || []).map(header => ({
                    header,
                    value: normalizedRowData[header.toLowerCase()] || ''
                }));
                (this.csvHeaders || []).forEach(header => {
                    values[header] = normalizedRowData[header.toLowerCase()] || '';
                });
                return {
                    rowIndex: record.rowIndex,
                    name: normalizedRowData['name'] || '',
                    sku: normalizedRowData['sku__c'] || '',
                    display: normalizedRowData['display__c'] || '',
                    statusField: normalizedRowData['status__c'] || '',
                    fulfilledStatus: normalizedRowData['fulfilled_status__c'] || '',
                    status: 'success',
                    recordId: record.recordId || '',
                    errorMessages: [],
                    values,
                    hasErrorMessages: false,
                    cellValues
                };
            });

            // Transform failed records
            const failedRecords = (result.failedRecords || []).map(record => {
                const rowData = record.rowData || {};
                const normalizedRowData = {};
                Object.keys(rowData).forEach(key => {
                    normalizedRowData[key.toLowerCase()] = rowData[key];
                });
                // Build values object for dynamic columns
                const values = {};
                const cellValues = (this.csvHeaders || []).map(header => ({
                    header,
                    value: normalizedRowData[header.toLowerCase()] || ''
                }));
                (this.csvHeaders || []).forEach(header => {
                    values[header] = normalizedRowData[header.toLowerCase()] || '';
                });
                return {
                    rowIndex: record.rowIndex,
                    name: normalizedRowData['name'] || '',
                    sku: normalizedRowData['sku__c'] || '',
                    display: normalizedRowData['display__c'] || '',
                    statusField: normalizedRowData['status__c'] || '',
                    fulfilledStatus: normalizedRowData['fulfilled_status__c'] || '',
                    status: 'failed',
                    recordId: '',
                    errorMessages: record.errorMessages || [],
                    values,
                    hasErrorMessages: (record.errorMessages || []).length > 0,
                    cellValues
                };
            });

            // Combine and sort records by rowIndex
            this.allRecords = [...successfulRecords, ...failedRecords].sort((a, b) => a.rowIndex - b.rowIndex);
            console.log('All records:', JSON.stringify(this.allRecords));

            const toastTitle = this.isSuccess ? 'Success' : 'Warning';
            const toastMessage = this.isSuccess
                ? `Successfully uploaded ${this.successCount} records`
                : `Uploaded ${this.successCount} records with ${this.errorCount} errors`;
            const toastVariant = this.isSuccess ? 'success' : 'warning';

               


            this.showToast(toastTitle, toastMessage, toastVariant);
        } catch (error) {
            this.handleError(error);
        } finally {
            this.isLoading = false;
        }
    }

     handleUploadBack() {
        this.dispatchEvent(new CustomEvent('cancel'));
    }

    handleError(error) {
        this.showResults = true;
        this.isSuccess = false;
        this.hasErrors = true;
        this.errors = [error.message || 'An unexpected error occurred'];
        this.showToast('Error', 'Error processing file', 'error');
        console.error('Error:', error);
    }

     showToast(title, message, variant) {
        const toast = this.template.querySelector('c-custom-toast'); // Query the toast component
        console.log('Custom Toast component:', toast);  // Log the reference

        if (toast) {
            toast.showToast(variant, message); // Show the toast with the correct variant
        } else {
            console.error('Custom Toast component not found!');
        }
    }

    get hasRecords() {
        return this.allRecords && this.allRecords.length > 0;
    }

    downloadFailedRecords() {
        this.downloadFilteredRecords();
    }

    downloadFilteredRecords() {
        console.log('Download method called for filter:', this.selectedStatusFilter);
        
        // Use the currently filtered records
        const recordsToDownload = this.filteredRecords;
        console.log('Records to download:', JSON.stringify(recordsToDownload));

        if (!recordsToDownload || recordsToDownload.length === 0) {
            this.showToast('Error', `No ${this.selectedStatusFilter} records to download`, 'error');
            return;
        }
    
        try {
            // Dynamic headers from CSV
            const headers = [...this.csvHeaders];
            headers.push('Status');
            // Add appropriate last column header based on record type
            if (this.selectedStatusFilter === 'failed') {
                headers.push('Errors');
            } else if (this.selectedStatusFilter === 'success') {
                headers.push('Record ID');
            } else {
                headers.push('Details');
            }

            let csvContent = headers.join(',') + '\n';
        
            recordsToDownload.forEach(record => {
                // Dynamic row values
                const row = this.csvHeaders.map(header => `"${record.values[header] || ''}"`);
                row.push(`"${record.status || ''}"`);
                // Last column
                let lastColumn = '';
                if (this.selectedStatusFilter === 'failed') {
                    lastColumn = (record.errorMessages || []).join(' | ');
                } else if (this.selectedStatusFilter === 'success') {
                    lastColumn = record.recordId || '';
                } else {
                    lastColumn = record.status === 'failed' ? (record.errorMessages || []).join(' | ') : (record.recordId || '');
                }
                row.push(`"${lastColumn}"`);
                csvContent += row.join(',') + '\n';
            });

            const encodedUri = 'data:text/csv;charset=utf-8,' + encodeURIComponent(csvContent);
            const link = document.createElement('a');
            link.setAttribute('href', encodedUri);
            
            // Set filename based on filter
            const filename = this.selectedStatusFilter === 'all' ? 
                'All_Records.csv' : 
                this.selectedStatusFilter === 'success' ? 
                    'Successful_Records.csv' : 
                    'Failed_Records.csv';
            
            link.setAttribute('download', filename);
            document.body.appendChild(link);
            link.click();
            document.body.removeChild(link);
            
            this.showToast('Success', `${this.selectedStatusFilter} records downloaded successfully`, 'success');
        } catch (error) {
            console.error('Error downloading records:', error);
            this.showToast('Error', `Error downloading ${this.selectedStatusFilter} records: ${error.message}`, 'error');
        }
    }

    handleStatusFilterChange(event) {
        this.selectedStatusFilter = event.detail.value;
        console.log('Selected filter:', this.selectedStatusFilter);
        console.log('Filtered records:', JSON.stringify(this.filteredRecords));
    }

    get filteredRecords() {
        if (!this.allRecords) return [];
        if (this.selectedStatusFilter === 'all') {
            return this.allRecords;
        }
        return this.allRecords.filter(record => record.status === this.selectedStatusFilter);
    }

    get downloadButtonLabel() {
        switch(this.selectedStatusFilter) {
            case 'success':
                return 'Download Successful Records';
            case 'failed':
                return 'Download Failed Records';
            default:
                return 'Download All Records';
        }
    }

    get downloadButtonVariant() {
        switch(this.selectedStatusFilter) {
            case 'success':
                return 'success';
            case 'failed':
                return 'destructive';
            default:
                return 'brand';
        }
    }

    getRecordValue(record, header) {
        return record.values[header] || '';
    }

    hasErrorMessages(record) {
        return record.hasErrorMessages;
    }




    /**
 * Compare each CSV header to every field returned from Apex and
 * auto–populate fieldMapping when the label **or** API-name matches
 * (case-insensitive).  Already-mapped headers are left unchanged
 * so the user’s manual choices aren’t overwritten.
 */
autoMapFields() {
    if (!this.csvHeaders?.length || !this.objectFields?.length) {
        return;       // nothing to map yet
    }

    const updatedMapping = { ...this.fieldMapping };

    this.csvHeaders.forEach(header => {
        // Skip if user has already mapped this column
        if (updatedMapping[header]) return;

        const match = this.objectFields.find(f =>
            f.label.toLowerCase() === header.toLowerCase() ||
            f.value?.toLowerCase() === header.toLowerCase()   // API-name match
        );

        if (match) {
            updatedMapping[header] = match.value;  // value == API name
        }
    });

    this.fieldMapping = updatedMapping;    
      this.validateMapping();  
      this.refreshFieldMappingOptions();      // re-render comboboxes
}




}