@RestResource(urlMapping='/consent/*')
global without sharing class GetConsentAPI {
    @HttpPost
    global static string consent() {
      RestRequest req = RestContext.request;
        system.debug(req);
        system.debug(RestContext.request.params.get('x-api-key'));
        accrue__Tax_Status_API_Detail__mdt apiKey = accrue__Tax_Status_API_Detail__mdt.getInstance('API_Key');
        if(RestContext.request.params.get('x-api-key') == apiKey.accrue__API_Key__c){
        	Map<String, Object> params = (Map<String, Object>)JSON.deserializeUntyped(RestContext.request.requestBody.toString());
        Account accToUpdate;
        system.debug(params);
        system.debug(params.get('LastOrBusiness'));
        String lastName = (String)params.get('LastOrBusiness');
        system.debug(params.get('SSN'));
        String ssn = (String)params.get('SSN');
        system.debug(params.get('EIN'));
        String ein = (String)params.get('EIN');
        if (params.get('SSN')!=NULL){
            for(Account acc : [SELECT Id,accrue__TIN__pc, accrue__Consent_Status__c FROM Account WHERE LastName=:lastName]){
                if(acc.accrue__TIN__pc.right(4) == ssn.right(4)){
                	acc.accrue__Consent_Status__c = 'Authorized by Customer';    
                accToUpdate = acc;    
                }
            	acc.accrue__Consent_Status__c = 'Authorized by Customer';    
                accToUpdate = acc;
            }    
        } else if(params.get('EIN')!=NULL){
            for(Account acc : [SELECT Id,accrue__TIN__pc, accrue__Consent_Status__c FROM Account WHERE LastName=:lastName]){
            if(acc.accrue__TIN__c.right(4) == ein.right(4)){
                acc.accrue__Consent_Status__c = 'Authorized by Customer';    
                accToUpdate = acc;    
            }
            acc.accrue__Consent_Status__c = 'Authorized by Customer';    
            accToUpdate = acc;
            }
        }
        update accToUpdate;
        return 'Success';    
        }
        return 'Invalid API Key';         
    } 
    global class MyWrapperClass {
    @InvocableVariable
    @AuraEnabled global String SSN; //200012
    @InvocableVariable
    @AuraEnabled global String EIN; //200012
    @InvocableVariable
    @AuraEnabled global String LastOrBusiness;    //1040

}
}