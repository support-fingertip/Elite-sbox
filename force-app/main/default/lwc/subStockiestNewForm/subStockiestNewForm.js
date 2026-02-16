import { LightningElement, track } from 'lwc';

export default class SubStockiestNewForm extends LightningElement {


@track state = 'Maharashtra';
@track district = 'Mumbai';

@track productGroups = [
    { id:1, number:1, value:'' }
];


customerTypeOptions = [
    { label:'Sub Stockiest', value:'SubStockiest'}
];


visitTypeOptions = [
    { label:'New Market Expansion', value:'New'}
];


businessTypeOptions = [
    { label:'Distributor', value:'Distributor'},
    { label:'Retailer', value:'Retailer'}
];


categoryOptions = [
    { label:'Bakery', value:'Bakery'},
    { label:'Beverages', value:'Beverages'}
];


groupOptions = [
    { label:'Group A', value:'A'},
    { label:'Group B', value:'B'}
];


stateOptions = [
    { label:'Maharashtra', value:'Maharashtra'},
    { label:'Gujarat', value:'Gujarat'}
];


districtMap = {

    Maharashtra:[
        { label:'Mumbai', value:'Mumbai'},
        { label:'Pune', value:'Pune'}
    ],

    Gujarat:[
        { label:'Ahmedabad', value:'Ahmedabad'},
        { label:'Surat', value:'Surat'}
    ]

};


@track districtOptions=[];


connectedCallback(){

    this.updateDistrict();

}


updateDistrict(){

    this.districtOptions = this.districtMap[this.state];

}


handleStateChange(event){

    this.state = event.detail.value;

    this.updateDistrict();

}


handleDistrictChange(event){

    this.district = event.detail.value;

}


handleAddGroup(){

    const next = this.productGroups.length + 1;

    this.productGroups = [
        ...this.productGroups,
        { id:next, number:next, value:'' }
    ];

}


handleGroupChange(event){

    const index = event.target.dataset.index;

    this.productGroups[index].value = event.detail.value;

}


handleBack(){

    this.dispatchEvent(new CustomEvent('back'));

}


handleSubmit(){

    console.log('Sub Stockiest New Submitted');

}

}