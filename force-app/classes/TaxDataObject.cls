/**
 * Created by zachary_edgell on 12/1/21.
 */

global class TaxDataObject{
    @InvocableVariable
    @AuraEnabled global String SSN; //XXX-XX-2222
    @InvocableVariable
    @AuraEnabled global TaxDataInfo[] Data;
}