import { LightningElement, wire, track,api } from 'lwc';
import getVisits from '@salesforce/apex/VisitMapController.getVisits';
import USER_ID from '@salesforce/user/Id';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class MapContainerLwc extends LightningElement {
    @api recordId;
    vfUrl;
    @track visitData;
    @track selectedDate = new Date().toISOString().slice(0, 10);
    loading = false;
     _selectedId;
loadMap= false;
    connectedCallback() {
        const baseUrl = window.location.origin;
        this.vfUrl = `${baseUrl}/apex/customMapViewVFP?lcHost=${encodeURIComponent(baseUrl)}`;
        
    }
        @api
        get selectedId() {
        return this._selectedId;
        }
        set selectedId(value) {
     //   alert('Child received selectedId from parent:', value);
            this._selectedId = value;
        this.handleSelectedIdChange(value);
        }

        handleSelectedIdChange(newId) {
            this.visitData=[];
     //   alert('Selected ID changed: ' + newId);
     this.loadMap=false;
         this.sendDataToVf();
        }




    handleDateChange(event) {
        this.selectedDate = event.target.value;
    }

    loadVisits() {
        this.loading = true;
        getVisits({ userId: this.selectedId, selectedDate: this.selectedDate, recId: this.recordId})
            .then((result) => {
                console.log('Visit data received:', result);
                this.visitData = result;
                if(this.visitData.startLat){
                      this.loadMap=true;
                this.sendDataToVf();
                }
                this.loading = false;
               
            })
            .catch((error) => {
                console.error(' Error fetching visits:', error);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error loading visits',
                        message: error.body?.message || 'Unknown error',
                        variant: 'error'
                    })
                );
                this.loading = false;
            });
    }

    handleIframeLoad() {
        if (this.visitData) {
            this.sendDataToVf();
        }
    }

    sendDataToVf() {
        const iframe = this.template.querySelector('iframe');
        if (!iframe ) return;
//  if (!iframe || !this.visitData) return;
        const mapMessage = {
            loadGoogleMap: this.loadMap,
            mapOptionsCenter: {
                lat: this.visitData.startLat,
                lng: this.visitData.startLng
            },
            mapData: this.visitData.visits,
            bUrl:this.visitData.baseUrl,
            tok:this.visitData.tokenapi
        };

        console.log(' Sending dynamic visit data to VF:', mapMessage);

        setTimeout(() => {
            iframe.contentWindow.postMessage(mapMessage, '*');
        }, 1000);
    }
}