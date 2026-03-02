import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class SubStockiestNew extends LightningElement {


    @track customerType='';
    @track visitType='';
    @track subStockiestName='';
    @track secondaryBusinessType='';
    @track productCategory='';
    @track primaryBusinessType='';
    @track competitorName='';
    @track competitorProduct='';
    @track competitorRemarks='';
    @track generalRemarks='';
    @track address='';
    @track state='';
    @track district='';
    @track pinCode='';
    @track contactNumber='';

    outletImageUploaded=false;



    @track productGroups=[{id:1,value:''}];


    customerTypeOptions=[
        {label:'Sub Stockiest',value:'Sub Stockiest'}
    ];

    visitTypeOptions=[
        {label:'New Market Expansion',value:'New Market Expansion'}
    ];

    categoryOptions=[
        {label:'Bakery',value:'Bakery'},
        {label:'Staple',value:'Staple'}
    ];

    groupOptions=[
        {label:'Cookies',value:'Cookies'},
        {label:'Cake',value:'Cake'}
    ];

    businessTypeOptions=[
        {label:'Retail',value:'Retail'},
        {label:'Wholesale',value:'Wholesale'}
    ];

    stateOptions=[
        {label:'Maharashtra',value:'Maharashtra'},
        {label:'Gujarat',value:'Gujarat'}
    ];



    stateDistrictMap={

        Maharashtra:[
            {label:'Mumbai',value:'Mumbai'},
            {label:'Pune',value:'Pune'}
        ],

        Gujarat:[
            {label:'Ahmedabad',value:'Ahmedabad'},
            {label:'Surat',value:'Surat'}
        ]

    };



    get districtOptions(){

        return this.stateDistrictMap[this.state] || [];

    }



    handleStateChange(event){

        this.state=event.detail.value;
        this.district='';

    }



    handleDistrictChange(event){

        this.district=event.detail.value;

    }



    handleChange(event){

        const field=event.target.dataset.field;
        this[field]=event.detail.value;

    }



    handleProductGroupChange(event){

        const index=event.target.dataset.index;
        this.productGroups[index].value=event.detail.value;

    }



    handleAddProductGroup(){

        this.productGroups=[
            ...this.productGroups,
            {id:this.productGroups.length+1,value:''}
        ];

    }



    handleProductUpload(){}



    handleOutletUpload(){

        this.outletImageUploaded=true;

    }



    handleBack(){

        this.dispatchEvent(new CustomEvent('back'));

    }



    handleSubmit(){

        let valid=true;

        const inputs=this.template.querySelectorAll(
            'lightning-input, lightning-combobox, lightning-textarea'
        );

        inputs.forEach(input=>{
            if(input.required && !input.checkValidity()){
                input.reportValidity();
                valid=false;
            }
        });

        if(this.productGroups.some(g=>!g.value)){
            valid=false;
        }

        if(!this.outletImageUploaded){
            this.showToast('Error','Outlet Image required','error');
            valid=false;
        }

        if(!valid) return;

        this.showToast('Success','Form Submitted Successfully','success');

    }



    showToast(title,message,variant){

        this.dispatchEvent(
            new ShowToastEvent({title,message,variant})
        );

    }

}