import { LightningElement, api } from 'lwc';
import GOOGLE_ICONS from '@salesforce/resourceUrl/googleIcons';
import SummaryDate from '@salesforce/apex/beatPlannerlwc.getSummeryData';

export default class BusinessSummary extends LightningElement {

    @api visitId;
    @api isDesktop;
    @api objName;
    isPageLoaded = false;
    outstanding = false;
    order = false;
    sales = false;
    visit = false;
    rtn = false;
    summeryIcons ={
        summery :  GOOGLE_ICONS + "/googleIcons/summery.png",
    }
    businessSummary = [];
    connectedCallback(){
        this.isPageLoaded = true;
        this.getSummaryData();
    }

    getSummaryData(){
        SummaryDate({
            ids : this.visitId,
            objName : this.objName
         })
         .then(result =>{
            
            if(this.objName == 'outstanding'){
                this.outstanding = true;
                this.businessSummary = Object.entries(result).map(([date, data]) => ({
                    date: date,
                    details: data.outData
                }));
            }
            else if(this.objName == 'order'){
                this.order = true;
                this.businessSummary = Object.entries(result).map(([date, data]) => ({
                    date: date,
                    details: data.ordData
                }));
            }
            else if(this.objName == 'sales'){
                this.sales = true;
                this.businessSummary = Object.entries(result).map(([date, data]) => ({
                    date: date,
                    details: data.sales
                }));
            }
            else if(this.objName == 'visit'){
                this.visit = true;
                this.businessSummary = Object.entries(result).map(([date, data]) => ({
                    date: date,
                    details: data.SummaryvisitData
                }));
            }
             else if(this.objName == 'return'){
                this.rtn = true;
                this.businessSummary = Object.entries(result).map(([date, data]) => ({
                    date: date,
                    details: data.summaryReturnData
                }));
            }
            this.isPageLoaded = false;
            console.log(result);
         })
         .catch(error =>{
            console.log(error);
            this.isPageLoaded = false;
         });
    }
}