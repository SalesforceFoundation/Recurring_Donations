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
* @description Class provides a batchable wrapper for open ended recurring donations
*/
global without sharing class RecurringDonations_BATCH implements Database.Batchable<sObject>, Database.Stateful{
    public String query { get; set; } 
    public integer recCount;
    // constructors
    public RecurringDonations_BATCH(string q) {
    	RecurringDonations_ProcessControl.batchButton = true;
    	query = q;
        recCount = 0;
    }
    
    global database.Querylocator start(Database.BatchableContext bc){
    	//clear any existing errors from the queue
    	delete [select id from Recurring_Donations_Error_Queue__c];
        return Database.getQueryLocator(query);      
    }
    global void execute(Database.BatchableContext bc, Sobject[] result){
        RecurringDonations_ProcessControl.batchButton = true;
        recCount += result.size();
        RecurringDonations.evaluateRecurringDonationsForNewOppInsert(result);    
    }
    global void finish(Database.BatchableContext bc) {
        //update our settings
        Recurring_Donations_Settings__c rds = RecurringDonations.getRecurringDonationsSettings();
        
        AsyncApexJob a = [select Id, Status, NumberOfErrors, JobItemsProcessed,
                            TotalJobItems, CompletedDate
                            from AsyncApexJob 
                            where Id = :BC.getJobId()];
        integer errorcount = 0;
        errorcount = [select count() from Recurring_Donations_Error_Queue__c];                             
                            
        rds.Last_Batch_Run__c = a.CompletedDate;
        rds.Number_Of_Successes__c = recCount - errorcount;
        rds.Number_Of_Failures__c = errorcount;
        update rds;                            
        
        //if needed, send messages from teh error queue
        RecurringDonations_ErrorHandling.sendErrorQueueEmailNotification();        
    }
    
    
    @isTest (SeeAllData = true)
    public static void testBatch() {
    	
    	RecurringDonations_TEST.setRecurringDonationsSettingsForTest(
        new Recurring_Donations_Settings__c(
        Opportunity_Forecast_Months__c = 12,
        Maximum_Donations__c = 50,
        Open_Opportunity_Behavior__c = RecurringDonations.RecurringDonationCloseOptions.Mark_Opportunities_Closed_Lost.name()
        ));           
                    
        Account a = new Account();
        a.Name = 'test Individual';
        insert a;
        
        Contact c = new Contact();
        c.FirstName = 'test';
        c.LastName = 'contact';
        c.AccountId = a.Id;
        insert c;       

        Recurring_Donation__c r1 = new Recurring_Donation__c();
        r1.Name = 'test';
        r1.Installments__c = 2;
        r1.Organization__c = a.id;
        r1.Amount__c = 100;
        r1.Installment_Period__c = System.Label.RecurringDonationInstallmentPeriodWeekly;
        r1.Date_Established__c = date.newinstance(1970,6,12);
        r1.Schedule_Type__c = System.Label.RecurringDonationMultiplyValue;
        r1.Open_Ended_Status__c = System.label.RecurringDonationOpenStatus;
        r1.Next_Payment_Date__c = system.today();
        insert r1;
        
        map<id, Opportunity> originalOpps = new map<id, Opportunity>([select id, Name,amount,accountid,CloseDate from Opportunity where Recurring_Donation__c = :r1.id]);
        
        Opportunity o = originalOpps.values()[0];
        string closedstage = [select masterlabel from opportunitystage where isActive = true and iswon = true and isClosed = true limit 1].masterlabel;
        o.StageName = closedstage;
        o.CloseDate = system.today();
        update o;
        
        
        //kick it off from the vf page
        
        
        Test.setCurrentPageReference(new PageReference('Page.RecurringDonationsSettings'));
        
        //pass the controller into the extension
        RecurringDonationsSettings controller = new RecurringDonationsSettings(); 
        controller.getSettingsFirstTime();
        test.startTest();
        controller.runBatch();
        test.stopTest();  
    }
}