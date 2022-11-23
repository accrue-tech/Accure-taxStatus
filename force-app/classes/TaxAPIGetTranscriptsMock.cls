@isTest
global class TaxAPIGetTranscriptsMock implements HttpCalloutMock {
    // Implement this interface method
    global HTTPResponse respond(HTTPRequest req) {
	HttpResponse res = new HttpResponse();  
	res.setHeader('Content-Type', 'application/json');
        if (req.getEndpoint().endsWith('token')){
        res.setBody('{"access_token":"eyJraWQiOiJZMUoyWnBzOHkzWVFSek53RXBzZVhLTU8xR3ljTFBFT0ZMOWlUVXJpQ0hjPSIsImFsZyI6IlJTMjU2In0.eyJzdWIiOiI0dGRmcGdpZGN2aTE2YmhkcjBiNGlkOGVjdiIsInRva2VuX3VzZSI6ImFjY2VzcyIsInNjb3BlIjoidGF4c3RhdHVzLXVhdFwvdWF0LXJlYWQiLCJhdXRoX3RpbWUiOjE2NjkwNzM1NDMsImlzcyI6Imh0dHBzOlwvXC9jb2duaXRvLWlkcC51cy1lYXN0LTEuYW1hem9uYXdzLmNvbVwvdXMtZWFzdC0xX2pWN0RYVm04TSIsImV4cCI6MTY2OTA3NzE0MywiaWF0IjoxNjY5MDczNTQzLCJ2ZXJzaW9uIjoyLCJqdGkiOiJjNDRiNzdmMC1lYzBkLTRiN2QtYTJjZi1lNzBlZTlmYzcxZjEiLCJjbGllbnRfaWQiOiI0dGRmcGdpZGN2aTE2YmhkcjBiNGlkOGVjdiJ9.bHUxUF6xUfbqFEj9XZoW3k4bp-SNOkgJ9LPMG1oG8ZoixtgMBTbdzSSIV4KDMJqBvdBHEsu1868o13ywDr-zllf32re0kuGA2vgErAxWpugNKH8FaxtVny6aFVKrXX2pOB1AuAer5AepC0oRSNrvXFeDHrSwl3_A43uQ4N4rhBEbvKgHNuzL_V3U_Bt5qGO-YB0rPkrXDEp36unbaxvAQHVru_jlJ45HIZCfwC_aKmpxYdc7WMPHuCOvwfWiCd_lZzms83fp6btFzdGV8NCtWpRQmtJ1lV139TVRrGkQP9wfJA2remFOcQnXWrVEDYiKRYey9NYNobnCf9XW5wrZnA","expires_in":3600,"token_type":"Bearer"}');
        }else{
        	res.setBody('[{"TIN":"222222222","LastOrBusiness": "Smith","Period": "201712","ReportDate":"","Form":"1040 ACTR 202212","FormType": "WAID","Transcript":"JVBERi0xLjQKJdPr6eEKMSAwIG9iago8PC9DcmVhdG9yIChDaHJvbWl1bSkKL1Byb2R1Y2VyIChTa2lhL1BERiBtOTYpCi9DcmVhdGlvbkRhdGUgKEQ6MjAyMTEyMTAyMjU0NTArMDAnMDAnKQovTW9kRGF0ZSAoRDoyMDIxMTIxMDIyNTQ1MCswMCcwMCcpPj4KZW5kb2JqCjMgMCBvYmoKPDwvY2EgMQovQk0gL05vcm1hbD4+CmVuZG9iago1IDAgb2JqCjw8L1R5cGUgL1hPYmplY3QKL1N1YnR5cGUgL0ltYWdlCi9XaWR0aCA3NjAKL0hlaWdodCA3MgovQ29sb3JTcGFjZSAvRGV2aWNlUkdCCi9CaXRzUGVyQ29tcG9uZW50IDgKL0ZpbHRlciAvRmxhdGVEZWNvZGUKL0xlbmd0aCA1MDY2Pj4gc3RyZWFtCnic7Z15UBTH28cXARFBFjwQRURULiPifZY/KU9Ao8SYDTFeVSZaHlELj5SJVaKmvAVjhYhHYmI0xhg0VGIsjcajFI"}]');     
        
        }
   	res.setStatusCode(200);
	return res;
    }
}