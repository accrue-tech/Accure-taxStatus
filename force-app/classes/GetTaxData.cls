global class GetTaxData {
    
    private static final Map<String, String> mapQuarter = new Map<String, String>{'03' => 'Quarter 1', '06' => 'Quarter 2', '09' => 'Quarter 3','12' => 'Quarter 4'};
    @InvocableMethod
    global static List<FlowOutput> execute(List<FlowInput> inputs) {
        FlowOutput output = new FlowOutput();
        try{
            FlowInput input = inputs.get(0);
            String recordId = input.recordId;
            HttpRequest request = new HttpRequest();
            request.setMethod('POST');
            request.setHeader('euid', 'HQNZD5CQX8YOV96');
            request.setEndpoint('https://uat-taxstatus-api.auth.us-east-1.amazoncognito.com/oauth2/token');
            String payload = 'grant_type=' + EncodingUtil.urlEncode('client_credentials', 'UTF-8');
            payload = payload + '&client_id=' + EncodingUtil.urlEncode('4tdfpgidcvi16bhdr0b4id8ecv', 'UTF-8');
            payload = payload + '&client_secret=' + EncodingUtil.urlEncode('1jeg2r0danamvbmoavs4dadgeld8oqh5mkk6ngig1p5mnbl84co8', 'UTF-8');
            payload = payload + '&scope=' + EncodingUtil.urlEncode('taxstatus-uat/uat-read', 'UTF-8');
            request.setBody(payload);
            request.setHeader('Content-Type', 'application/x-www-form-urlencoded');
            Http http = new Http();
            HttpResponse response = http.send(request);
            System.debug(response.getBody());
            JSONParse jsonParser = new JSONParse(response.getBody());
            String token = jsonParser.get('access_token').getStringValue();
            request = new HttpRequest();
            request.setMethod('POST');
            request.setHeader('euid', 'HQNZD5CQX8YOV96');
            request.setHeader('Authorization', 'Bearer ' + token);
            system.debug('recordId '+recordId);
            Account acc = [SELECT id,accrue__TIN__pc,IsPersonAccount FROM Account WHERE Id =:recordId LIMIT 1];
            if(acc.IsPersonAccount)
                request.setEndpoint('https://dnh8ze7vli.execute-api.us-east-1.amazonaws.com/uat/api/taxdata/v1/individual');
            else 
                request.setEndpoint('https://dnh8ze7vli.execute-api.us-east-1.amazonaws.com/uat/api/taxdata/v1/business');
            JSONGenerator gen = JSON.createGenerator(true);
            gen.writeStartObject();
            gen.writeStringField('companyId', 'HQNZD5CQX8YOV96');
            if(acc.IsPersonAccount)
                gen.writeStringField('ssn', acc.accrue__TIN__pc);
            else 
                gen.writeStringField('ein', acc.accrue__TIN__pc);
            
            gen.writeEndObject();
            request.setBody(gen.getAsString());
            System.debug(gen.getAsString());
            http = new Http();
            response = http.send(request);
            System.debug(response.getBody());
            system.debug('response.getBody()'+response.getBody());
            if(response.getBody().contains('message')){
                
                Map<String, String> m = (Map<String, String>) JSON.deserialize(response.getBody(), Map<String, String>.class);
                output.response = m.get('message');
                    return new List<FlowOutput> {
                    output
                    };
            }
            TaxDataObject dataObject = (TaxDataObject) System.JSON.deserialize(response.getBody(), TaxDataObject.class);
            List<TaxDataObject> objects = new List<TaxDataObject>();
            system.debug(DataObject.SSN);
            system.debug(DataObject.Data);
            List<Tax_Data__c> listTaxDataToInsert = new List<Tax_Data__c>();
            for(TaxDataInfo taxDataInfo:DataObject.Data){
                Tax_Data__c tempTaxData = new Tax_Data__c();
                 tempTaxData.accrue__Filing_Status__c = taxDataInfo.FilingStatus;
                 tempTaxData.accrue__Annual_Form__c = taxDataInfo.AnnualForm;
                 tempTaxData.accrue__Relationship_Type__c = acc.IsPersonAccount?'Individual':'Business';
                 tempTaxData.accrue__IRS_Balance__c = taxDataInfo.IRSBalance;
                 /*tempTaxData.accrue__Total_Compensation__c
                 tempTaxData.accrue__Total_Sales__c
                 tempTaxData.accrue__Total_Income__c
                 tempTaxData.accrue__Adjusted_Gross_Income__c
                 tempTaxData.accrue__Curently_Not_Collectable_CNC_Date__c
                 tempTaxData.accrue__Audit_Date__c
                 tempTaxData.accrue__Federal_Tax_Deposit_Penalty_Date__c
                 tempTaxData.accrue__Payment_Plan_Issue_Date__c
                 tempTaxData.accrue__Agency_Date__c
                 tempTaxData.accrue__Offer_Date__c
                 tempTaxData.accrue__Extension_Date__c
                 tempTaxData.accrue__Payment_Date__c
                 tempTaxData.accrue__Notice_Date__c
                 tempTaxData.accrue__Levy_Date__c
                 tempTaxData.accrue__Late_Date__c
                 tempTaxData.accrue__Lien_Date__c*/
                 tempTaxData.accrue__Filing_Date__c = taxDataInfo.FileDate;
                 tempTaxData.accrue__Update_Date__c = taxDataInfo.UpdateDate;
                 //tempTaxData.accrue__Form_Type__c
                 tempTaxData.accrue__Form__c = taxDataInfo.Form;
                 string period = String.valueOf(taxDataInfo.Period);
                 tempTaxData.accrue__Tax_Quarter__c = mapQuarter.get(period.substring(5));
                 tempTaxData.accrue__Tax_Year__c = period.substring(0,4);
                 //tempTaxData.accrue__CompanyId__c
                 tempTaxData.accrue__Relationship__c = recordId;
                 tempTaxData.accrue__TIN__c = acc.accrue__TIN__pc;
                listTaxDataToInsert.add(tempTaxData);
            }
            insert listTaxDataToInsert;
            objects.add(DataObject);
            system.debug(objects);
                    output.response = 'Tax data fetched successfully!';
                    return new List<FlowOutput> {
                        output
                    };
            
        } catch(exception ex){
            system.debug(ex.getMessage()+ex.getLineNumber());
           	 	    output.response = 'Error while fetching tax data, try again later.';
                    return new List<FlowOutput> {
                    output
                    };
        }
        
    }
        global class FlowInput {
        @InvocableVariable(required=false)
        global String recordId;
    }
    
        global class FlowOutput {
        @InvocableVariable
        global String response;
    }
}