import { LightningElement, api, track, wire } from 'lwc';


export default class NewBeatMaster extends LightningElement {
  @api recordId;
  @track isPage1 = true;
  @track isPage2 = false;

    connectedCallback() {
        console.log('Record ID passed to LWC12:', this.recordId);  // Check if it’s received properly
    }

  handleNextPage(event) {
    this.recordId = event.detail.beatId;
   // alert(this.recordId);
    this.isPage1 = false;
    this.isPage2 = true;
  }

  genericToastDispatchEvent(title, message, variant) {
    this.dispatchEvent(
      new ShowToastEvent({
        title: title,
        message: message,
        variant: variant
      })
    );
  }
}