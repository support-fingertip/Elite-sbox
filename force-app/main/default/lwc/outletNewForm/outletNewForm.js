import { LightningElement, track } from 'lwc';

export default class OutletNewForm extends LightningElement {

    // navigation
    handleBack(){
        this.dispatchEvent(new CustomEvent('back'));
    }

    // values
    customerType;
    visitType;
    outletName;
    secondaryBusiness;
    productCategory;
    primaryBusiness;
    competitorName;
    competitorProduct;
    competitorRemarks;
    generalRemarks;
    address;
    state='MH';
    district;
    pin;
    contact;


    // dynamic groups
    @track productGroups=[
        {id:1,number:1,value:''}
    ];

    handleAddGroup(){

        const next=this.productGroups.length+1;

        this.productGroups=[
            ...this.productGroups,
            {id:next,number:next,value:''}
        ];
    }

    handleGroupChange(e){

        const index=e.target.dataset.index;

        this.productGroups[index].value=e.detail.value;
    }


    // options

    customerTypeOptions=[
        {label:'Outlet',value:'outlet'}
    ];

    visitTypeOptions=[
        {label:'New Market',value:'new'}
    ];

    categoryOptions=[
        {label:'Bakery',value:'bakery'},
        {label:'Beverages',value:'bev'}
    ];

    groupOptions=[
        {label:'Group A',value:'A'},
        {label:'Group B',value:'B'}
    ];

    primaryBusinessOptions=[
        {label:'Retailer',value:'retailer'}
    ];

    secondaryBusinessOptions=[
        {label:'Grocery',value:'grocery'}
    ];

    stateOptions=[
        {label:'Maharashtra',value:'MH'}
    ];

    districtMap={

        MH:[
            {label:'Mumbai',value:'Mumbai'},
            {label:'Pune',value:'Pune'},
            {label:'Nagpur',value:'Nagpur'}
        ]
    };

    get districtOptions(){

        return this.districtMap[this.state]||[];
    }


    handleStateChange(e){

        this.state=e.detail.value;
        this.district=null;
    }

    handleDistrictChange(e){

        this.district=e.detail.value;
    }


    // handlers

    handleCustomerType(e){this.customerType=e.detail.value;}
    handleVisitType(e){this.visitType=e.detail.value;}
    handleOutletName(e){this.outletName=e.detail.value;}
    handleSecondaryBusiness(e){this.secondaryBusiness=e.detail.value;}
    handleCategory(e){this.productCategory=e.detail.value;}
    handlePrimaryBusiness(e){this.primaryBusiness=e.detail.value;}
    handleCompetitorName(e){this.competitorName=e.detail.value;}
    handleCompetitorProduct(e){this.competitorProduct=e.detail.value;}
    handleCompetitorRemarks(e){this.competitorRemarks=e.detail.value;}
    handleGeneralRemarks(e){this.generalRemarks=e.detail.value;}
    handleAddress(e){this.address=e.detail.value;}
    handlePin(e){this.pin=e.detail.value;}
    handleContact(e){this.contact=e.detail.value;}

}