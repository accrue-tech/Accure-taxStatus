@isTest
public class TaxAPIGetTranscriptsTest {
    @isTest 
    static void executeTest() {
        
		Id rtId = [SELECT Id,Name FROM RecordType WHERE SObjectType='Account' AND Name ='Person Account' LIMIT 1].Id;
        Account relationship = new Account(RecordTypeId=rtId);
        relationship.FirstName = 'Test SMITH';
        relationship.LastName = 'SMITH';
        relationship.accrue__TIN__pc ='222222222';
        insert relationship;
        
        TaxAPIGetTranscripts.FlowInput input = new TaxAPIGetTranscripts.FlowInput();
        List<TaxAPIGetTranscripts.FlowInput> inputs = new List<TaxAPIGetTranscripts.FlowInput>();
        input.recordId = relationship.Id;
        inputs.add(input);
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new TaxAPIGetTranscriptsMock()); 
        Map<String, String> mapQuarter = new Map<String, String>{'03' => 'Quarter 1', '06' => 'Quarter 2', '09' => 'Quarter 3','12' => 'Quarter 4'};
        TaxAPIGetTranscripts.execute(relationship.Id,mapQuarter);
        Test.stopTest();
    }
}