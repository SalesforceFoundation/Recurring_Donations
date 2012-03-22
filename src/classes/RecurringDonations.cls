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
* @description The main class for controlling the behavior of Recurring Donations, both open ended and standard 
*/
global with sharing class RecurringDonations {
    
    /*** Public Vars ***/
    
    public enum RecurringDonationCloseOptions {Delete_Open_Opportunities, Mark_Opportunities_Closed_Lost, No_Action}
    public enum triggerAction {beforeInsert, beforeUpdate, beforeDelete, afterInsert, afterUpdate, afterDelete, afterUndelete}
    public static Recurring_Donations_Settings__c recurringDonationsSettings;    
    public static map<id, Recurring_Donation__c> recurringDonationMap;
    public static map<string, Custom_Field_Mapping__c> customFieldMappingSettings = new map<string, Custom_Field_Mapping__c>();
    
    /*** Constructors ***/ 
           
    //handles Opportunity closures
    public RecurringDonations(map<id, Opportunity> newOppMap, map<id, Opportunity> oldOppMap, triggerAction ta){
    	RecurringDonations_ProcessControl.hasRun = true;
        set<id> rdIDs = new set<id>();        
        if (ta == triggerAction.afterUpdate){       
            for (Opportunity o : newOppMap.values()){
                //does it have a recurring donation reference?
                //has it moved into a closed state?
                if (o.Recurring_Donation__c != null && (o.isClosed && !oldOppMap.get(o.id).isClosed)){
                    rdIds.add(o.Recurring_Donation__c);
                }
            }                  
        }           
        
        //Get the open label for opps
        string openLabel = system.label.RecurringDonationOpenStatus;
        recurringDonationMap = new map<id, Recurring_Donation__c>([select id, Paid_Amount__c, Next_Payment_Date__c, 
                                                                                    Contact__c, Organization__c, Amount__c, 
                                                                                    Date_Established__c, Recurring_Donation_Campaign__c,
                                                                                     Installment_Period__c, Installments__c,
                                                                                     Last_Payment_Date__c, Open_Ended_Status__c,
                                                                                     Schedule_Type__c, Total_Paid_Installments__c,
                                                                                     Donor_Name__c
                                                                                  from Recurring_Donation__c 
                                                                                  where Open_Ended_Status__c = :openLabel
                                                                                  and id IN :RDids]);
        //recurring donations that need to be updated      
        if (!recurringDonationMap.keySet().isEmpty()){
        	if (recurringDonationMap.keySet().size() == 1 || system.isBatch() || RecurringDonations_ProcessControl.batchButton)
        	   updateRecurringDonationOnOppChange(rdIds);
                //evaluateExistingOpportunities(rdIds, false);
            else
                updateRecurringDonationOnOppChangeFuture(rdIds);                                        
        }        
    }
    
    //support for older model
    public RecurringDonations(list<Recurring_Donation__c> rd, list<Recurring_Donation__c> nulllist, triggerAction ta){
    	Recurring_Donations_Settings__c rds = getRecurringDonationsSettings();
        for (Recurring_Donation__c r : rd){
            if (ta==triggerAction.beforeInsert){
                if (r.Organization__c == null && r.Contact__c == null){
                    r.addError(System.Label.RecurringDonationMissingDataError);
                }
                if (r.Installments__c > rds.Maximum_Donations__c){
                    r.addError(System.Label.RecurringDonationTooManyInstallmentsError);
                }
            }
        }                	   
    }
    
    //handles Recurring Donation scenarios
    public RecurringDonations(map<id, Recurring_Donation__c> recurringDonations, map<id, Recurring_Donation__c> oldRecurringDonations, triggerAction ta){       	 
        RecurringDonations_ProcessControl.hasRun = true;
        list<Recurring_Donation__c> recDonationDeletes = new list<Recurring_Donation__c>();
        map<id, Recurring_Donation__c> rdInserts = new map<id, Recurring_Donation__c>(); 
        list<Recurring_Donation__c> recDonationUpdates = new list<Recurring_Donation__c>();
        Recurring_Donations_Settings__c rds = getRecurringDonationsSettings();
        //Get the open label for opps
        string openLabel = system.label.RecurringDonationOpenStatus;
        
        for(id rid : recurringDonations.keySet()){
        	Recurring_Donation__c r = recurringDonations.get(rid);            
            if (ta==triggerAction.afterInsert){
                rdInserts.put(rid, r);
            }            
            if (ta==triggerAction.beforeDelete){
                recDonationDeletes.add(r);
            }                        
            //added for 2.0
            if (ta==triggerAction.afterUpdate){
                recDonationUpdates.add(r);
            }
        }
        
        if (recDonationDeletes.size() > 0){
            deleteRecDonations(recDonationDeletes);
        }
        
        //added for 2.0
        if (recDonationUpdates.size() > 0){
            handleRecurringDonationUpdate(recDonationUpdates, oldRecurringDonations); 
        }
        if (!rdInserts.isEmpty()){
            if (rdInserts.keySet().size() == 1 || system.isBatch())            
                insertOppsOnRecurringDonationInsert(rdInserts.values());
            else
                insertOppsOnRecurringDonationInsertFuture(rdInserts.keySet());
        }        
    }
    
    /*** BEGIN STATIC METHODS ***/    
    
    @future
    public static void updateRecurringDonationOnOppChangeFuture(set<id> RDids){updateRecurringDonationOnOppChange(RDids);} 
    public static void updateRecurringDonationOnOppChange(set<id> RDids){
     
        //Multicurrency Support
        SObjectField OppCurrencyField = Schema.sObjectType.Opportunity.fields.getMap().get('CurrencyIsoCode');
        //Use NPSP OCR Support?
        Sobjectfield ConIDForRole = Schema.sObjectType.Opportunity.fields.getMap().get('npe01__Contact_Id_for_Role__c');
        
        //set of RDs to be updated         
        map<id, Recurring_Donation__c> updateMap = new map<id, Recurring_Donation__c>();
        
        //Get our settings
        Recurring_Donations_Settings__c rds = getRecurringDonationsSettings();     
         
        //Get the open label for opps
        string openLabel = system.label.RecurringDonationOpenStatus;
        
        //get all possible rd records that may need updating, exclude ones not in an open state  
        map<id, Recurring_Donation__c> rdMap = new map<id, Recurring_Donation__c>([select id, Paid_Amount__c, Next_Payment_Date__c, 
                                                                                    Contact__c, Organization__c, Amount__c, 
                                                                                    Date_Established__c, Recurring_Donation_Campaign__c,
                                                                                     Installment_Period__c, Installments__c,
                                                                                     Last_Payment_Date__c, Open_Ended_Status__c,
                                                                                     Schedule_Type__c, Total_Paid_Installments__c,
                                                                                     Donor_Name__c
                                                                                  from Recurring_Donation__c 
                                                                                  where Open_Ended_Status__c = :openLabel
                                                                                  and id IN :RDids]);
        
        //get the cumulative values to update the recurring donations
        list<sobject> sobjs = [select count(id) oppcount, MIN(CloseDate) MinDate, MAX(CloseDate) MaxDate, SUM(Amount) Total,
                                  isClosed, Recurring_Donation__r.id rdid, isWon
                                  from Opportunity where Recurring_Donation__r.Open_Ended_Status__c = :openLabel 
                                  and Recurring_Donation__r.id IN :rdMap.keySet()
                                  group by rollup(Recurring_Donation__r.id, isClosed, isWon)]; 
        
        //holds the rdid of all evaluated closed sets, allows us to figure out the various summary rows
        //this is a workaorund for the null boolean aggregate result bug
        set<id> isClosedEvaluatedSet = new set<id>();
        map<id, date> maxOpenPaymentMap = new map<id, date>();
        
        //we want this outside of the loop so the grand summary row (null id) always refers to the 
        //rdids before it
        Recurring_Donation__c rd;        
        //update the rc next payment date 
        //and add new donation objects needed 
        for (sobject obj : sobjs){
            id rdid = (id)obj.get('rdid'); 
            
            //the summary isclosed row will contain a null boolean
            //which is evaluated as false, so we'll need to mark 
            //this rdid as having had the nonsummary false isclosed value 
            //already used, so we don't accidentally use the summary row below
            boolean isClosed = (boolean)obj.get('isClosed');
            boolean isWon = (boolean)obj.get('isWon');            
            
            if (rdid != null){
            	//if we already have values for this RD, get it from our rdid map, otherwise just grab
                //the one we're already working on 
                if (!updateMap.containsKey(rdid)){
                    rd = rdMap.get(rdid);
                }
                else{
                    rd = updateMap.get(rdid);
                }
                //if this is the open set for this rd
                if (!isClosed && !isWon && !isClosedEvaluatedSet.contains(rdid)){
                    rd.Next_Payment_Date__c = (date)obj.get('MinDate');
                    maxOpenPaymentMap.put(rdid, (date)obj.get('MaxDate'));
                    isClosedEvaluatedSet.add(rdid);
                    updateMap.put(rdid, rd);                                       
                }
                //if this is the closed set     
                else if (isClosed && isWon){
                    rd.Last_Payment_Date__c = (date)obj.get('MaxDate');
                    rd.Paid_Amount__c = (decimal)obj.get('Total');     
                    rd.Total_Paid_Installments__c = (integer)obj.get('oppcount');
                    updateMap.put(rdid, rd);                        
                }                   
            }
            else{          
                rd.Installments__c = (integer)obj.get('oppcount'); 
                updateMap.put(rd.id, rd);            	
            }                            
        }
        
        if (!updateMap.isEmpty()){
        	update updateMap.values();
        }
    } 
    
    //future wrapper for rds with no opptys closed
    @future
    public static void insertOppsOnRecurringDonationInsertFuture(set<id> recids){
    	delete [select id from Opportunity where isClosed = false and Recurring_Donation__r.id IN :recids];
    	list<Recurring_Donation__c> reclist = [select id, Total__c, Total_Paid_Installments__c, Schedule_Type__c,
    	                                       Recurring_Donation_Campaign__c, Paid_Amount__c, Organization__c,
    	                                       Open_Ended_Status__c, Next_Payment_Date__c, Last_Payment_Date__c,
    	                                       Installments__c, Installment_Period__c, Installment_Amount__c,
    	                                       Donor_Name__c, Date_Established__c, Contact__c, Amount__c, Name    	                                       
    	                                       from Recurring_Donation__c];
    	
        insertOppsOnRecurringDonationInsert(reclist);
    }
    
    //Creates new Opportunities when a RecurringDonation is inserted
    public static void insertOppsOnRecurringDonationInsert(list<Recurring_Donation__c> recurringDonations){
        //Lists used for final Insert
        list<Opportunity> opportunityInserts = new list<Opportunity>();
        
        Recurring_Donations_Settings__c rds = getRecurringDonationsSettings();
        customFieldMappingSettings = Custom_Field_Mapping__c.getAll();
        
        // James Melville 05/03/2011 Added to support multi-currency sfdc.  */
        // CurrencyIsoCode doesn't exist in non-multi-currency orgs
        SObjectField OppCurrencyField = Schema.sObjectType.Opportunity.fields.getMap().get('CurrencyIsoCode');
        //grab the contact id for role to take advantage of NPSP C&O if it exists
        Sobjectfield ConIDForRole = Schema.sObjectType.Opportunity.fields.getMap().get('npe01__Contact_Id_for_Role__c');
        set<id> updateRecurringDonationSet = new set<id>();            
        
        //Create a list of ContactIds used in these RecurringDonations
        list<Id> contactIds = new list<Id>();
        map<Id,Id> recConMap = new map<Id,Id>();
        for(Recurring_Donation__c r : recurringDonations){
        	updateRecurringDonationSet.add(r.id);
            if (r.Contact__c != null){ 
                contactIds.add(r.Contact__c);
                recConMap.put(r.Id,r.Contact__c);
            }
        }

        //Create a Map of Contact Ids and Contact Records
        map<Id,Contact> contactMap;
        map<Id,Account> accountMap;
        if (contactIds.size() > 0){
            contactMap = new Map<Id,Contact>([Select Id, AccountId from Contact where Id in :contactIds and AccountId != null]);
        }
        
        //Loop through the Recurring Donations and create the appropriate number of Opportunities
        for(Recurring_Donation__c r : recurringDonations){
            //if we're not looking at an open-ended type donation, handle it the 'old' way        
            if (r.Open_Ended_Status__c != system.label.RecurringDonationOpenStatus && r.Open_Ended_Status__c != system.label.RecurringDonationClosedStatus){          
        
                Decimal installs = r.Installments__c;
                Integer installments = installs.intValue();
                
                for ( Integer j=0;j<installments;j++ )
                {
                    Opportunity opp = new Opportunity();
                
                    if ( r.Organization__c != null )
                    {
                       opp.AccountId = r.Organization__c;
                    }
                    else
                    if ( contactMap.containsKey(r.Contact__c) )
                    {
                        Contact c = contactMap.get(r.Contact__c);
                        opp.AccountId = c.AccountId;
                    } 

                    // James Melville 05/03/2011 Added to support multi-currency sfdc.  
                    // we check currency iscode before entering the loop since it's a system check
                    if(OppCurrencyField != null)
                    {
                        SObjectField RDCurrencyField = Schema.sObjectType.Recurring_Donation__c.fields.getMap().get('CurrencyIsoCode');
                        //this should never return null as we have already found multicurrency on the oppty.
                        if(RDCurrencyField != null)
                        {
                            //set the donation currency field to equal the recurring donation currency
                            opp.put(OppCurrencyField,r.get(RDCurrencyField));
                        }
                    }
                
                    //add the remainder to the last installment, otherwise use the amount
                    if (j + 1 == installments && installments * r.Installment_Amount__c != r.Total__c)
                    {
                        opp.Amount = r.Total__c - (j * r.Installment_Amount__c);
                    } else {
                        opp.Amount = r.Installment_Amount__c;
                    }
                
                    if (r.Installment_Period__c == System.Label.RecurringDonationInstallmentPeriodYearly)
                    {
                        opp.CloseDate = (r.Date_Established__c).addYears(j);
                    } else
                    if (r.Installment_Period__c == System.Label.RecurringDonationInstallmentPeriodQuarterly)
                    {
                       opp.CloseDate = (r.Date_Established__c).addMonths(3*j);
                    } else
                    if (r.Installment_Period__c == System.Label.RecurringDonationInstallmentPeriodMonthly)
                    {
                       opp.CloseDate = (r.Date_Established__c).addMonths(j);
                    } else
                    if (r.Installment_Period__c == System.Label.RecurringDonationInstallmentPeriodWeekly)
                    {
                       opp.CloseDate = (r.Date_Established__c).addDays(7*j);
                    } else
                    {
                       opp.CloseDate = (r.Date_Established__c);
                    }
                
                    String oName = '';
                    oName += r.Donor_Name__c; 
                    oName += ' ';
                    oName += System.Label.RecurringDonationPrefix;
                    oName += ' (';
                    oName += j+1;
                    oName += ' of ';
                    oName += installments;
                    oName += ') ';
                    oName += opp.CloseDate.format();
                    opp.Name = oName;
                
                    opp.StageName = System.Label.RecurringDonationStageName;
                    opp.Recurring_Donation__c = r.Id;
                    if (r.Recurring_Donation_Campaign__c != null && (rds.Add_Campaign_to_All_Opportunites__c || j < 1)){
                       opp.CampaignId = r.Recurring_Donation_Campaign__c;
                    }                                        
                    if (rds.Record_Type__c != null){
                    	opp.RecordTypeID = rds.Record_Type__c;
                    }                    
                    
                    //evaluate any custom field mappings
                    for (string s : customFieldMappingSettings.keySet()){
                        Custom_Field_Mapping__c cfm = customFieldMappingSettings.get(s);
                        opp.put(cfm.Opportunity_Field__c, r.get(cfm.Recurring_Donation_Field__c));
                    }
                    
                    opportunityInserts.add(opp);
                    if ( opportunityInserts.size() == 100 )
                    {
                       Database.SaveResult[] lsr = Database.insert(opportunityInserts, false);
                       opportunityInserts.clear();
                    }
                }
            }
            
            //this is an open-ended rd that needs opptys
            else{
                //if its not 'open', we're not doing anything to it
                if (r.Open_Ended_Status__c == system.label.RecurringDonationOpenStatus){
                    //get settings so we can figure out how many donations to create                    
                    date OppCloseDate;
                    date loop_date;
                  
                    SObjectField RDCurrencyField; 
                    if(OppCurrencyField != null){
                        RDCurrencyField = Schema.sObjectType.Recurring_Donation__c.fields.getMap().get('CurrencyIsoCode');
                    }
                    
                    if (r.Next_Payment_Date__c != null)                     
                        OppCloseDate = r.Next_Payment_Date__c;
                    else{
                        OppCloseDate = r.Date_Established__c;                                                                        
                    }                                             
                    /*
                    if (r.Total_Paid_Installments__c > 0){
                            OppCloseDate = getNextDate(OppCloseDate, r.Installment_Period__c);
                    } */   
                    date incrementdate = OppCloseDate;
                    integer rdcounter = 1;
                    if (r.Total_Paid_Installments__c > 0)
                        rdcounter = (integer)r.Total_Paid_Installments__c + 1;
                            
                    do{
                        Opportunity o = new Opportunity();
                        o.CloseDate = OppCloseDate;
                                                                                                          
                        if(RDCurrencyField != null){
                            //set the donation currency field to equal the recurring donation currency
                            o.put(OppCurrencyField,r.get(RDCurrencyField));
                        }
                    
                        if (r.Organization__c != null){
                            o.AccountId = r.Organization__c;
                        }
                        else if (contactMap.containsKey(r.Contact__c)){
                            Contact c = contactMap.get(r.Contact__c);
                            o.AccountId = c.AccountId;
                            if (ConIDForRole != null){
                                o.put('npe01__Contact_Id_For_Role__c', (string)c.id);
                            }
                        }       
                                       
                        o.Amount = r.Amount__c;
                    
                        OppCloseDate = getNextDate(OppCloseDate, r.Installment_Period__c);
                    
                        String oName = '';
                        oName += r.Donor_Name__c; 
                        oName += ' ';
                        oName += System.Label.RecurringDonationPrefix;
                        oName += ' (';
                        oName += string.valueOf(rdcounter);
                        oName += ') ';
                        oName += o.CloseDate.format();
                        o.Name = oName;
                        
                        if (rds.Record_Type__c != null){
                            o.RecordTypeID = rds.Record_Type__c;
                        }                
                        o.StageName = System.Label.RecurringDonationStageName;
                        o.Recurring_Donation__c = r.Id;
                        if (r.Recurring_Donation_Campaign__c != null && (rds.Add_Campaign_to_All_Opportunites__c || rdcounter == 1)){
                            o.CampaignId = r.Recurring_Donation_Campaign__c;
                        }   
                        
                        //evaluate any custom field mappings
                        for (string s : customFieldMappingSettings.keySet()){
                            Custom_Field_Mapping__c cfm = customFieldMappingSettings.get(s);
                            o.put(cfm.Opportunity_Field__c, r.get(cfm.Recurring_Donation_Field__c)); 
                        }
                        opportunityInserts.add(o);    
                        rdcounter++;                                                                                       
                    }while (OppCloseDate < incrementdate.addMonths((integer)rds.Opportunity_Forecast_Months__c));                                        
                }
            }                 
        }
        
        if( opportunityInserts.size() > 0 )
        {   
        	set<id> RDID = new set<id>();        	
            for (Opportunity o : opportunityInserts){
            	RDID.add(o.Recurring_Donation__c);
            }
            
            Database.SaveResult[] lsr;
            list<Database.SaveResult> badSRs = new list<Database.SaveResult>();
            list<Opportunity> badOpps = new list<Opportunity>();
            set<id> createdOppIds = new set<id>();  
            
            //we're probably coming from the UI if we're only updating one RD, so lets 
            //let the error bubble up to the top
            if (RDID.size() == 1)
                lsr = Database.insert(opportunityInserts, true);
            //otherwise, this is a bulk operation so fail to the error handler 
            else
                lsr = Database.insert(opportunityInserts, false);        
                    
            integer i = 0;                          
            for (Database.SaveResult s : lsr){
                if (s.isSuccess() == true){
                    //get all the new OppIds into a list
                    createdOppIds.add(s.getId());
                }    
                //handle errors on insert   
                else{
                    badSRs.add(s);
                    badOpps.add(opportunityInserts[i]);            
                }                     
                i++;
            }
                    
            if (ConIDForRole == null){
                if (!system.isFuture() && !system.isBatch() && !RecurringDonations_ProcessControl.batchButton)
                    oppContactRolesFuture(createdOppIds); 
                else
                    oppContactRoles(createdOppIds);                    
            }
            
            if (!badSRs.isEmpty()){
                RecurringDonations_ErrorHandling.handleDMLErrorsOnOppInsert(badSRs, badOpps);
            }            
            
            if (!system.isBatch() && !system.isFuture() && !RecurringDonations_ProcessControl.batchButton)
                updateRecurringDonationOnOppChangeFuture(updateRecurringDonationSet); 
            else
                updateRecurringDonationOnOppChange(updateRecurringDonationSet);
        }
    }
    
    //async wrapper for oppcontact role creation
    @future 
    public static void oppContactRolesFuture(set<id> oppIds){oppContactRoles(oppIds);}
    public static void oppContactRoles( Set<Id> oppIds ){
        List<OpportunityContactRole> contactRoleInserts = new List<OpportunityContactRole>();
        map <String,Id> contactOppToContactRole = new Map <String,Id> ();
            
        Opportunity[] oppsFromRecurringDontaions = [select id, Recurring_Donation__c,Recurring_Donation__r.Contact__c from Opportunity where Id IN :oppIds AND Recurring_Donation__r.Contact__c!=null];
        
        if(oppsFromRecurringDontaions.size()>0){
            // query for OppConRoles where primary=true and OppID in arg set
            OpportunityContactRole[] conRoles = [select Id,OpportunityId, ContactId From OpportunityContactRole WHERE IsPrimary = true AND Opportunity.Id IN :oppIds ];
            String uniqueConRole = '';
            // now loop through the results and build the map
            for (OpportunityContactRole thisCR : conRoles) {
                uniqueConRole = string.valueOf(thisCR.OpportunityId) + string.valueOf(thisCR.ContactId);
                contactOppToContactRole.put(uniqueConRole , thisCR.Id );
            }
                
            for (Opportunity createdOpp : oppsFromRecurringDontaions) {
              
                OpportunityContactRole ocr = new OpportunityContactRole();
                ocr.OpportunityId = createdOpp.Id;
                ocr.Role = System.Label.RecurringDonationContactRole;
                ocr.IsPrimary = true;
                
                uniqueConRole = string.valueOf(createdOpp.Id)+string.valueOf(createdOpp.Recurring_Donation__r.Contact__c);
                if(contactOppToContactRole.get(uniqueConRole)==null){
                    ocr.ContactId = createdOpp.Recurring_Donation__r.Contact__c;
                    contactRoleInserts.add(ocr);
                    if ( contactRoleInserts.size() == 100 )
                    {
                        Database.SaveResult[] osr = Database.insert(contactRoleInserts, false);
                        contactRoleInserts.clear();
                    }
                }
            }
        }
        if ( contactRoleInserts.size() > 0 )
        {
            Database.SaveResult[] osr = Database.insert(contactRoleInserts, false);
        }
    }
    
    //updates opps that are part of a recurring donation that was updated
    @future
    public static void updateExistingOppsFuture(set<id>recIDs){updateExistingOpps(recIDs);}
    public static void updateExistingOpps(set<id> recIDs){
        
        
        Recurring_Donations_Settings__c rds = getRecurringDonationsSettings();
        string openLabel = system.label.RecurringDonationOpenStatus;
        map<id, Recurring_Donation__c> rdMap = new map<id, Recurring_Donation__c>([select id, Paid_Amount__c, Next_Payment_Date__c, 
                                                                                    Contact__c, Organization__c, Amount__c, 
                                                                                    Date_Established__c, Recurring_Donation_Campaign__c,
                                                                                     Installment_Period__c, Installments__c,
                                                                                     Last_Payment_Date__c, Open_Ended_Status__c,
                                                                                     Schedule_Type__c, Total_Paid_Installments__c,
                                                                                     Donor_Name__c
                                                                                  from Recurring_Donation__c 
                                                                                  where Open_Ended_Status__c = :openLabel 
                                                                                  and id IN :recIDs]);        
                           
        list<Opportunity> oppList = [select id, Amount, Name, CampaignId, AccountID, CloseDate, Recurring_Donation__r.id                                         
                                       from Opportunity 
                                       where Recurring_Donation__r.id IN :rdMap.keySet() 
                                       and isClosed = false
                                       order by CloseDate asc];

        //build a map of recurring donation ID and opps 
        map<id, list<Opportunity>> RDOppMap = new map<id, list<Opportunity>>(); 
        for (Opportunity o : opplist){
            if (RDOppMap.containsKey(o.Recurring_Donation__r.id)){
                list<Opportunity> opps = RDOppMap.get(o.Recurring_Donation__r.id);
                opps.add(o);
                RDOppMap.put(o.Recurring_Donation__r.id, opps);
            }
            else{
                RDOppMap.put(o.Recurring_Donation__r.id, new list<Opportunity>{o});
            }
        }       
        
        //opps for updating
        list<Opportunity> updateOppsList = new list<Opportunity>();
        
        //loop through existing opps for each RD and update according to values on the RD
        for (id RDid : RDOppMap.keySet()){
            
            date PaymentDate = RDMap.get(RDid).Next_Payment_Date__c;
            
            for (Opportunity o : RDOppMap.get(RDid)){
                
                o.Amount = rdMap.get(RDid).Amount__c;
                if (rdMap.get(RDid).Recurring_Donation_Campaign__c != null && rds.Add_Campaign_to_All_Opportunites__c){ 
                    o.CampaignId = rdMap.get(RDid).Recurring_Donation_Campaign__c;
                }               
                
                //changed for beta 7 - dont' update with a null org unless we need to
                if (rdMap.get(RDid).Organization__c != null)
                    o.AccountID = rdMap.get(RDid).Organization__c;
                o.CloseDate = PaymentDate;                      
                
                //rebuild the donor string by plucking out the installment number for re-use
                integer lbracket = o.Name.indexOf('(');
                integer rbracket = o.Name.indexOf(')');
                string iNumber = '';
                if (lbracket > 0 && rbracket > lbracket)
                   iNumber = o.Name.substring(lbracket, rbracket + 1);
                //modify the name 
                String oName = '';
                oName += rdMap.get(RDid).Donor_Name__c; 
                oName += ' ';
                oName += System.Label.RecurringDonationPrefix;
                oName += ' ' + iNumber + ' ';
                oName += o.CloseDate.format();
                o.Name = oName;
                
                //now append appropriate amount to this date
                PaymentDate = getNextDate(PaymentDate, RDMap.get(RDid).Installment_Period__c);
                updateOppsList.add(o);
            }
        }
        
        if (!updateOppsList.isEmpty())
           update updateOppsList;
        
        
        if (system.isFuture() || RDOppMap.keySet().size() == 1 || system.isBatch() || RecurringDonations_ProcessControl.batchButton){
            updateRecurringDonationOnOppChange(RDOppMap.keySet());
        }          
        else{
            updateRecurringDonationOnOppChangeFuture(RDOppMap.keySet());            
        }
    }
         
    //handles updates to the recurring donations object
    public static void handleRecurringDonationUpdate(list<Recurring_Donation__c> recurringDonations, map<id, Recurring_Donation__c> oldRecurringDonations){
        
        //opening a closed recurring donation
        set<id> reevaluateOpps = new set<id>();
        list<Recurring_Donation__c> reinsertOpps = new list<Recurring_Donation__c>(); 
        // closed an open recurring donation
        list<Recurring_Donation__c> newlycloseddonations = new list<Recurring_Donation__c>();
         
        string openlabel = system.label.RecurringDonationOpenStatus;
        string closedlabel = system.label.RecurringDonationClosedStatus;        
        
        for (Recurring_Donation__c r : recurringDonations){
            Recurring_Donation__c oldRD = oldRecurringDonations.get(r.id);
            
            //if we're closing an open ended donation, modify the existing opps as required by the custom setting
            if (r.Open_Ended_Status__c == closedlabel && oldRD.Open_Ended_Status__c != r.Open_Ended_Status__c){
                newlycloseddonations.add(r);        
            }            
            
            //if there's any other change that would require a reevaluation of existing Opps
            else if (r.Open_Ended_Status__c == openlabel){
                if (r.Amount__c != oldRD.Amount__c ||
                    r.Recurring_Donation_Campaign__c != oldRD.Recurring_Donation_Campaign__c ||
                    r.Organization__c != oldRD.Organization__c ||
                    r.Next_Payment_Date__c != oldRD.Next_Payment_Date__c                    
                    ){
                    reevaluateopps.add(r.id);
                }
                else if (r.Installment_Period__c != oldRD.Installment_Period__c || r.Contact__c != oldRD.Contact__c){
                    reinsertopps.add(r);
                }                                        
            }
        }      
        
        if (!newlycloseddonations.isEmpty()){
        	runRecurringDonationClosedActions(newlycloseddonations);
        }
        if (!reevaluateopps.isEmpty()){
        	if (reevaluateopps.size() == 1 || system.isBatch())
                updateExistingOpps(reevaluateopps);
            else
                updateExistingOppsFuture(reevaluateopps);
        }
        //needs a total reinsert, not an update
        if (!reinsertopps.isEmpty()){
        	//clear existing open opps and recreate
        	delete [select id from Opportunity where Recurring_Donation__c IN :reinsertopps and isClosed = false];
        	if (reinsertopps.size() == 1 || system.isBatch()){
                insertOppsOnRecurringDonationInsert(reinsertopps);            		
        	}
        	else{
        		set<id> rdset = new set<id>();
                for (Recurring_Donation__c r : reinsertopps)
                    rdset.add(r.id);
                insertOppsOnRecurringDonationInsertFuture(rdset);	
        	}
        }
    }
    
        /// <name> deleteRecDonations </name>
    /// <summary> Validates that a Recurring Donation can be deleted </summary>
    /// <param name="recurringDonations"> RecurringDonation objects that are being triggered </param>
    private static void deleteRecDonations(Recurring_Donation__c[] recurringDonations)
    {
        Map<Id,Id> recDonationMap = new Map<Id,Id>();
        List<Id> recDonationIds = new List<Id>();
        
        for(Recurring_Donation__c r : recurringDonations)
        {
            recDonationIds.add(r.Id);
        }
        for (Opportunity o : [Select Id, Recurring_Donation__c from Opportunity where Recurring_Donation__c in :recDonationIds])
        {
            recDonationMap.put(o.Recurring_Donation__c,o.Id);
        }
        for(Recurring_Donation__c r : recurringDonations)
        {
            if(recDonationMap.containsKey(r.Id))
            {
                r.addError(System.Label.RecurringDonationCantDeleteError);
            }
        }
    }

    public static void evaluateRecurringDonationsForNewOppInsert(list<Recurring_Donation__c> recurringDonationsToEvaluate){
    	
    	Recurring_Donations_Settings__c rds = getRecurringDonationsSettings();
    
    	list<Opportunity> oppInsertList = new list<Opportunity>();
    	
        //get the total number of forecast months
        integer forecast_months = (integer)rds.Opportunity_Forecast_Months__c;
        SObjectField RDCurrencyField; 
        // multicurrency support
        SObjectField OppCurrencyField = Schema.sObjectType.Opportunity.fields.getMap().get('CurrencyIsoCode');
        //grab the contact id for role to take advantage of NPSP C&O if it exists
        Sobjectfield ConIDForRole = Schema.sObjectType.Opportunity.fields.getMap().get('npe01__Contact_Id_for_Role__c');
        if(OppCurrencyField != null){
            RDCurrencyField = Schema.sObjectType.Recurring_Donation__c.fields.getMap().get('CurrencyIsoCode');
        }
        string openlabel = system.label.RecurringDonationOpenStatus;
        
        //get the existing donations
        list<sobject> sobjs = [select count(id) oppCount, MAX(CloseDate) MaxDate,
                                  Recurring_Donation__r.id rdid
                                  from Opportunity where Recurring_Donation__r.Open_Ended_Status__c = :openLabel 
                                  and Recurring_Donation__r.id IN :recurringDonationsToEvaluate                                  
                                  group by rollup(Recurring_Donation__r.id)]; 
        
        map<id, date> lastOppMap = new map<id, date>();
        map<id, integer> oppCountMap = new map<id, integer>();
        set<id> contactIDs = new set<id>();
                
        for (Recurring_Donation__c rd : recurringDonationsToEvaluate){
            if (rd.Contact__c != null ){
                contactIds.add(rd.Contact__c);
            }
        }            
        //Create a Map of Contact Ids and Contact Records
        map<id,Contact> contactMap;        
        if (contactIds.size() > 0){
            contactMap = new Map<Id,Contact>([Select Id, AccountId from Contact where Id in :contactIds and AccountId != null]);
        }        
 
        for (sobject obj : sobjs){
            id rdid = (id)obj.get('rdid'); 
            if ((date)obj.get('MaxDate') != null){
                lastOppMap.put(rdid, (date)obj.get('MaxDate'));
            }
                                  
            oppCountMap.put(rdid, (integer)obj.get('oppCount'));                 
        }
        
        customFieldMappingSettings = Custom_Field_Mapping__c.getAll();
        //if the RD has no opps, we'll need to bail back to the insert methods
        list<Recurring_Donation__c> reRollRDs = new list<Recurring_Donation__c>();
        for (Recurring_Donation__c rd : recurringDonationsToEvaluate){
        	
        	//only proceed if there are some opps, otherwise we need to start over from scratch	
        	if (oppCountMap.containsKey(rd.id)){
        	    integer oppCounter = oppCountMap.get(rd.id) + 1;                    
                           
                if (system.today().addMonths(forecast_months) > lastOppMap.get(rd.id)){
                    date oppclosedate = lastOppMap.get(rd.id);
                    do{
                        Opportunity o = new Opportunity();

                        //multicurrency?
                        if(RDCurrencyField != null){o.put(OppCurrencyField,rd.get(RDCurrencyField));}
                    
                        //account or contact?
                        if (rd.Organization__c != null){
                    	   o.AccountId = rd.Organization__c;
                        }
                        else if (contactMap.containsKey(rd.Contact__c)){
                            Contact c = contactMap.get(rd.Contact__c);
                            o.AccountId = c.AccountId;
                            if (ConIDForRole != null){
                                o.put('npe01__Contact_Id_For_Role__c', (string)c.id);
                            }
                        }                    
                    
                        oppclosedate = getNextDate(oppclosedate, rd.Installment_Period__c);
                        o.CloseDate = oppclosedate;                                                                            	           
                	    string oName = rd.Donor_Name__c + ' ' + System.Label.RecurringDonationPrefix +
                        ' (' + string.valueOf(oppCounter) + ') ' + o.CloseDate.format();
                    
                        o.Name = oName;
                        o.Amount = rd.Amount__c;
                        o.StageName = System.Label.RecurringDonationStageName;                    
                        o.Recurring_Donation__c = rd.Id;                    
                        //evaluate any custom field mappings
                        for (string s : customFieldMappingSettings.keySet()){
                            Custom_Field_Mapping__c cfm = customFieldMappingSettings.get(s);
                            o.put(cfm.Opportunity_Field__c, rd.get(cfm.Recurring_Donation_Field__c));
                        }
                    
                        if (rd.Recurring_Donation_Campaign__c != null && (rds.Add_Campaign_to_All_Opportunites__c || oppCounter == 1)){
                            o.CampaignId = rd.Recurring_Donation_Campaign__c;
                        }
                    
                        oppCounter++;
                        oppInsertList.add(o);                	
                    }while(oppclosedate < system.today().addMonths(forecast_months));
                }
        	}
        	else{
        		reRollRDs.add(rd);
        	}
        }
        if (!reRollRDs.isEmpty())
            insertOppsOnRecurringDonationInsert(reRollRDs);
       
        set<id> RDID = new set<id>();  
        if(!oppInsertList.isEmpty())
        {
            Database.SaveResult[] lsr;
            list<Database.SaveResult> badSRs = new list<Database.SaveResult>();
            list<Opportunity> badOpps = new list<Opportunity>();
            set<id> createdOppIds = new set<id>();  
            
            //we're probably coming from the UI if we're only updating one RD, so lets 
            //let the error bubble up to the top
            if (RDID.size() == 1)
                lsr = Database.insert(oppInsertList, true);
            //otherwise, this is a bulk operation so fail to the error handler 
            else
                lsr = Database.insert(oppInsertList, false);        
                    
            integer i = 0;                          
            for (Database.SaveResult s : lsr){
                if (s.isSuccess() == true){
                    //get all the new OppIds into a list
                    createdOppIds.add(s.getId());
                    RDID.add(oppInsertList[i].Recurring_Donation__c);                    
                }    
                //handle errors on insert   
                else{
                    badSRs.add(s);
                    badOpps.add(oppInsertList[i]);            
                }                     
                i++;
            }
                    
            if (ConIDForRole == null){
                if (!system.isFuture() && !system.isBatch() && !RecurringDonations_ProcessControl.batchButton)
                    oppContactRolesFuture(createdOppIds); 
                else 
                    oppContactRoles(createdOppIds);                    
            }
            
            if (!badSRs.isEmpty()){
                RecurringDonations_ErrorHandling.handleDMLErrorsOnOppInsert(badSRs, badOpps);
            }
        }
        
        if (system.isFuture() || system.isBatch() || (recurringDonationsToEvaluate.size() == 1 && !system.isFuture() && !system.isBatch()) || RecurringDonations_ProcessControl.batchButton){
        	updateRecurringDonationOnOppChange(RDID);
        }
        else{
        	updateRecurringDonationOnOppChangeFuture(RDID); 
        }   
    }
    
    /*** UTILITY METHODS ***/
    
    //get the settings. handles the case where the managed value doesn't exist yet
    public static Recurring_Donations_Settings__c getRecurringDonationsSettings() {
        //if no settings exist, create defaults
        if (recurringDonationsSettings == null) {
            //first see if we already have settings
            recurringDonationsSettings = Recurring_Donations_Settings__c.getOrgDefaults();
            //if the save behavior is null, then we'll need to upsert new settings, otherwise, we have valid settings as its 
            //the only field w/o a default defined
            if (recurringDonationsSettings.Open_Opportunity_Behavior__c == null){  
                recurringDonationsSettings.Open_Opportunity_Behavior__c = RecurringDonations.RecurringDonationCloseOptions.Mark_Opportunities_Closed_Lost.name();
                recurringDonationsSettings.Add_Campaign_to_All_Opportunites__c = true;
                recurringDonationsSettings.Enable_Update_Check__c = true;
                recurringDonationsSettings.Error_Email_Notifications__c = 'All Sys Admins';
                recurringDonationsSettings.Maximum_Donations__c = 50;
                recurringDonationsSettings.Opportunity_Forecast_Months__c = 12;
                recurringDonationsSettings.Update_Check_Interval__c = 90;
                id myid = [select id from RecordType where sobjecttype = 'Opportunity' limit 1].id;
                recurringDonationsSettings.Record_Type__c = myid; 
                upsert recurringDonationsSettings;    
                recurringDonationsSettings = Recurring_Donations_Settings__c.getOrgDefaults();                           
            }
        }         
        return recurringDonationsSettings;
    }

    //handles action for opps on recurring donations
    private static void runRecurringDonationClosedActions(list<Recurring_Donation__c> closedRDs){
        // determine the update type - 
        Recurring_Donations_Settings__c rds = getRecurringDonationsSettings();
         system.debug('IN THE PRIVATE METHOD');
        if (!closedRDs.isEmpty() && rds.Open_Opportunity_Behavior__c != RecurringDonationCloseOptions.No_Action.name()){
            list<Opportunity> olist = [select StageName, Recurring_Donation__r.id from Opportunity where Recurring_Donation__r.id IN :closedRDs and isClosed = false];
         
            if (rds.Open_Opportunity_Behavior__c == RecurringDonationCloseOptions.Delete_Open_Opportunities.name()){
               system.debug('IN THE PRIVATE METHOD3');
               database.delete(olist);
            }              
            else if (rds.Open_Opportunity_Behavior__c == RecurringDonationCloseOptions.Mark_Opportunities_Closed_Lost.name()){
                for (Opportunity o : olist){
                    o.StageName = system.label.RecurringDonationClosedLostOpportunityStage;
                }            
                update olist; 
            }
        }
    }

    //helper for calculating the next date in the sequence based on the RD schedule type 
    private static date getNextDate(date CalcDate, string InstallmentType){
    	Recurring_Donations_Settings__c rds = getRecurringDonationsSettings();
    	
    	if (InstallmentType == System.Label.RecurringDonationInstallmentPeriodYearly){
            CalcDate = CalcDate.addYears(1);
        } 
        else if (InstallmentType == System.Label.RecurringDonationInstallmentPeriodQuarterly){
            CalcDate = CalcDate.addMonths(3);
        } 
        else if (InstallmentType == System.Label.RecurringDonationInstallmentPeriodMonthly){
            CalcDate = CalcDate.addMonths(1);
        } 
        else if (InstallmentType == System.Label.RecurringDonationInstallmentPeriodWeekly){
            CalcDate = CalcDate.addDays(7);
        }
      /*  else if (InstallmentType == System.label.RecurringDonationInstallmentPeriodCustom){ 
            CalcDate = CalcDate.addDays((integer)rds.Custom_Days__c);
        }*/
        else if (InstallmentType == system.label.RecurringDonationInstallmentPeriod1stand15th){
            //increment it by one day until we hit either the 1st or 15th            
            do{
            	CalcDate = CalcDate.addDays(1);
            }while (CalcDate.day() != 15 && CalcDate.day() != 1);
        }        
        else{
        	map<string, Custom_Installment_Settings__c> cisMap = Custom_Installment_Settings__c.getAll();
            //handle custom installment types        	
        	if (cisMap.containsKey(InstallmentType)){
        		Custom_Installment_Settings__c c = cisMap.get(InstallmentType);
        		
        		if (c.Increment__c == 'Days'){
                    CalcDate = CalcDate.addDays(integer.valueOf(c.Value__c));
                }
                else if (c.Increment__c == 'Weeks'){
                    CalcDate = CalcDate.addDays(integer.valueOf(c.Value__c * 7));
                }
                else if (c.Increment__c == 'Months'){
                    CalcDate = CalcDate.addMonths(integer.valueOf(c.Value__c));
                }
                else if (c.Increment__c == 'Years'){
                    CalcDate = CalcDate.addYears(integer.valueOf(c.Value__c));
                }        	
        	}
            //if its not a valid value, set it to the max last payment date plus the 
            //the open ended value so we only create one opp max                    	   
            else{	
                CalcDate = CalcDate.addMonths((integer)rds.Opportunity_Forecast_Months__c);
            }                
        }
    	return CalcDate;
    }
}