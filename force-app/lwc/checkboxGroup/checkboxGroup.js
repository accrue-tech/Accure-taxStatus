import { LightningElement,track,api } from 'lwc';

export default class CheckboxGroup extends LightningElement {
    value = [];
    @api year;
    @track options=[
            { label: 'Q1', value: 'Q1' },
            { label: 'Q2', value: 'Q2' },
            { label: 'Q3', value: 'Q3' },
            { label: 'Q4', value: 'Q4' },
        ];
    
    handleChange(event){
        console.log('Year',this.year);
        this.value=event.detail.value;
        console.log('Year1',this.value);
        let selectedValues = this.value.join(',');
        const sendData = new CustomEvent('senddata', {
            detail: {
                year: this.year,
                quarter:selectedValues
            } 
        });

        this.dispatchEvent(sendData);
    }

}