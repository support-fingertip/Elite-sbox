// customCheckbox.js
import { LightningElement, api } from 'lwc';

export default class CustomCheckbox extends LightningElement {
    @api checked = false;
    @api disabled = false;
    @api label;
    @api name; // Use name instead of data-id for better form handling
    
    handleClick() {
        if (!this.disabled) {
            this.checked = !this.checked;
            this.dispatchEvent(new CustomEvent('change', {
                detail: {
                    checked: this.checked,
                    name: this.name // Pass the name as identifier
                },
                bubbles: true,
                composed: true
            }));
        }
    }

    @api
    setChecked(value) {
        this.checked = value;
       
    }
}