global class GetTranscriptDetails {
    
    private static final Map<String, String> mapQuarter = new Map<String, String>{'Quarter 1' => '03', 'Quarter 2' => '06', 'Quarter 3' => '09','Quarter 4' => '12'};
        @InvocableMethod
        global static void execute(List<FlowInput> inputs) {
            //FlowOutput output = new FlowOutput();
            FlowInput input = inputs.get(0);
            String recordId = input.recordId;
            insertData(recordId);
        }
    @future(callout=true)
    public static void insertData(String recordId) {
        
        //Getting API Information from Tax Status Detail Metadata =    
        accrue__Tax_Status_API_Detail__mdt token = accrue__Tax_Status_API_Detail__mdt.getInstance('Token');
        accrue__Tax_Status_API_Detail__mdt transcriptdetail = accrue__Tax_Status_API_Detail__mdt.getInstance('Transcriptdetail');
        
        try{
            HttpRequest request = new HttpRequest();
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
            String access_token = jsonParser.get('access_token').getStringValue();
            request = new HttpRequest();
            request.setMethod('POST');
            request.setHeader('euid', token.accrue__Company_Id__c);
            request.setHeader('Authorization', 'Bearer ' + access_token);
            system.debug('recordId '+recordId);
            accrue__Tax_Data__c taxData = [SELECT Id, accrue__Form_Type__c, accrue__Form__c, accrue__TIN__c, accrue__Tax_Quarter__c, accrue__Tax_Year__c FROM accrue__Tax_Data__c WHERE Id =:recordId LIMIT 1];
            
            request.setEndpoint(transcriptdetail.accrue__Endpoint__c);
            JSONGenerator gen = JSON.createGenerator(true);
            gen.writeStartObject();
            system.debug('token.accrue__Company_Id__c '+token.accrue__Company_Id__c+'==>'+taxData.accrue__TIN__c+'==>'+taxData.accrue__Form_Type__c+'==>'+taxData.accrue__Form__c+'==>'+taxData.accrue__Tax_Year__c+mapQuarter.get(taxData.accrue__Tax_Quarter__c));
            gen.writeStringField('companyId', token.accrue__Company_Id__c);
            gen.writeStringField('tin', taxData.accrue__TIN__c);
            gen.writeStringField('transcriptType', taxData.accrue__Form_Type__c);
            gen.writeStringField('transcriptForm', taxData.accrue__Form__c);
            gen.writeStringField('transcriptPeriod', taxData.accrue__Tax_Year__c+mapQuarter.get(taxData.accrue__Tax_Quarter__c));
            gen.writeEndObject();
            request.setBody(gen.getAsString());
            System.debug(gen.getAsString());
            http = new Http();
            response = http.send(request);
            System.debug(response.getBody());
            String strBody = response.getBody();
            
            strBody = strBody.replace('"Desc":','"Desc1":');
            strBody = strBody.replace('"Date":','"Date1":');
            
            List<TaxDataObject>  transcriptMap = (List<TaxDataObject>)JSON.deserialize(strBody, List<TaxDataObject>.class);
            TaxDataObject objtranscript = transcriptMap[0];
            cls_Data dat = objtranscript.Data[0];
            
            List<accrue__Transcript_Detail__c> listtranscriptToUpdate = new List<accrue__Transcript_Detail__c>();
            accrue__Transcript_Detail__c tempTranscriptDetail = new accrue__Transcript_Detail__c();
            for(cls_Transactions trans: dat.Transactions){
                tempTranscriptDetail = new accrue__Transcript_Detail__c();
                tempTranscriptDetail.accrue__Amount__c = trans.Amount;
                tempTranscriptDetail.accrue__Code__c = trans.Code;
                tempTranscriptDetail.accrue__Date__c = trans.Date1;
                tempTranscriptDetail.accrue__Description__c = trans.Desc1;
                tempTranscriptDetail.accrue__Tax_Data__c = recordId;
                system.debug(tempTranscriptDetail);
                listtranscriptToUpdate.add(tempTranscriptDetail);
            }
                insert(listtranscriptToUpdate);
                /*output.response = 'Transcript data fetched successfully!';
                return new List<FlowOutput> {
                output
                };*/
            
        } catch(exception ex){
            system.debug(ex.getMessage()+ex.getLineNumber());
            /*output.response = 'Error while fetching tax data, try again later.';
            return new List<FlowOutput> {
            output
            };*/
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
    global class TaxDataObject{
        @InvocableVariable
        @AuraEnabled global cls_Data[] Data;
    }
    global class cls_Data {
        public cls_Transactions[] Transactions;
    }
    class cls_Transactions {
        public String Code;	//150
        public String Desc1;	//Tax return filed
        public String Date1;	//05-11-2020
        public String Amount;	//$3,619.00
    }
}