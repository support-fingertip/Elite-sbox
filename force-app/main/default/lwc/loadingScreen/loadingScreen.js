import { LightningElement,api } from 'lwc';

export default class LoadingScreen extends LightningElement {
    placeholders = [];
    @api size = 3;
    connectedCallback(){
       
        this.createPlaceholders(this.size);
    }

    createPlaceholders(count) {
        const tempPlaceholders = [];
        for (let i = 0; i < count; i++) {
            tempPlaceholders.push({
                id: i,
                titleClass: 'card__title loading',
                descriptionClass: 'card__description loading'
            });
        }
        this.placeholders = tempPlaceholders;
    }
}