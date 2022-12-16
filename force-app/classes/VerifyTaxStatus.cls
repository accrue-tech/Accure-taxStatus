/**
 * Created by Mangesh on 11/14/22.
 */

global class VerifyTaxStatus {
    @InvocableMethod
    global static List<FlowOutput> execute(List<FlowInput> inputs) {
        FlowInput input = inputs[0];
        string taxResult = makeCallout(input.recordId);
        FlowOutput output = new FlowOutput();
        output.taxResult = taxResult;
        system.debug(output);
        return new List<FlowOutput> {
            output
        };
    }
    public static String makeCallout(String recordId) {

        //Getting API Information from Tax Status Detail Metadata =    
        Tax_Status_API_Detail__mdt token = Tax_Status_API_Detail__mdt.getInstance('Token');
        Tax_Status_API_Detail__mdt verify = Tax_Status_API_Detail__mdt.getInstance('Verify');
        
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
        String access_token = jsonParser.get('access_token').getStringValue();
        request = new HttpRequest();
        request.setMethod('POST');
        request.setHeader('euid', token.Company_Id__c);
        request.setHeader('Authorization', 'Bearer ' + access_token);
        request.setEndpoint(verify.Endpoint__c);

        Account acc = [SELECT id,accrue__TIN__pc,accrue__TIN__c,TIN_Verification_Status__c,IsPersonAccount,LastName,Name FROM Account WHERE Id =:recordId LIMIT 1];
        string taxResult;
        System.debug(acc.IsPersonAccount);
        System.debug(acc.accrue__TIN__pc);
        System.debug(acc.accrue__TIN__c);
        if(acc.IsPersonAccount?!String.ISBLANK(acc.accrue__TIN__pc):!String.ISBLANK(acc.accrue__TIN__c)){
            JSONGenerator gen = JSON.createGenerator(true);
            gen.writeStartObject();
            gen.writeStringField('companyId', token.Company_Id__c);
            gen.writeStringField('tin', acc.IsPersonAccount?acc.accrue__TIN__pc:acc.accrue__TIN__c);
            gen.writeStringField('isCompany', acc.IsPersonAccount?'0':'1');
            gen.writeStringField('lastNameOrBusiness', acc.IsPersonAccount?acc.LastName:acc.Name);
            gen.writeEndObject();
            request.setBody(gen.getAsString());
            System.debug(gen.getAsString());
            http = new Http();
            response = http.send(request);
            System.debug(response.getBody());
            String bodyDataString = response.getBody();
            JSONParse jsonParser1 = new JSONParse(bodyDataString);
            taxResult = jsonParser1.get('Result').getStringValue();
            acc.TIN_Verification_Status__c = taxResult;
            acc.TIN_Verification_Date__c = system.today();
    }
    update acc;
    return taxResult;
    }

    global class FlowInput {
        @InvocableVariable(required=false)
        global String recordId;
    }

    global class FlowOutput {
        @InvocableVariable
        global String taxResult;
    }
}