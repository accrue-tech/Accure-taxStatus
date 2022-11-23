@isTest
global class GetTaxDataMock implements HttpCalloutMock {
    // Implement this interface method
    global HTTPResponse respond(HTTPRequest req) {
	HttpResponse res = new HttpResponse();  
	res.setHeader('Content-Type', 'application/json');
	res.setBody('{"access_token":"dddsadasxsaxasxasx","instance_url":"https://login.salesforce.com","SSN":"XXX-XX-2222","LastOrBusiness":"Smith","Data":[{"Period":201212,"Form":"1040","FormType":"ACTR","UpdateDate":"01/12/2022","FilingStatus":"Married Filing Joint","AnnualForm":"1040","AGI":79063,"IRSBalance":0,"FileDate":"09-02-2013","ExtensionDate":"04-15-2013","EmptyMessage":""}]}');
	res.setStatusCode(200);
	return res;
    }
}