import { LightningElement,track,api } from 'lwc';
import execute from '@salesforce/apex/TaxAPIGetTranscripts.execute';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import {NavigationMixin} from 'lightning/navigation';    
export default class TaxReturn extends  NavigationMixin(LightningElement) {

    @track  allYears=[];
    @api recordId;
    @track map = new Map();
    @track message;
    @track error;
    connectedCallback(){
        const year = new Date().getFullYear(); 
        for(let i = 0;i<=10;i++){
        this.allYears.push(year-i);
        }
        console.log('this.allYear',this.allYears);
    }

    handleData(event){
        console.log('Data',event.detail.year);
        console.log('Data',event.detail.quarter);
        const year = event.detail.year;
        const quarter = event.detail.quarter;
        console.log('Data1',year);
        console.log('Data1',quarter);

        this.map.set(year, quarter);
        console.log('Map',this.map);
    }


    handleClick(){
        console.log('Map TEST2',this.map);
        console.log('Map TEST1',this.recordId);
		execute({ recordId: this.recordId, mapPeriod: this.map})
		.then(result => {

			this.message = result;
			this.error = undefined;
            console.log('Map1',this.message);
            console.log('Map2',this.error);

            const event = new ShowToastEvent({
                title: 'Success',
                message: 'Transcripts requested for given TIN and date.',
                variant: 'success',
                mode: 'dismissable'
            });
            this.dispatchEvent(event);
            
            this[NavigationMixin.Navigate]({
                type:'standard__recordPage',
                attributes:{
                    "recordId":this.recordId,
                    "objectApiName":"Account",
                    "actionName": "view"
                }
            });

		})
		.catch(error => {
			this.error = error;
			this.message = undefined;
            console.log('Map3',this.message);
            console.log('Map4',this.error);

            const evt = new ShowToastEvent({
                title: 'Error',
                message: 'Some unexpected error occure, please try again later',
                variant: 'error',
                mode: 'dismissable'
            });
            this.dispatchEvent(evt);

            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: this.recordId,
                    objectApiName: "Account", // objectApiName is optional
                    actionName: 'view'
                }
            });
    
            


		})
	} 
}