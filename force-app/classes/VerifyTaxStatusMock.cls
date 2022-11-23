@isTest
global class VerifyTaxStatusMock implements HttpCalloutMock {
    // Implement this interface method
    global HTTPResponse respond(HTTPRequest req) {
	HttpResponse res = new HttpResponse();  
	res.setHeader('Content-Type', 'application/json');
	res.setBody('{"access_token":"dddsadasxsaxasxasx","instance_url":"https://login.salesforce.com","TIN":"222222222","Result":"Valid"}');
	res.setStatusCode(200);
	return res;
    }
}