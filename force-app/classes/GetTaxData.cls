global class GetTaxData {
    
    private static final Map<String, String> mapQuarter = new Map<String, String>{'03' => 'Quarter 1', '06' => 'Quarter 2', '09' => 'Quarter 3','12' => 'Quarter 4'};
    @InvocableMethod
    global static List<FlowOutput> execute(List<FlowInput> inputs) {
        FlowOutput output = new FlowOutput();
        //Getting API Information from Tax Status Detail Metadata =    
        accrue__Tax_Status_API_Detail__mdt token = accrue__Tax_Status_API_Detail__mdt.getInstance('Token');
        accrue__Tax_Status_API_Detail__mdt individual = accrue__Tax_Status_API_Detail__mdt.getInstance('Individual');
        accrue__Tax_Status_API_Detail__mdt business = accrue__Tax_Status_API_Detail__mdt.getInstance('Business');
        
        try{
            FlowInput input = inputs.get(0);
            String recordId = input.recordId;
            HttpRequest request = new HttpRequest();
            request.setMethod('POST');
            request.setHeader('euid', token.accrue__Company_Id__c);
            request.setEndpoint(token.accrue__Endpoint__c);
            String payload = 'grant_type=' + EncodingUtil.urlEncode('client_credentials', 'UTF-8');
            payload = payload + '&client_id=' + EncodingUtil.urlEncode(token.accrue__Client_Id__c, 'UTF-8');
            payload = payload + '&client_secret=' + EncodingUtil.urlEncode(token.accrue__Client_Secret__c, 'UTF-8');
            payload = payload + '&scope=' + EncodingUtil.urlEncode('taxstatus-uat/uat-read', 'UTF-8');
            request.setBody(payload);
            request.setHeader('Content-Type', 'application/x-www-form-urlencoded');
            Http http = new Http();
            HttpResponse response = http.send(request);
            System.debug(response.getBody());
            JSONParse jsonParser = new JSONParse(response.getBody());
            String accessToken = jsonParser.get('access_token').getStringValue();
            request = new HttpRequest();
            request.setMethod('POST');
            request.setHeader('euid', token.accrue__Company_Id__c);
            request.setHeader('Authorization', 'Bearer ' + accessToken);
            system.debug('recordId '+recordId);
            Account acc = [SELECT id,accrue__TIN__pc,accrue__TIN__c,IsPersonAccount FROM Account WHERE Id =:recordId LIMIT 1];
            system.debug('token.accrue__Company_Id__c '+token.accrue__Company_Id__c+'==>'+acc.accrue__TIN__pc+'==>'+acc.accrue__TIN__c);
            if(acc.IsPersonAccount)
                request.setEndpoint(individual.accrue__Endpoint__c);
            else 
                request.setEndpoint(business.accrue__Endpoint__c);
            JSONGenerator gen = JSON.createGenerator(true);
            gen.writeStartObject();
            system.debug('token.accrue__Company_Id__c '+token.accrue__Company_Id__c+'==>'+acc.accrue__TIN__pc+'==>'+acc.accrue__TIN__c);
            gen.writeStringField('companyId', token.accrue__Company_Id__c);
            if(acc.IsPersonAccount)
                gen.writeStringField('ssn', acc.accrue__TIN__pc);
            else 
                gen.writeStringField('ein', acc.accrue__TIN__c);
            
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
                 tempTaxData.accrue__Form_Type__c = taxDataInfo.FormType;
                 tempTaxData.accrue__Form__c = taxDataInfo.Form;
                 string period = String.valueOf(taxDataInfo.Period);
                 system.debug(period.substring(5));
                 system.debug(mapQuarter.get(period.substring(4)));
                 tempTaxData.accrue__Tax_Quarter__c = mapQuarter.get(period.substring(4));
                 tempTaxData.accrue__Tax_Year__c = period.substring(0,4);
                 //tempTaxData.accrue__CompanyId__c
                 tempTaxData.accrue__Relationship__c = recordId;
                	system.debug(acc.IsPersonAccount?acc.accrue__TIN__pc:acc.accrue__TIN__c);
                system.debug(acc.IsPersonAccount);
                system.debug(acc.accrue__TIN__c);
                 tempTaxData.accrue__TIN__c = acc.IsPersonAccount?acc.accrue__TIN__pc:acc.accrue__TIN__c;
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