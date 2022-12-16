global class  GetTranscripts {
    private static final Map<String, String> mapQuarter = new Map<String, String>{'Quarter 1' => '03', 'Quarter 2' => '06', 'Quarter 3' => '09','Quarter 4' => '12'};
        @InvocableMethod
        public static void execute(List<FlowInput> inputs) {
            FlowInput input = inputs.get(0);
            String recordId = input.recordId;
            makeCallout(recordId);
            
        }
    //@future(callout=true)
    public static void makeCallout(String recordId) {
        //Getting API Information from Tax Status Detail Metadata =    
        accrue__Tax_Status_API_Detail__mdt token = accrue__Tax_Status_API_Detail__mdt.getInstance('Token');
        accrue__Tax_Status_API_Detail__mdt transcript = accrue__Tax_Status_API_Detail__mdt.getInstance('Transcript');
		
        //Creating Transcript details for which pdf is to be created
        List<accrue__Tax_Data__c> taxData = [SELECT Id, accrue__Form_Type__c, accrue__Form__c, accrue__TIN__c, accrue__Tax_Quarter__c, accrue__Tax_Year__c,accrue__Transcript_Path__c FROM accrue__Tax_Data__c WHERE accrue__Relationship__c  =:recordId];    
         system.debug(taxData); 
        Map<String,accrue__Tax_Data__c> taxDataMap = new Map<String,accrue__Tax_Data__c>();
        Set<Id> distributionId = new Set<Id>();
        	String companyId = token.accrue__Company_Id__c;
            String tin  = taxData[0].accrue__TIN__c;  
            Boolean needPDF  = true;
            List<Transcript> listTranscript = new List<Transcript>();  
            for(accrue__Tax_Data__c objTaxData : taxData){
                Transcript tempTranscript = new Transcript(objTaxData.accrue__Form_Type__c,objTaxData.accrue__Form__c,objTaxData.accrue__Tax_Year__c+mapQuarter.get(objTaxData.accrue__Tax_Quarter__c));   
                system.debug(tempTranscript);
                listTranscript.add(tempTranscript);
                
                //CReate Map to store Tax Data
                taxDataMap.put(objTaxData.accrue__Form_Type__c+objTaxData.accrue__Form__c+objTaxData.accrue__Tax_Year__c+mapQuarter.get(objTaxData.accrue__Tax_Quarter__c),objTaxData);
            }
        	system.debug('taxDataMap'+taxDataMap);
            TranscriptFile objTF = new TranscriptFile(companyId, tin, needPDF,listTranscript);
            System.debug( JSON.serialize(objTF));
            
            //Create request to get token
            HttpRequest request = new HttpRequest();
            String jsonBody = JSON.serialize(objTF);
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
            request.setEndpoint(transcript.accrue__Endpoint__c);
            request.setBody(jsonBody);
        	System.debug(jsonBody);
            http = new Http();
            response = http.send(request);
            System.debug(response.getBody());
            List<TaxTranscripts> dataObject = (List<TaxTranscripts>) System.JSON.deserialize(response.getBody(), List<TaxTranscripts>.class);
            for(TaxTranscripts t : dataObject) {
                if(t.Transcript!=''){
                    ContentVersion cv = createContentVersion(t.Transcript, t.FormType + '_' + t.Form + '_' +  t.period + '-transcript.pdf');
                    String cdId = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;
                    ContentDocumentLink cdl = createContentLink(cdId, recordId);
                    FileExplorerFile__c file = new FileExplorerFile__c();
                    file.Label__c = t.FormType + '_' + t.Form + '_' + t.period  + '-transcript.pdf';
                    ContentDocument cd = [SELECT Id, ContentSize FROM ContentDocument WHERE Id = :cdId];
                    file.ContentSize__c = cd.ContentSize;
                    file.ContentDocumentId__c = cdId;
                    
                    /* Creating ContentDistribution record */
                    ContentDistribution conDis = new ContentDistribution();
                    conDis.Name = t.FormType + t.Form + t.period;
                    conDis.ContentVersionId = cv.Id;
                    conDis.PreferencesAllowViewInBrowser= true;
                    insert conDis;
                    
                    //Getting tax data to update URL 
                    accrue__Tax_Data__c tempTaxData = taxDataMap.get(t.FormType + t.Form + t.period) ;
                    tempTaxData.accrue__Transcript_Path__c = conDis.DistributionPublicUrl;
                    system.debug('Test@@'+conDis.Id);
                    distributionId.add(conDis.Id);
                    
                    //update tempTaxData;
                    insert file;    
                }
                
            }
        system.debug(distributionId);
        system.debug([SELECT DistributionPublicUrl from ContentDistribution WHERE ID IN:distributionId]);
        for(ContentDistribution key: [SELECT DistributionPublicUrl,Name from ContentDistribution WHERE ID IN:distributionId]){
            accrue__Tax_Data__c tempTaxData = taxDataMap.get(Key.Name);
            tempTaxData.accrue__Transcript_Path__c = key.DistributionPublicUrl;
            update tempTaxData;
        }
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
        cdl.Visibility = 'InternalUsers';
        insert cdl;    
        return cdl;
    }
    
    
    global class FlowInput {
        @InvocableVariable(required=false)
        global String recordId;
    }
    
    class TranscriptFile {
        public String companyId;
        public String tin;
        public Boolean needPDF;
        public List<Transcript> transcripts ;
        public TranscriptFile(String companyId1, String tin1, Boolean needPDF1 , List<Transcript> listTranscript1){
            companyId=companyId1; 
            tin=tin1; 
            needPDF=needPDF1; 
            transcripts=listTranscript1;
        }
    }
    
    class Transcript {
        public String transcriptType;
        public String transcriptForm;
        public String transcriptPeriod;
        public Transcript(String transcriptType1, String transcriptForm1, String transcriptPeriod1) {
            transcriptType = transcriptType1;
            transcriptForm = transcriptForm1;
            transcriptPeriod = transcriptPeriod1;
        }
    }
}