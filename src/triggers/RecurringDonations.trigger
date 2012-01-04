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
    public enum triggerAction {beforeInsert, beforeUpdate, beforeDelete, afterInsert, afterUpdate, afterDelete, afterUndelete}
 
    if(Trigger.isBefore && Trigger.isInsert){
        RecurringDonations process = new RecurringDonations (Trigger.new, Trigger.old, triggerAction.beforeInsert);
    }
    if(Trigger.isBefore && Trigger.isUpdate){
        RecurringDonations process = new RecurringDonations (Trigger.new, Trigger.old, triggerAction.beforeUpdate);
    }
    if(Trigger.isBefore && Trigger.isDelete ){
        RecurringDonations process = new RecurringDonations (Trigger.old, null, triggerAction.beforeDelete);
    }
    if(Trigger.isInsert && Trigger.isAfter){
    
        //James Melville 05/03/2011 Dynamically build Recurring donation query to allow currency to be included if needed.
        //build start of dynamic query
        String queryRCD = 'select id,Organization__c,Contact__c,Installment_Amount__c,Installments__c,Amount__c,Total__c,Installment_Period__c,Date_Established__c,Donor_Name__c,Schedule_Type__c,Recurring_Donation_Campaign__c';
       
        //if currencyiso field exists add it to query for use later
        if(Schema.sObjectType.Recurring_Donation__c.fields.getMap().get('CurrencyIsoCode') != null)
            queryRCD = queryRCD + ',CurrencyIsoCode';
       
        //continue building query - dynamic apex does not allow nested binds (:Trigger.new) so we build a list
        List<Id> ids = new List<Id>();
        for(Recurring_Donation__c r : Trigger.new)
        {
            ids.add(r.Id);
        }
        //Trigger.new.Id;
        queryRCD=queryRCD+' from Recurring_Donation__c where Id in :ids';
        //execute query
        Recurring_Donation__c[] updatedRecurringDonations = Database.query(queryRCD);
        RecurringDonations process = new RecurringDonations (updatedRecurringDonations, Trigger.old, triggerAction.afterInsert);
    }
    
    if(Trigger.isUpdate && Trigger.isAfter){
        RecurringDonations process = new RecurringDonations (Trigger.new, Trigger.old, triggerAction.afterUpdate);
    }
}