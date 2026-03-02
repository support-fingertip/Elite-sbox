import { LightningElement, api, wire, track } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';

const FIELDS = [
    'Visit_Form__c.Id',
    'Visit_Form__c.Customer_Name__c',
    'Visit_Form__c.Customer_Type__c',
    'Visit_Form__c.Visit_Type__c',
    'Visit_Form__c.CreatedDate',
    'Visit_Form__c.Owner.Name',
    'Visit_Form__c.Primary_Customer__c',
    'Visit_Form__c.Primary_Customer__r.Name',
    'Visit_Form__c.Secondary_Customer__c',
    'Visit_Form__c.Secondary_Customer__r.Name',
    'Visit_Form__c.Primary_Customer_Name__c',
    'Visit_Form__c.Sub_Stockiest_Name__c',
    'Visit_Form__c.Outlet_Name__c',
    'Visit_Form__c.Primary_Customer_Business_Type__c',
    'Visit_Form__c.Secondary_Customer_Business_Type__c',
    'Visit_Form__c.Address__c',
    'Visit_Form__c.State__c',
    'Visit_Form__c.District__c',
    'Visit_Form__c.Pincode__c',
    'Visit_Form__c.Contact_Number__c',
    'Visit_Form__c.Product_Categories__c',
    'Visit_Form__c.Product_Group__c',
    'Visit_Form__c.Competitor_Name__c',
    'Visit_Form__c.Competitor_Product__c',
    'Visit_Form__c.Competitor_Remarks__c',
    'Visit_Form__c.General_Remarks__c',
    'Visit_Form__c.Geo_Location__Latitude__s',
    'Visit_Form__c.Geo_Location__Longitude__s'
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
            const fieldValue = (fieldName) => fields[fieldName]?.value;
            const relatedName = (relationshipName) =>
                fields[relationshipName]?.value?.fields?.Name?.value;

            const customerType = fieldValue('Customer_Type__c') || '—';
            const visitType = fieldValue('Visit_Type__c') || '—';

            const computedCustomerName =
                fieldValue('Customer_Name__c') ||
                fieldValue('Primary_Customer_Name__c') ||
                fieldValue('Sub_Stockiest_Name__c') ||
                fieldValue('Outlet_Name__c') ||
                relatedName('Secondary_Customer__r') ||
                relatedName('Primary_Customer__r') ||
                '—';

            this.visitRecord = {
                customerName: computedCustomerName,
                customerType,
                visitType,
                createdDate: fieldValue('CreatedDate'),
                Owner: {
                    Name: fields.Owner?.value?.fields?.Name?.value || '—'
                },
                primaryCustomerName: relatedName('Primary_Customer__r') || '—',
                secondaryCustomerName: relatedName('Secondary_Customer__r') || '—',
                primaryCustomerNameText: fieldValue('Primary_Customer_Name__c') || '—',
                subStockiestName: fieldValue('Sub_Stockiest_Name__c') || '—',
                outletName: fieldValue('Outlet_Name__c') || '—',
                primaryCustomerBusinessType:
                    fieldValue('Primary_Customer_Business_Type__c') || '—',
                secondaryCustomerBusinessType:
                    fieldValue('Secondary_Customer_Business_Type__c') || '—',
                address: fieldValue('Address__c') || '—',
                state: fieldValue('State__c') || '—',
                district: fieldValue('District__c') || '—',
                pincode: fieldValue('Pincode__c') || '—',
                contactNumber: fieldValue('Contact_Number__c') || '—',
                productCategory: fieldValue('Product_Categories__c') || '—',
                productGroup: fieldValue('Product_Group__c') || '—',
                competitorName: fieldValue('Competitor_Name__c') || '—',
                competitorProduct: fieldValue('Competitor_Product__c') || '—',
                competitorRemarks: fieldValue('Competitor_Remarks__c') || '—',
                generalRemarks: fieldValue('General_Remarks__c') || '—',
                latitude:
                    fieldValue('Geo_Location__Latitude__s') !== undefined &&
                    fieldValue('Geo_Location__Latitude__s') !== null
                        ? String(fieldValue('Geo_Location__Latitude__s'))
                        : '—',
                longitude:
                    fieldValue('Geo_Location__Longitude__s') !== undefined &&
                    fieldValue('Geo_Location__Longitude__s') !== null
                        ? String(fieldValue('Geo_Location__Longitude__s'))
                        : '—'
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
        return new Date(this.visitRecord.createdDate).toLocaleTimeString('en-IN', {
            hour: '2-digit', minute: '2-digit', hour12: true
        });
    }

    get formSpecificFields() {
        if (!this.visitRecord) {
            return [];
        }

        const customerTypeField = {
            label: 'Customer Type',
            value: this.visitRecord.customerType
        };

        const commonFormFields = [
            { label: 'Product Category', value: this.visitRecord.productCategory },
            { label: 'Product Group', value: this.visitRecord.productGroup },
            { label: 'Competitor Name', value: this.visitRecord.competitorName },
            { label: 'Competitor Product', value: this.visitRecord.competitorProduct },
            { label: 'Competitor Remarks', value: this.visitRecord.competitorRemarks },
            { label: 'General Remarks', value: this.visitRecord.generalRemarks },
            { label: 'Latitude', value: this.visitRecord.latitude },
            { label: 'Longitude', value: this.visitRecord.longitude }
        ];

        const addressFields = [
            { label: 'Address', value: this.visitRecord.address },
            { label: 'State', value: this.visitRecord.state },
            { label: 'District', value: this.visitRecord.district },
            { label: 'Pincode', value: this.visitRecord.pincode },
            { label: 'Contact Number', value: this.visitRecord.contactNumber }
        ];

        const customerType = this.visitRecord.customerType;
        const visitType = this.visitRecord.visitType;

        if (customerType === 'Existing Primary Customer') {
            return [
                { label: 'Primary Customer', value: this.visitRecord.primaryCustomerName },
                customerTypeField,
                ...commonFormFields
            ];
        }

        if (customerType === 'Existing Secondary Customer') {
            return [
                { label: 'Primary Customer', value: this.visitRecord.primaryCustomerName },
                { label: 'Secondary Customer', value: this.visitRecord.secondaryCustomerName },
                customerTypeField,
                ...commonFormFields
            ];
        }

        if (customerType === 'New Primary Customer') {
            return [
                {
                    label: 'Primary Customer Name',
                    value: this.visitRecord.primaryCustomerNameText
                },
                customerTypeField,
                {
                    label: 'Primary Customer Business Type',
                    value: this.visitRecord.primaryCustomerBusinessType
                },
                ...addressFields,
                ...commonFormFields
            ];
        }

        if (customerType === 'New Sub Stockiest') {
            return [
                { label: 'Sub Stockiest Name', value: this.visitRecord.subStockiestName },
                { label: 'Primary Customer', value: this.visitRecord.primaryCustomerName },
                customerTypeField,
                ...addressFields,
                ...commonFormFields
            ];
        }

        if (customerType === 'New Outlet' && visitType === 'New Market Expansion') {
            return [
                { label: 'Outlet Name', value: this.visitRecord.outletName },
                customerTypeField,
                {
                    label: 'Secondary Customer Business Type',
                    value: this.visitRecord.secondaryCustomerBusinessType
                },
                ...addressFields,
                ...commonFormFields
            ];
        }

        if (customerType === 'New Outlet' && visitType === 'Existing Market Expansion') {
            return [
                { label: 'Outlet Name', value: this.visitRecord.outletName },
                { label: 'Primary Customer', value: this.visitRecord.primaryCustomerName },
                customerTypeField,
                {
                    label: 'Secondary Customer Business Type',
                    value: this.visitRecord.secondaryCustomerBusinessType
                },
                ...addressFields,
                ...commonFormFields
            ];
        }

        return [customerTypeField, ...commonFormFields];
    }

    get hasFormSpecificFields() {
        return this.formSpecificFields.length > 0;
    }

    handleClose() {
        this.dispatchEvent(new CustomEvent('close'));
    }
}