/*
    Copyright (c) 2009, Salesforce.com Foundation
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
trigger RecurringDonations on Recurring_Donation__c (before insert, before update, before delete, 
after insert, after update, after delete, after undelete) {
    
    /// <name> triggerAction </name>
    /// <summary> contains possible actions for a trigger </summary>
    Recurring_Donations_Settings__c rds = RecurringDonations.getRecurringDonationsSettings();
    public enum triggerAction {beforeInsert, beforeUpdate, beforeDelete, afterInsert, afterUpdate, afterDelete, afterUndelete}
    
    if (!rds.DISABLE_RecurringDonations_trigger__c && RecurringDonations_ProcessControl.hasRun != true){ 
    
        if(Trigger.isBefore && Trigger.isInsert){
            RecurringDonations process = new RecurringDonations (trigger.new, trigger.old, triggerAction.beforeInsert);
        }        
        if(Trigger.isBefore && Trigger.isDelete ){
            RecurringDonations process = new RecurringDonations (trigger.oldMap, trigger.oldMap, triggerAction.beforeDelete);
        }
        if(Trigger.isInsert && Trigger.isAfter){
            //James Melville 05/03/2011 Dynamically build Recurring donation query to allow currency to be included if needed.
            //build start of dynamic query
            
            set<string> existingFields = new set<string>{  'open_ended_status__c', 'next_payment_date__c', 'name',
            	                                           'organization__c', 'contact__c', 'installment_amount__c',
            	                                           'installments__c', 'amount__c', 'total__c', 'installment_period__c',
            	                                           'date_established__c', 'donor_name__c', 'schedule_type__c', 
            	                                           'recurring_donation_campaign__c', 'total_paid_installments__c'};
            
            String queryRCD = 'select id';
            for (string s : existingFields){
            	queryRCD += ', ' + s;             	
            }
       
            //add any custom mapping to make sure we have the required fields
            map<string, Custom_Field_Mapping__c> cfmMap = new map<string, Custom_Field_Mapping__c>();
            cfmMap = Custom_Field_Mapping__c.getAll();
            for (string s : cfmMap.keySet()){
            	string RDFieldName = cfmMap.get(s).Recurring_Donation_Field__c;            	
                if (!existingFields.contains(RDFieldName.toLowerCase()) && s != 'id'){
            	   queryRCD = queryRCD + ',' + cfmMap.get(s).Recurring_Donation_Field__c;
            	   existingFields.add(RDFieldName.toLowerCase());   
                }
            }       
       
            //if currencyiso field exists add it to query for use later
            if(Schema.sObjectType.Recurring_Donation__c.fields.getMap().get('CurrencyIsoCode') != null)
                queryRCD = queryRCD + ',CurrencyIsoCode';
       
            //continue building query - dynamic apex does not allow nested binds (:Trigger.new) so we build a list
            List<Id> ids = new List<Id>();
        
            for(Recurring_Donation__c r : Trigger.new){
                ids.add(r.Id);
            }
        
            //Trigger.new.Id;
            queryRCD=queryRCD+' from Recurring_Donation__c where Id in :ids';
            //execute query
            Recurring_Donation__c[] updatedRecurringDonations = Database.query(queryRCD);
            map<id, Recurring_Donation__c> updatedRDs = new map<id, Recurring_Donation__c>();
            for (Recurring_Donation__c rd : updatedRecurringDonations){
                updatedRDs.put(rd.id, rd);            
            }
            RecurringDonations process = new RecurringDonations (updatedRDs, trigger.oldMap, triggerAction.afterInsert);
        }
    
        if(Trigger.isUpdate && Trigger.isAfter){
            RecurringDonations process = new RecurringDonations (trigger.newMap, trigger.oldMap, triggerAction.afterUpdate);
        }
    }    
}