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
    
    
    public static void handleDMLErrorsOnOppInsert(list<Database.SaveResult> lsr, list<Opportunity> badOpps, boolean isUIOperation){
        if (!isUIOperation){
        	list<Recurring_Donations_Error_Queue__c> rdeqList = new list<Recurring_Donations_Error_Queue__c>();
            //we only want one error per id, so we filter with this set
            set<id> RDIDs = new set<id>();
            integer i = 0;            
            for (Opportunity o : badOpps){
                
                if (!RDIDs.contains(o.Recurring_Donation__c)){
                    Database.SaveResult thisSR = lsr[0];
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
            	sendErrorQueueEmailNotification();
            }
        }            
        //add the error to the parent Recurring Donation for this opp
        else{
            Recurring_Donation__c rd = [select id from Recurring_Donation__c where id = :badOpps[0].Recurring_Donation__c];
            rd.addError(lsr[0].getErrors()[0].getMessage());
        }           
    }
    
    @future
    public static void sendErrorQueueEmailNotification(){
    	map<string, Recurring_Donations_Error_Queue__c> rdeqMap = Recurring_Donations_Error_Queue__c.getAll();
    	if (!rdeqMap.isEmpty()){
    		
    		
    	}
    	
    	
    } 

    private void constructEmailMessage(){
    	
    }
}