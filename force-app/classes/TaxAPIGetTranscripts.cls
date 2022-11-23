global class TaxAPIGetTranscripts {
    @AuraEnabled
    public static void execute(String recordId, Map<String,String> mapPeriod) {
        HttpRequest request = new HttpRequest();
        String jsonBody = '{\n' +
                '  "companyId": "HQNZD5CQX8YOV96",\n' +
                '  "tin": "222222222",\n' +
                '  "needPDF":true,\n' +
                '  "transcripts": [{\n' +
                '\t"transcriptType": "ACTR",\n' +
                '\t"transcriptForm": "1040",\n' +
                '\t"transcriptPeriod": "201612"\n' +
                '},\n' +
                '{\n' +
                '\t"transcriptType": "WAID",\n' +
                '\t"transcriptForm": "INCOME",\n' +
                '\t"transcriptPeriod": "201712"\n' +
                '},\n' +
                '{\n' +
                '\t"transcriptType": "RECA",\n' +
                '\t"transcriptForm": "1040",\n' +
                '\t"transcriptPeriod": "201812"\n' +
                '}]\n' +
                '}';
        //jsonBody = jsonBody.replace('HQNZD5CQX8YOV96', input.companyId);
        //jsonBody = jsonBody.replace('222222222', input.ssn);
        jsonBody = jsonBody.replace('HQNZD5CQX8YOV96', 'HQNZD5CQX8YOV96');
        jsonBody = jsonBody.replace('222222222', '222222222');
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
        request.setEndpoint('https://dnh8ze7vli.execute-api.us-east-1.amazonaws.com/uat/api/taxdata/v1/transcript');
        request.setBody(jsonBody);
        http = new Http();
        response = http.send(request);
        System.debug(response.getBody());
        List<TaxTranscripts> dataObject = (List<TaxTranscripts>) System.JSON.deserialize(response.getBody(), List<TaxTranscripts>.class);
        for(TaxTranscripts t : dataObject) {
            ContentVersion cv = createContentVersion(t.Transcript, t.Form + '_' +  t.period + '-transcript.pdf');
            String cdId = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;
            ContentDocumentLink cdl = createContentLink(cdId, recordId);
            FileExplorerFile__c file = new FileExplorerFile__c();
            file.Label__c = t.Form + '_' + t.period  + '-transcript.pdf';
            ContentDocument cd = [SELECT Id, ContentSize FROM ContentDocument WHERE Id = :cdId];
            file.ContentSize__c = cd.ContentSize;
            file.ContentDocumentId__c = cdId;
            insert file;
        }
    }
    global class FlowInput {
        @InvocableVariable(Required = true)
        global String recordId;
    }

    private static ContentVersion createContentVersion(String base64, String filename) {
        List<ContentVersion> contentVersions = new List<ContentVersion>();
        ContentVersion cv = new ContentVersion();

        cv.VersionData = EncodingUtil.base64Decode(base64);
        cv.Title = filename;
        cv.PathOnClient = filename;
        contentVersions.add(cv);

        insert contentVersions;
        return cv;

    }

    private static ContentDocumentLink createContentLink(String cdlId, String recordId) {
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = cdlId;
        cdl.LinkedEntityId = recordId;
        // ShareType is either 'V', 'C', or 'I'
        // V = Viewer, C = Collaborator, I = Inferred
        cdl.ShareType = 'I';
        cdl.Visibility = 'AllUsers';
        insert cdl;
        return cdl;
    }
}