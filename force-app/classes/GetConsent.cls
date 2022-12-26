global class GetConsent {

    @InvocableMethod
    global static List<FlowOutput> execute(List<FlowInput> inputs) {
        FlowOutput output = new FlowOutput();
        //Getting API Information from Tax Status Detail Metadata =    
        Tax_Status_API_Detail__mdt token = Tax_Status_API_Detail__mdt.getInstance('Token');
        Tax_Status_API_Detail__mdt consent = Tax_Status_API_Detail__mdt.getInstance('Consent');
        
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
            request.setHeader('euid',token.Company_Id__c);
            request.setHeader('Authorization', 'Bearer ' + accessToken);
            system.debug('recordId '+recordId);
            Account acc = [SELECT accrue__TIN__c, Phone,PersonEmail,IsPersonAccount,accrue__TIN__pc, Id, Name, LastName, FirstName,
                           PersonMailingStreet, PersonMailingCity, PersonMailingState, PersonMailingPostalCode,
                           BillingStreet, BillingCity, BillingState, BillingPostalCode FROM Account WHERE Id =:recordId LIMIT 1];
            request.setEndpoint(consent.Endpoint__c);
            JSONGenerator gen = JSON.createGenerator(true);
            gen.writeStartObject();
            gen.writeStringField('companyId', token.Company_Id__c);
            gen.writeStringField('tin', acc.IsPersonAccount? acc.accrue__TIN__pc : acc.accrue__TIN__c);
            gen.writeStringField('isCompany', acc.IsPersonAccount? '0' : '1' );
            

            if(acc.IsPersonAccount){
                system.debug(acc.FirstName+acc.LastName+acc.PersonMailingStreet+acc.Phone+acc.PersonEmail);
                if(acc.FirstName==null || acc.LastName==null || acc.PersonMailingStreet==null || acc.PersonMailingCity==null
                   || acc.PersonMailingState==null|| acc.PersonMailingPostalCode==null || acc.Phone==null || acc.PersonEmail==null){
                    output.response = 'Please check First Name, Last Name, Mailing Address, Phone and Email and try again';
                    return new List<FlowOutput> {
                        output
                    };    
                   }
                gen.writeStringField('firstName', acc.FirstName);
                gen.writeStringField('lastName', acc.LastName);
                gen.writeStringField('street', acc.PersonMailingStreet);
                gen.writeStringField('city', acc.PersonMailingCity);
                gen.writeStringField('state', acc.PersonMailingState);
                gen.writeStringField('zip', acc.PersonMailingPostalCode);
                gen.writeStringField('mobile', acc.Phone);
                gen.writeStringField('email', acc.PersonEmail);    
            } else{
                Contact con = [SELECT Id, Name, LastName, FirstName, Email, Phone FROM Contact WHERE AccountId  =:recordId LIMIT 1];
                if(con.FirstName==null || con.LastName==null || acc.BillingStreet==null || acc.BillingState==null
                   || acc.BillingCity==null|| acc.BillingPostalCode==null || con.Phone==null || con.Email==null){
                       output.response = 'Please check First Name, Last Name, Mailing Address, Phone and Email and try again.';
                       return new List<FlowOutput> {
                           output
                               };    
                                   }
                system.debug(con.FirstName+con.LastName+acc.BillingStreet+con.Phone+con.Email);
                gen.writeStringField('firstName', con.FirstName);
                gen.writeStringField('lastName', con.LastName);
                gen.writeStringField('street', acc.BillingStreet);
                gen.writeStringField('city', acc.BillingCity);
                gen.writeStringField('state', acc.BillingState);
                gen.writeStringField('zip', acc.BillingPostalCode);
                gen.writeStringField('mobile', con.Phone);
                gen.writeStringField('email', con.Email);  
            }
            
            gen.writeEndObject();
            request.setBody(gen.getAsString());
            System.debug(gen.getAsString());
            http = new Http();
            response = http.send(request);
            
            if(response.getBody().contains('Ok')){
            	acc.Consent_Status__c ='Submitted to TaxStatus';    
                update acc;
            }
				
            
                    output.response = 'Consent request sent to client.';
                    return new List<FlowOutput> {
                        output
                    };
            
        } catch(exception ex){
            system.debug(ex.getMessage()+ex.getLineNumber());
           	 	    output.response = 'Error While requesting consent';
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