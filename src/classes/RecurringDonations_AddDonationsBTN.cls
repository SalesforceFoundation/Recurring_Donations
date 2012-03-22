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
* @date 2012 (2.2)
* @description The controller for the VF page invoked by using the check for new opps button
*/
public with sharing class RecurringDonations_AddDonationsBTN {

    public string returnURL{get; set;}
    public Recurring_Donation__c RecurringDonation{get; set;}    
    
    public RecurringDonations_AddDonationsBTN(ApexPages.StandardController controller){
        //set the return URL
        RecurringDonation = (Recurring_Donation__c)Controller.getRecord();
        PageReference pageRef = new PageReference('/' + RecurringDonation.id);
        returnurl = pageref.getUrl();
        
    }
    
    public PageReference buttonClick(){
    	   system.assert(RecurringDonation != null);
        
           set<string> existingFields = new set<string>{  'open_ended_status__c', 'next_payment_date__c', 'name',
                                                           'organization__c', 'contact__c', 'installment_amount__c',
                                                           'installments__c', 'amount__c', 'total__c', 'installment_period__c',
                                                           'date_established__c', 'donor_name__c', 'schedule_type__c', 
                                                           'recurring_donation_campaign__c', 'total_paid_installments__c'};
            
            String qString = 'select id';
            for (string s : existingFields){
                qString += ', ' + s;               
            }
       
            //add any custom mapping to make sure we have the required fields
            map<string, Custom_Field_Mapping__c> cfmMap = new map<string, Custom_Field_Mapping__c>();
            cfmMap = Custom_Field_Mapping__c.getAll();
            for (string s : cfmMap.keySet()){
                string RDFieldName = cfmMap.get(s).Recurring_Donation_Field__c;             
                if (!existingFields.contains(RDFieldName.toLowerCase()) && s != 'id'){
                   qString = qString + ',' + cfmMap.get(s).Recurring_Donation_Field__c;
                   existingFields.add(RDFieldName.toLowerCase());   
                }
            }       
                                           
                            
        qString += ' from Recurring_Donation__c ';
        qString += ' where id = \'' + RecurringDonation.id + '\'';
        RecurringDonation = (Recurring_Donation__c)database.query(qString);
        RecurringDonations.evaluateRecurringDonationsForNewOppInsert(new list<Recurring_Donation__c>{RecurringDonation});
        
        PageReference pageRef = new PageReference(returnurl);
        pageRef.setRedirect(true);
        return pageRef;
    }
    
    public static testMethod void testBTN(){
        Account a = new Account(Name = 'TestA');
        insert a;
        Recurring_Donation__c r1 = new Recurring_Donation__c();
        r1.Name = 'test';
        r1.Installments__c = 2;
        r1.Organization__c = a.Id;
        r1.Amount__c = 100;
        r1.Installment_Period__c = System.Label.RecurringDonationInstallmentPeriodWeekly;
        r1.Date_Established__c = date.newinstance(1970,6,12);
        r1.Schedule_Type__c = System.Label.RecurringDonationMultiplyValue;
        r1.Open_Ended_Status__c = System.label.RecurringDonationOpenStatus;
        r1.Next_Payment_Date__c = system.today();
        insert r1;
        
        delete[select id from Custom_Field_Mapping__c];
        insert new Custom_Field_Mapping__c(
        Name = 'CFM-' + system.now(),
        Opportunity_Field__c = 'closedate',
        Recurring_Donation_Field__c = 'last_payment_date__c'
        );
        
        ApexPages.StandardController scc = new ApexPages.StandardController(r1);
        RecurringDonations_AddDonationsBTN rdadb = new RecurringDonations_AddDonationsBTN(scc);
        system.assertEquals(r1.id, rdadb.RecurringDonation.id);
        rdadb.buttonClick();	
    }
}