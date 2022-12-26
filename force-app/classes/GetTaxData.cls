global class GetTaxData {
    
    private static final Map<String, String> mapQuarter = new Map<String, String>{'03' => 'Quarter 1', '06' => 'Quarter 2', '09' => 'Quarter 3','12' => 'Quarter 4'};
    @InvocableMethod
    global static List<FlowOutput> execute(List<FlowInput> inputs) {
        FlowOutput output = new FlowOutput();
        //Getting API Information from Tax Status Detail Metadata =    
        Tax_Status_API_Detail__mdt token = Tax_Status_API_Detail__mdt.getInstance('Token');
        Tax_Status_API_Detail__mdt individual = Tax_Status_API_Detail__mdt.getInstance('Individual');
        Tax_Status_API_Detail__mdt business = Tax_Status_API_Detail__mdt.getInstance('Business');
        
        try{
            FlowInput input = inputs.get(0);
            String recordId = input.recordId;
            HttpRequest request = new HttpRequest();
            request.setMethod('POST');
            request.setHeader('euid', token.Company_Id__c);
            request.setEndpoint(token.Endpoint__c);
            String payload = 'grant_type=' + EncodingUtil.urlEncode('client_credentials', 'UTF-8');
            payload = payload + '&client_id=' + EncodingUtil.urlEncode(token.Client_Id__c, 'UTF-8');
            payload = payload + '&client_secret=' + EncodingUtil.urlEncode(token.Client_Secret__c, 'UTF-8');
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
            request.setHeader('euid', token.Company_Id__c);
            request.setHeader('Authorization', 'Bearer ' + accessToken);
            system.debug('recordId '+recordId);
            Account acc = [SELECT id,accrue__TIN__pc,accrue__TIN__c,IsPersonAccount FROM Account WHERE Id =:recordId LIMIT 1];
            system.debug('token.Company_Id__c '+token.Company_Id__c+'==>'+acc.accrue__TIN__pc+'==>'+acc.accrue__TIN__c);
            if(acc.IsPersonAccount)
                request.setEndpoint(individual.Endpoint__c);
            else 
                request.setEndpoint(business.Endpoint__c);
            JSONGenerator gen = JSON.createGenerator(true);
            gen.writeStartObject();
            system.debug('token.Company_Id__c '+token.Company_Id__c+'==>'+acc.accrue__TIN__pc+'==>'+acc.accrue__TIN__c);
            gen.writeStringField('companyId', token.Company_Id__c);
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
                 tempTaxData.Filing_Status__c = taxDataInfo.FilingStatus;
                 tempTaxData.Annual_Form__c = taxDataInfo.AnnualForm;
                 tempTaxData.Relationship_Type__c = acc.IsPersonAccount?'Individual':'Business';
                 tempTaxData.IRS_Balance__c = taxDataInfo.IRSBalance;
                 /*tempTaxData.Total_Compensation__c
                 tempTaxData.Total_Sales__c
                 tempTaxData.Total_Income__c
                 tempTaxData.Adjusted_Gross_Income__c
                 tempTaxData.Curently_Not_Collectable_CNC_Date__c
                 tempTaxData.Audit_Date__c
                 tempTaxData.Federal_Tax_Deposit_Penalty_Date__c
                 tempTaxData.Payment_Plan_Issue_Date__c
                 tempTaxData.Agency_Date__c
                 tempTaxData.Offer_Date__c
                 tempTaxData.Extension_Date__c
                 tempTaxData.Payment_Date__c
                 tempTaxData.Notice_Date__c
                 tempTaxData.Levy_Date__c
                 tempTaxData.Late_Date__c
                 tempTaxData.Lien_Date__c*/
                 tempTaxData.Filing_Date__c = taxDataInfo.FileDate;
                 tempTaxData.Update_Date__c = taxDataInfo.UpdateDate;
                 tempTaxData.Form_Type__c = taxDataInfo.FormType;
                 tempTaxData.Form__c = taxDataInfo.Form;
                 string period = String.valueOf(taxDataInfo.Period);
                 system.debug(period.substring(5));
                 system.debug(mapQuarter.get(period.substring(4)));
                 tempTaxData.Tax_Quarter__c = mapQuarter.get(period.substring(4));
                 tempTaxData.Tax_Year__c = period.substring(0,4);
                 //tempTaxData.CompanyId__c
                 tempTaxData.Relationship__c = recordId;
                	system.debug(acc.IsPersonAccount?acc.accrue__TIN__pc:acc.accrue__TIN__c);
                system.debug(acc.IsPersonAccount);
                system.debug(acc.accrue__TIN__c);
                 tempTaxData.TIN__c = acc.IsPersonAccount?acc.accrue__TIN__pc:acc.accrue__TIN__c;
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