import { LightningElement, track } from 'lwc';

export default class OutletExistingForm extends LightningElement {

    // ===============================
    // TRACKED FIELDS
    // ===============================

    @track outlet;
    @track category;
    @track competitorName;
    @track competitorProduct;
    @track competitorRemarks;
    @track generalRemarks;

    @track state = 'MH';
    @track district;

    // ===============================
    // PRODUCT GROUPS (Dynamic)
    // ===============================

    @track productGroups = [
        {
            id: 1,
            number: 1,
            value: ''
        }
    ];


    // ===============================
    // OPTIONS
    // ===============================

    outletOptions = [
        { label: 'Outlet A', value: 'A' },
        { label: 'Outlet B', value: 'B' }
    ];


    categoryOptions = [
        { label: 'Bakery', value: 'bakery' },
        { label: 'Beverages', value: 'beverages' }
    ];


    groupOptions = [
        { label: 'Group A', value: 'A' },
        { label: 'Group B', value: 'B' },
        { label: 'Group C', value: 'C' }
    ];


    stateOptions = [
        { label: 'Maharashtra', value: 'MH' }
    ];


    districtMap = {

        MH: [
            { label: 'Mumbai', value: 'Mumbai' },
            { label: 'Pune', value: 'Pune' },
            { label: 'Nagpur', value: 'Nagpur' },
            { label: 'Nashik', value: 'Nashik' }
        ]

    };


    // ===============================
    // GET DISTRICT OPTIONS
    // ===============================

    get districtOptions() {

        return this.districtMap[this.state] || [];

    }


    // ===============================
    // HANDLE FIELD CHANGE
    // ===============================

    handleChange(event) {

        const field = event.target.label;
        const value = event.detail.value;

        switch(field){

            case 'Outlet *':
                this.outlet = value;
                break;

            case 'Product Category *':
                this.category = value;
                break;

            case 'Competitor Name *':
                this.competitorName = value;
                break;

            case 'Competitor Product *':
                this.competitorProduct = value;
                break;

            case 'Competitor Remarks *':
                this.competitorRemarks = value;
                break;

            case 'General Remarks *':
                this.generalRemarks = value;
                break;

        }

    }


    // ===============================
    // HANDLE DISTRICT CHANGE
    // ===============================

    handleDistrictChange(event){

        this.district = event.detail.value;

    }


    // ===============================
    // ADD PRODUCT GROUP
    // ===============================

    handleAddGroup(){

        const nextNumber = this.productGroups.length + 1;

        const newGroup = {

            id: nextNumber,
            number: nextNumber,
            value: ''

        };

        this.productGroups = [...this.productGroups, newGroup];

    }


    // ===============================
    // HANDLE PRODUCT GROUP CHANGE
    // ===============================

    handleGroupChange(event){

        const index = event.target.dataset.index;

        this.productGroups[index].value = event.detail.value;

        this.productGroups = [...this.productGroups];

    }


    // ===============================
    // BACK BUTTON → VisitForm
    // ===============================

    handleBack(){

        this.dispatchEvent(new CustomEvent('back'));

    }


    // ===============================
    // CANCEL
    // ===============================

    handleCancel(){

        this.handleBack();

    }


    // ===============================
    // SUBMIT
    // ===============================

    handleSubmit(){

        const formData = {

            outlet: this.outlet,
            category: this.category,
            productGroups: this.productGroups,
            competitorName: this.competitorName,
            competitorProduct: this.competitorProduct,
            competitorRemarks: this.competitorRemarks,
            generalRemarks: this.generalRemarks,
            state: this.state,
            district: this.district

        };

        console.log('Outlet Existing Market Form Data:', JSON.stringify(formData));

    }

}