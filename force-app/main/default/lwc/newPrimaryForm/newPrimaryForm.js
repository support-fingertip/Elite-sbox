import { LightningElement, track } from 'lwc';

export default class NewPrimaryForm extends LightningElement {


@track customerType;
@track customerName;
@track productCategory;
@track businessType;
@track competitorName;
@track competitorProduct;
@track competitorRemarks;
@track generalRemarks;
@track address;
@track pinCode;
@track contactNumber;


@track state = 'Maharashtra';
@track district = 'Mumbai';


@track productGroups = [
    { id: 1, number: 1, value: '' }
];


customerTypeOptions = [
    { label:'Retailer', value:'Retailer'},
    { label:'Distributor', value:'Distributor'}
];


categoryOptions = [
    { label:'Bakery', value:'Bakery'},
    { label:'Beverages', value:'Beverages'}
];


groupOptions = [
    { label:'Group A', value:'Group A'},
    { label:'Group B', value:'Group B'},
    { label:'Group C', value:'Group C'}
];


businessTypeOptions = [
    { label:'Retail', value:'Retail'},
    { label:'Wholesale', value:'Wholesale'}
];


stateOptions = [
    { label:'Maharashtra', value:'Maharashtra'},
    { label:'Gujarat', value:'Gujarat'}
];


districtMap = {

    Maharashtra: [
        { label:'Mumbai', value:'Mumbai'},
        { label:'Pune', value:'Pune'}
    ],

    Gujarat: [
        { label:'Ahmedabad', value:'Ahmedabad'},
        { label:'Surat', value:'Surat'}
    ]

};


@track districtOptions = [];


connectedCallback(){

    this.updateDistrictOptions();

}


updateDistrictOptions(){

    this.districtOptions = this.districtMap[this.state];

}


handleStateChange(event){

    this.state = event.detail.value;

    this.updateDistrictOptions();

}


handleDistrictChange(event){

    this.district = event.detail.value;

}


handleAddGroup(){

    const next = this.productGroups.length + 1;

    this.productGroups = [

        ...this.productGroups,

        { id: next, number: next, value: '' }

    ];

}


handleGroupChange(event){

    const index = event.target.dataset.index;

    this.productGroups[index].value = event.detail.value;

    this.productGroups = [...this.productGroups];

}


handleBack(){

    this.dispatchEvent(new CustomEvent('back'));

}


handleSubmit(){

    console.log('Form submitted');

}

}