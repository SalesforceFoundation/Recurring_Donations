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
        map<string, Custom_Field_Mapping__c> cfm = Custom_Field_Mapping__c.getAll();
        //get the rest of hte fiedls
        string qString = 'select id, Paid_Amount__c, Next_Payment_Date__c, ' +  
                            'Contact__c, Organization__c, Amount__c, ' +  
                            'Date_Established__c, Recurring_Donation_Campaign__c, ' + 
                            'Installment_Period__c, Installments__c, ' + 
                            'Last_Payment_Date__c, Open_Ended_Status__c, ' + 
                            'Schedule_Type__c, Total_Paid_Installments__c, ' + 
                            'Donor_Name__c';                             
        for (string s : cfm.keySet()){
        	qString += ' ,' + cfm.get(s).Recurring_Donation_Field__c;        	
        }                                    
                            
        qString += ' from Recurring_Donation__c ';
        qString += ' where id = \'' + RecurringDonation.id + '\'';
        RecurringDonation = (Recurring_Donation__c)database.query(qString);
        RecurringDonations.evaluateRecurringDonationsForNewOppInsert(new list<Recurring_Donation__c>{RecurringDonation});
        
        PageReference pageRef = new PageReference(returnurl);
        pageRef.setRedirect(true);
        return pageRef;
    }
}