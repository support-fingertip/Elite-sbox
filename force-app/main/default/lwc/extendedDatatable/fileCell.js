import { LightningElement, api } from 'lwc';

export default class FileCell extends LightningElement {
    @api typeAttributes;

    get hasFiles() {
         alert(1);
        alert(this.typeAttributes.files);
        return this.typeAttributes && this.typeAttributes.files && this.typeAttributes.files.length > 0;
    }
     @api
    set files(value) {
        console.log('Files received in custom cell:', value);
        // Re-assign the value if needed, though this is primarily for debugging
        this._files = value;
    }
    get files() {
        return this._files;
    }
}