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
        request.setEndpoint('https://dnh8ze7vli.execute-api.us-east-1.amazonaws.com/uat/api/taxdata/v1/verify');

        Account acc = [SELECT id,accrue__TIN__pc,accrue__Tax_Status__c,IsPersonAccount,LastName FROM Account WHERE Id =:recordId LIMIT 1];
		string taxResult;
        System.debug(acc.accrue__TIN__pc);
        if(!String.ISBLANK(acc.accrue__TIN__pc)){
            JSONGenerator gen = JSON.createGenerator(true);
            gen.writeStartObject();
            gen.writeStringField('companyId', 'HQNZD5CQX8YOV96');
            gen.writeStringField('tin', acc.accrue__TIN__pc);
            gen.writeStringField('isCompany', acc.IsPersonAccount==true?'0':'1');
            gen.writeStringField('lastNameOrBusiness', acc.LastName);
            gen.writeEndObject();
            request.setBody(gen.getAsString());
            System.debug(gen.getAsString());
            http = new Http();
            response = http.send(request);
            System.debug(response.getBody());
            String bodyDataString = response.getBody();
            JSONParse jsonParser1 = new JSONParse(bodyDataString);
            taxResult = jsonParser1.get('Result').getStringValue();
            acc.accrue__Tax_Status__c = taxResult;
            acc.accrue__TIN_Verification_Date__c = system.today();
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