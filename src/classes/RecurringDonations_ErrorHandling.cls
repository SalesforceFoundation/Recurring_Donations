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
* @description Handles errors in the recurring donation processes  
*/
public without sharing class RecurringDonations_ErrorHandling {
    
    public static Recurring_Donations_Settings__c rds;
    
    public static void handleDMLErrorsOnOppInsert(list<Database.SaveResult> lsr, list<Opportunity> badOpps){ 
        list<Recurring_Donations_Error_Queue__c> rdeqList = new list<Recurring_Donations_Error_Queue__c>();
        //we only want one error per id, so we filter with this set
        set<id> RDIDs = new set<id>(); 
        integer i = 0;            
        for (Opportunity o : badOpps){
                  
            if (!RDIDs.contains(o.Recurring_Donation__c)){
                Database.SaveResult thisSR = lsr[i];
                //insert into our custom list setting?                  
                Recurring_Donations_Error_Queue__c rdeq = new Recurring_Donations_Error_Queue__c();
                rdeq.Name = 'E-' + o.Recurring_Donation__c + '-' + i;
                rdeq.Recurring_Donation_ID__c = o.Recurring_Donation__c;
                rdeq.Error_Message__c = thisSR.getErrors()[0].getMessage();
                rdeqList.add(rdeq);
                RDIDs.add(o.Recurring_Donation__c);
            }            
            i++;
        }
         
        if (!rdeqList.isEmpty()){
            insert rdeqList;
            //if we're in a batch job, let the batch handle the send notification so it happens
            //at one time
            if (!system.isBatch() && !RecurringDonations_ProcessControl.batchButton && !system.isFuture())  
                sendErrorQueueEmailNotificationFuture();
            else if (system.isFuture()){
            	sendErrorQueueEmailNotification();
            }                 
        }                  
    }
    
    @future
    public static void sendErrorQueueEmailNotificationFuture(){sendErrorQueueEmailNotification();}
    public static void sendErrorQueueEmailNotification(){
    	map<string, Recurring_Donations_Error_Queue__c> rdeqMap = Recurring_Donations_Error_Queue__c.getAll();
    	rds = RecurringDonations.getRecurringDonationsSettings();
    	if (!rdeqMap.isEmpty() && rds.Error_Email_Notifications__c != 'None' && rds.Error_Email_Notifications__c != null){
    		Messaging.SingleEmailMessage sme = createEmailMessage(rdeqMap.values());
            if (!test.isRunningTest())
                Messaging.sendEmail(new Messaging.SingleEmailMessage[]{sme});
    	}
    	//clear the queue if not in a batch, otherwise, save them 
        if (!system.isBatch() && !RecurringDonations_ProcessControl.batchButton)      	   
    	   delete [select id from Recurring_Donations_Error_Queue__c];
    } 

    private static Messaging.SingleEmailMessage createEmailMessage(list<Recurring_Donations_Error_Queue__c> rdeqList){
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setUseSignature(false);
        mail.setSenderDisplayName('Salesforce Recurring Donations');
        mail.setSubject('Salesforce Recurring Donations Errors');
        string bodyString = '';
        bodyString += system.label.RecurringDonationErrorEmailBody;
        bodyString += '\n\nErrors:';
        for (Recurring_Donations_Error_Queue__c rdeq : rdeqlist){
        	bodyString += '\n' + system.url.getSalesforceBaseUrl().toExternalForm() + '/' + rdeq.Recurring_Donation_ID__c;
        	bodystring += ' Error Message: ' + rdeq.Error_Message__c;        	
        }        
        mail.setPlainTextBody(bodyString);
        list<string> sendList = new list<string>();
        //user, sysadmins or PG
        string mailList = rds.Error_Email_Notifications__c;
        
        if (mailList.startsWith('005')){
        	sendList.add([select email from User where id = :mailList].email);
        }
        else if(mailList == 'All Sys Admins'){
        	list<User> sysadminlist = [select email from User where User.Profile.Name = 'System Administrator'];
        	for (User u : sysadminlist){
                sendList.add(u.email);        		
        	}        	
        }
        else if(mailList.startsWith('00G')){
        	list<GroupMember> groupUsers = [select g.UserOrGroupId from GroupMember g where GroupId = :mailList];
        	set<id> userIDs = new set<id>();
        	for (GroupMember g : groupUsers)
        	   userIDs.add(g.UserOrGroupId);
        	list<User> userList = [select email from User where id IN :userIDs];
        	for (User u : userList){
        		sendList.add(u.email);
        	}
        }        
        mail.setToAddresses(sendList);                   

        return mail;    	
    }
    
    /*** Test Methods ***/
    
    static testMethod void testErrorHandlingAllSysAdmins(){
        RecurringDonations_TEST.setRecurringDonationsSettingsForTest(new Recurring_Donations_Settings__c( 
        Error_Email_Notifications__c ='All Sys Admins'                
        ));         
        
        Account a = new Account(Name = 'Test');
        insert a;
        Recurring_Donation__c r1 = new Recurring_Donation__c();
        r1.Name = 'test';
        r1.Organization__c = a.id;
        r1.Amount__c = 100;
        r1.Installment_Period__c = System.Label.RecurringDonationInstallmentPeriodWeekly;
        r1.Open_Ended_Status__c = System.label.RecurringDonationOpenStatus;
        r1.Next_Payment_Date__c = system.today();
        insert r1;    
        
        //create some opps
        list<Opportunity> olist = new list<Opportunity>();
        integer i;
        for (i = 0; i<=10; i++){
            Opportunity o = new Opportunity(
                StageName = 'Closed Won',
                Name = 'Opp ' + i,
                CloseDate = system.today(),
                Amount = 1.00,
                Recurring_Donation__c = r1.id                
            );
            olist.add(o);                    	
        }
        //invalidate one opp    	
        olist[0].Name = null;
        Database.saveresult[] lsr = Database.insert(olist, false);
        list<Opportunity> badOpps = new list<Opportunity>{olist[0]};
        //run it using bulk setup
        RecurringDonations_ErrorHandling.handleDMLErrorsOnOppInsert(lsr, badOpps);
    }
    
    static testMethod void testErrorHandlingUser(){
     	User u = [select id from User limit 1];
        RecurringDonations_TEST.setRecurringDonationsSettingsForTest(new Recurring_Donations_Settings__c( 
        Error_Email_Notifications__c = u.id                
        ));  
        
        Account a = new Account(Name = 'Test');
        insert a;
        Recurring_Donation__c r1 = new Recurring_Donation__c();
        r1.Name = 'test';
        r1.Organization__c = a.id;
        r1.Amount__c = 100;
        r1.Installment_Period__c = System.Label.RecurringDonationInstallmentPeriodWeekly;
        r1.Open_Ended_Status__c = System.label.RecurringDonationOpenStatus;
        r1.Next_Payment_Date__c = system.today();
        insert r1;      
        
         //create some opps
        list<Opportunity> olist = new list<Opportunity>();
        integer i;
        for (i = 0; i<=10; i++){
            Opportunity o = new Opportunity(
                StageName = 'Closed Won',
                Name = 'Opp ' + i,
                CloseDate = system.today(),
                Amount = 1.00,
                Recurring_Donation__c = r1.id                
            );
            olist.add(o);                       
        }
        //invalidate one opp        
        olist[0].Name = null;
        Database.saveresult[] lsr = Database.insert(olist, false);
        list<Opportunity> badOpps = new list<Opportunity>{olist[0]};
        
        RecurringDonations_ErrorHandling.handleDMLErrorsOnOppInsert(lsr, badOpps);
    }
    
    static testMethod void testErrorHandlingPublicGroup(){
        Group g = new Group(Name = 'MyGroup');
        insert g;
        system.debug('GID IS: ' + g.id);
        RecurringDonations_TEST.setRecurringDonationsSettingsForTest(new Recurring_Donations_Settings__c( 
        Error_Email_Notifications__c = g.id                
        ));         
        
        Account a = new Account(Name = 'Test');
        insert a;
        Recurring_Donation__c r1 = new Recurring_Donation__c();
        r1.Name = 'test';
        r1.Organization__c = a.id;
        r1.Amount__c = 100;
        r1.Installment_Period__c = System.Label.RecurringDonationInstallmentPeriodWeekly;
        r1.Open_Ended_Status__c = System.label.RecurringDonationOpenStatus;
        r1.Next_Payment_Date__c = system.today();
        insert r1;                   
        
        //create some opps
        list<Opportunity> olist = new list<Opportunity>();
        integer i;
        for (i = 0; i<=10; i++){
            Opportunity o = new Opportunity(
                StageName = 'Closed Won',
                Name = 'Opp ' + i,
                CloseDate = system.today(),
                Amount = 1.00,
                Recurring_Donation__c = r1.id                
            );
            olist.add(o);                       
        }
        //invalidate one opp        
        olist[0].Name = null;
        Database.saveresult[] lsr = Database.insert(olist, false);
        list<Opportunity> badOpps = new list<Opportunity>{olist[0]};
        
        RecurringDonations_ErrorHandling.handleDMLErrorsOnOppInsert(lsr, badOpps);
    }    
}