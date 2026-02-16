import { LightningElement, track } from 'lwc';

export default class ExistingSecondaryForm extends LightningElement {

    @track primaryCustomer = '';
    @track secondaryCustomer = '';
    @track productCategory = '';
    @track competitorName = '';
    @track competitorProduct = '';
    @track competitorRemarks = '';
    @track generalRemarks = '';

    @track productGroups = [
        {
            id: 1,
            number: 1,
            value: ''
        }
    ];


    primaryOptions = [
        { label: 'ABC Distributors', value: 'abc' }
    ];

    secondaryOptions = [
        { label: 'Retailer A', value: 'retA' }
    ];

    categoryOptions = [
        { label: 'Bakery', value: 'bakery' }
    ];

    groupOptions = [
        { label: 'Group A', value: 'a' }
    ];


    handlePrimaryChange(e){
        this.primaryCustomer = e.detail.value;
    }

    handleSecondaryChange(e){
        this.secondaryCustomer = e.detail.value;
    }

    handleCategoryChange(e){
        this.productCategory = e.detail.value;
    }

    handleGroupChange(e){

        const index = e.target.dataset.index;

        this.productGroups[index].value = e.detail.value;

        this.productGroups = [...this.productGroups];

    }

    handleAddGroup(){

        const next = this.productGroups.length + 1;

        this.productGroups = [
            ...this.productGroups,
            {
                id: next,
                number: next,
                value: ''
            }
        ];

    }


    handleCompetitorName(e){
        this.competitorName = e.detail.value;
    }

    handleCompetitorProduct(e){
        this.competitorProduct = e.detail.value;
    }

    handleCompetitorRemarks(e){
        this.competitorRemarks = e.detail.value;
    }

    handleGeneralRemarks(e){
        this.generalRemarks = e.detail.value;
    }


    handleBack(){
        this.dispatchEvent(new CustomEvent('back'));
    }

    handleCancel(){
        this.dispatchEvent(new CustomEvent('back'));
    }

    handleSubmit(){

        const data = {

            primaryCustomer: this.primaryCustomer,
            secondaryCustomer: this.secondaryCustomer,
            productCategory: this.productCategory,
            productGroups: this.productGroups,
            competitorName: this.competitorName,
            competitorProduct: this.competitorProduct,
            competitorRemarks: this.competitorRemarks,
            generalRemarks: this.generalRemarks

        };

        console.log(JSON.stringify(data));

    }

}