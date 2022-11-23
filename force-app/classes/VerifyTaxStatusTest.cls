@isTest
public class VerifyTaxStatusTest {
    @isTest 
    static void executeTest() {
        
		Id rtId = [SELECT Id,Name FROM RecordType WHERE SObjectType='Account' AND Name ='Person Account' LIMIT 1].Id;
        Account relationship = new Account(RecordTypeId=rtId);
        relationship.FirstName = 'Test SMITH';
        relationship.LastName = 'SMITH';
        relationship.accrue__TIN__pc ='222222222';
        insert relationship;
        
        VerifyTaxStatus.FlowInput input = new VerifyTaxStatus.FlowInput();
        List<VerifyTaxStatus.FlowInput> inputs = new List<VerifyTaxStatus.FlowInput>();
        input.recordId = relationship.Id;
        inputs.add(input);
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new VerifyTaxStatusMock()); 
        VerifyTaxStatus.execute(inputs);
        Test.stopTest();
    }
}