/*
    Copyright (c) 2012, Salesforce.com Foundation
    All rights reserved.
    
    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:
    
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the Salesforce.com Foundation nor the names of
      its contributors may be used to endorse or promote products derived
      from this software without specific prior written permission.
 
    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
    "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT 
    LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS 
    FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE 
    COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, 
    INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, 
    BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; 
    LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER 
    CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT 
    LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN 
    ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
    POSSIBILITY OF SUCH DAMAGE.
*/
/**
* @author Salesforce.com Foundation
* @date 2012 (2.0)
* @description Supports the automatic scheduling of recurring donation updates  
*/
global class RecurringDonations_SCHED implements Schedulable {

    global void execute(SchedulableContext SC) { 
        string openLabel = system.label.RecurringDonationOpenStatus;
        string queryRCD = 'select id,Open_Ended_Status__c, Next_Payment_Date__c, Organization__c, ' + 
            'Contact__c,Installment_Amount__c,Installments__c,Amount__c,Total__c,Installment_Period__c, ' +
            'Date_Established__c,Donor_Name__c,Schedule_Type__c,Recurring_Donation_Campaign__c,Total_Paid_Installments__c ';
            //add any custom mapping to make sure we have the required fields
        map<string, Custom_Field_Mapping__c> cfmMap = new map<string, Custom_Field_Mapping__c>();
        cfmMap = Custom_Field_Mapping__c.getAll();
        for (string s : cfmMap.keySet()){
            queryRCD = queryRCD + ',' + cfmMap.get(s).Recurring_Donation_Field__c;
        }
            //if currencyiso field exists add it to query for use later
        if(Schema.sObjectType.Recurring_Donation__c.fields.getMap().get('CurrencyIsoCode') != null)
            queryRCD = queryRCD + ',CurrencyIsoCode';
        queryRCD=queryRCD+' from Recurring_Donation__c where Open_Ended_Status__c = \'' + openLabel + '\'';
        
        //call the batch job, processing 50 at a time 
        Id batchInstanceId = Database.executeBatch(new RecurringDonations_BATCH(queryRCD), 50);    
    }
    
    static testmethod void test(){ 
             
        Custom_Field_Mapping__c cfm = new Custom_Field_Mapping__c(
        Recurring_Donation_Field__c = 'Last_Payment_Date__c',
        Opportunity_Field__c = 'Description',
        Name = 'CFMName00001-Test'
        );
        insert cfm;
        
        Test.startTest(); 
        
        //Schedule the test job 
        String jobId = System.schedule('test rd Sched', 
        '0 0 0 3 9 ? 2022',new RecurringDonations_SCHED()); 

        CronTrigger ct =[SELECT id,CronExpression,TimesTriggered,NextFireTime 
        FROM CronTrigger WHERE id=:jobId]; 
        //Verify the expressions are the same 
        System.assertEquals('0 0 0 3 9 ? 2022',ct.CronExpression); 
        //Verify the job has not run 
        System.assertEquals(0,ct.TimesTriggered); 
        //Verify the next time the job will run 
        System.assertEquals('2022-09-03 00:00:00',String.valueOf(ct.NextFireTime)); 
        
        Test.stopTest();        
    }   
}