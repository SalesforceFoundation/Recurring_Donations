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
public with sharing class RecurringDonations_BATCH {
    public String query { get; set; }
    // constructors
    public RecurringDonations_BATCH() {query = q;}
    
    public database.Querylocator start(Database.BatchableContext bc){
    	//clear any existing errors from the queue
    	delete [select id from Recurring_Donations_Error_Queue__c];
        return Database.getQueryLocator(query);      
    }
    public void execute(Database.BatchableContext bc, Sobject[] result){
        RecurringDonations.evaluateRecurringDonationsForNewOppInsert(result);    
    }
    public void finish(Database.BatchableContext bc) {
        //update our settings
        Recurring_Donations_Settings__c rds = RecurringDonations.getRecurringDonationsSettings();
        AsyncApexJob a = [select Id, Status, NumberOfErrors, JobItemsProcessed,
                            TotalJobItems, CompletedDate
                            from AsyncApexJob 
                            where Id = :BC.getJobId()];
                            
        rds.Last_Batch_Run__c = a.CompletedDate;
        rds.Number_Of_Successes__c = a.JobItemsProcessed;
        rds.Number_Of_Failures__c = a.NumberOfErrors;
        update rds;                            
        
        //if needed, send messages from teh error queue
        RecurringDonations_ErrorHandling.sendErrorQueueEmailNotification();        
    }
}