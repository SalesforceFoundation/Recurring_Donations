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
global class RecurringDonations {



	/// <name> RecurringDonations </name>
	/// <summary> Default Constructor </summary> 
	public RecurringDonations(){}


	/// <name> triggerAction </name>
	/// <summary> contains possible actions for a trigger </summary>
	public enum triggerAction {beforeInsert, beforeUpdate, beforeDelete, afterInsert, afterUpdate, afterDelete, afterUndelete}
    
    
    public static Recurring_Donations_Settings__c recurringDonationsSettings;    
    

	/// <name> RecurringDonations </name>
	/// <summary> Overloads the RecurringDonations object constructor to handle RecurringDonation processing </summary>
	/// <param name="recurringDonations"> RecurringDonation objects that are being triggered </param>
	/// <param name="oldRecurringDonations"> RecurringDonation object values before trigger event </param>
	/// <param name="ta"> Trigger action that is occuring </param>
	
	public RecurringDonations(map<id, Opportunity> newOppMap, map<id, Opportunity> oldOppMap, triggerAction ta){
		
		set<id> rdIDs = new set<id>();
		list<Recurring_Donation__c> rdList = new list<Recurring_Donation__c>();
    
        if (ta == triggerAction.afterUpdate){		
            for (Opportunity o : newOppMap.values()){
                //does it have a recurring donation reference?
                //has it moved into a closed state?
                if (o.Recurring_Donation__c != null && (o.isClosed && !oldOppMap.get(o.id).isClosed)){
				    rdIds.add(o.Recurring_Donation__c);
                }
            }                  
		}		
	
        //recurring donations that need to be updated	   
        if (!rdIds.isEmpty()){
            updateOnOppChange(rdIds);                    	
        }
	
	}
	
	
	
	
	public RecurringDonations(Recurring_Donation__c[] recurringDonations, map<id, Recurring_Donation__c> oldRecurringDonations, triggerAction ta)
	{
		List<Recurring_Donation__c> contactRecDonations = new List<Recurring_Donation__c>();
		List<Recurring_Donation__c> accountRecDonations = new List<Recurring_Donation__c>();
		List<Recurring_Donation__c> recDonationDeletes = new List<Recurring_Donation__c>();
		list<Recurring_Donation__c> rdInserts = new list<Recurring_Donation__c>(); 
		
		list<Recurring_Donation__c> recDonationUpdates = new list<Recurring_Donation__c>();

		for(Recurring_Donation__c r : recurringDonations)
		{
			if (ta==triggerAction.beforeInsert)
			{
				if (r.Organization__c == null && r.Contact__c == null)
				{
					r.addError(System.Label.RecurringDonationMissingDataError);
				}
				if ( r.Installments__c > 50 )
				{
					r.addError(System.Label.RecurringDonationTooManyInstallmentsError);
				}
			}
			
			if ( ta==triggerAction.afterInsert ){
				rdInserts.add(r);
			}
			
			if ( ta==triggerAction.beforeDelete )
			{
				recDonationDeletes.add(r);
			}
			
			
			//added for 2.0
			if (ta==triggerAction.afterUpdate){
                recDonationUpdates.add(r);
			}
			
			
		}
		
		
		if ( recDonationDeletes.size() > 0 )
		{
			deleteRecDonations(recDonationDeletes);
		}
		
		//added for 2.0
		if (recDonationUpdates.size() > 0){
			updateRecDonations(recDonationUpdates, oldRecurringDonations); 
		}
		if (rdInserts.size() > 0){
            insertOpptys(rdInserts);
        }
		
	}
	
	/// <name> insertContactOpportunities </name>
	/// <summary> Creates new Opportunities when a RecurringDonation is inserted </summary>
	/// <param name="recurringDonations"> RecurringDonation objects that are being triggered </param>
	public static void insertOpptys(list<Recurring_Donation__c> recurringDonations)
	{
		//Lists used for final Insert
		List<Opportunity> opportunityInserts = new List<Opportunity>();
		
		// James Melville 05/03/2011 Added to support multi-currency sfdc.  */
        // CurrencyIsoCode doesn't exist in non-multi-currency orgs
        SObjectField OppCurrencyField = Schema.sObjectType.Opportunity.fields.getMap().get('CurrencyIsoCode');
		
		
		//Create a list of ContactIds used in these RecurringDonations
		list<Id> contactIds = new list<Id>();
		map<Id,Id> recConMap = new map<Id,Id>();
		for( Recurring_Donation__c r : recurringDonations )
		{
			if ( r.Contact__c != null )
			{
				contactIds.add(r.Contact__c);
				recConMap.put(r.Id,r.Contact__c);
			}
		}

		//Create a Map of Contact Ids and Contact Records
		map<Id,Contact> contactMap;
		map<Id,Account> accountMap;
		if (contactIds.size() > 0)
		{
			contactMap = new Map<Id,Contact>([Select Id, AccountId from Contact where Id in :contactIds and AccountId != null]);
		}
		
		//Loop through the Recurring Donations and create the appropriate number of Opportunities
		for(Recurring_Donation__c r : recurringDonations)
		{
		    //if we're not looking at an open-ended type donation, handle it the 'old' way		  
            if (r.Open_Ended_Status__c != system.label.RecurringDonationOpenStatus && r.Open_Ended_Status__c != system.label.RecurringDonationClosedStatus){		  
		
                Decimal installs = Decimal.valueOf(r.Installments__c);
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
				    if (r.Recurring_Donation_Campaign__c != null){
					   opp.CampaignId = r.Recurring_Donation_Campaign__c;
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
            	if (r.Open_Ended_Status__c == system.label.RecurringDonationOpenStatus){
            	   //get settings so we can figure out how many donations to create
            	   Recurring_Donations_Settings__c rds = getRecurringDonationsSettings();
            	   
            	   
            	   
            	   
            	
            	
            	
            	}
            }
            
            			     
		}
		
		if( opportunityInserts.size() > 0 )
		
		
		{
			
			Database.SaveResult[] lsr = Database.insert(opportunityInserts, false);
			Set<Id> createdOppIds = new Set<Id>();
			for (Database.SaveResult s : lsr)
       	    {
       	    	if ( s.isSuccess() == true ){
	       	    	//get all the new OppIds into a list
	       	    	createdOppIds.add(s.getId());
       	    	}
       	    }
       	    
       	    oppContactRolesFuture(createdOppIds);
			
		}
	}
	
	//async wrapper for oppcontact role creation
	@future 
	public static void oppContactRolesFuture(set<id> oppIds){
		oppContactRoles(oppIds);
	}
	
	
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
	

	/// <name> deleteRecDonations </name>
	/// <summary> Validates that a Recurring Donation can be deleted </summary>
	/// <param name="recurringDonations"> RecurringDonation objects that are being triggered </param>
	public static void deleteRecDonations(Recurring_Donation__c[] recurringDonations)
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
	
	
	//handles updates to the recurring donations object
	public static void updateRecDonations(list<Recurring_Donation__c> recurringDonations, map<id, Recurring_Donation__c> oldRecurringDonations){
		
				
        // the change is in the opps...
        // update the recurring donation
        if (oldRecurringDonations == null){        
                    	
                    		
        }

        // determine the update type - 
        // change to next due date?
        // change in schedule? 
        else{
        	for (Recurring_Donation__c r : recurringDonations){
            
            
            
            
            
            
            }
        	
        }
	}
	
	
	//updating the RD based on a change in the opp stage, going from open to closed
	@future
	public static void updateOnOppChange(set<id> recurringDonationIDs){
		
		// James Melville 05/03/2011 Added to support multi-currency sfdc.  */
        // CurrencyIsoCode doesn't exist in non-multi-currency orgs
        // we check currency iscode before entering the loop since it's a system check
        SObjectField OppCurrencyField = Schema.sObjectType.Opportunity.fields.getMap().get('CurrencyIsoCode');
        
        //grab the contact id for role to take advantage of NPSP C&O if it exists
        Sobjectfield ConIDForRole = Schema.sObjectType.Opportunity.fields.getMap().get('npe01__Contact_Id_for_Role__c');
		
        //set of RDs to be updated	       
		map<id, Recurring_Donation__c> updateMap = new map<id, Recurring_Donation__c>();
		list<Opportunity> oppInsertList = new list<Opportunity>();
		
        Recurring_Donations_Settings__c rds = getRecurringDonationsSettings();	   
        string openLabel = system.label.RecurringDonationOpenStatus;
		
		//get all possible rd records that may need updating, exclude ones not in an open state  
		map<id, Recurring_Donation__c> rdMap = new map<id, Recurring_Donation__c>([select id, Paid_Amount__c, Next_Payment_Date__c 
		                                                                          from Recurring_Donation__c 
		                                                                          where Open_Ended_Status__c = :openLabel 
		                                                                          and id IN :recurringDonationIDs]);
		
		list<sobject> sobjs = [select count(id) oppcount, MIN(CloseDate) MinDate, MAX(CloseDate) MaxDate, SUM(Amount) Total,
		                          isClosed, Recurring_Donation__c 
		                          from Opportunity where Recurring_Donation__r.Open_Ended_Status__c = :openLabel 
		                          and id IN :rdMap.keySet()
		                          group by rollup(Recurring_Donation__c, isClosed)];
		
		map<id, date> maxOpenPaymentMap = new map<id, date>();
		map<id, integer> oppCountMap = new map<id, integer>();
		
		
		//update the rc next payment date 
		//and add new donation objects needed 
		for (sobject obj : sobjs){
            id rdid = (id)obj.get('Recurring_Donation__c');
            
            //get the total number of opps for usage in naming later...
            if (!oppCountMap.containsKey(rdid)){
                oppCountMap.put(rdid, (integer)obj.get('oppcount'));
            }
            else{
            	integer x = oppCountMap.get(rdid);
            	x = x + (integer)obj.get('oppcount');
            	oppCountMap.put(rdid, x);
            }
            
            
            Recurring_Donation__c rd;
            
            if (!updateMap.containsKey(rdid)){
                rd = rdMap.get(rdid);
            }
            else{
            	rd = updateMap.get(rdid);
            }
            
            boolean isClosed = (boolean)obj.get('isClosed');
            
            //if this is the open set for this rd
            if (isClosed != null && !isClosed){
            	rd.Next_Payment_Date__c = (date)obj.get('MinDate');
            	updateMap.put(rdid, rd);
            	maxOpenPaymentMap.put(rdid, (date)obj.get('MaxDate'));            	            	
            }
            //if this is the closed set		
            else if (isClosed != null && isClosed){
                rd.Last_Payment_Date__c = (date)obj.get('MaxDate');
                rd.Paid_Amount__c = (decimal)obj.get('Total');     
                rd.Total_Paid_Installments__c = (integer)obj.get('oppcount');
                updateMap.put(rdid, rd);       	            	
            }
		}
		
		//get the total number of forecast months
		integer oppMonths = (integer)rds.Opportunity_Forecast_Months__c;
		
		SObjectField RDCurrencyField; 
		// multicurrency support
        if(OppCurrencyField != null){
            RDCurrencyField = Schema.sObjectType.Recurring_Donation__c.fields.getMap().get('CurrencyIsoCode');
        }
        
        //Create a list of ContactIds used in these RecurringDonations
        list<id> contactIds = new list<id>();
        map<id,id> recConMap = new map<id,id>();
        for( Recurring_Donation__c rd : updateMap.values()){
            if (rd.Contact__c != null ){
                contactIds.add(rd.Contact__c);
                recConMap.put(rd.id,rd.Contact__c);
            }
        }
        //Create a Map of Contact Ids and Contact Records
        map<id,Contact> contactMap;        
        if (contactIds.size() > 0){
            contactMap = new Map<Id,Contact>([Select Id, AccountId from Contact where Id in :contactIds and AccountId != null]);
        }
		
		for (Recurring_Donation__c rd : updateMap.values()){
            
            date OppCloseDate;
            
			//if max open payment is less than the value of hte last payment + the 
            //scheduled open timeframe, add as many opps as needed to satisfy teh criteria
            if (rd.Last_Payment_Date__c.addMonths(oppMonths) > maxOpenPaymentMap.get(rd.id)){
                do{
                    Opportunity o = new Opportunity();

                    if(RDCurrencyField != null){
                        //set the donation currency field to equal the recurring donation currency
                        o.put(OppCurrencyField,rd.get(RDCurrencyField));
                    }
                    
                    if (rd.Organization__c != null){
                       o.AccountId = rd.Organization__c;
                    }
                    else if (contactMap.containsKey(rd.Contact__c)){
                        Contact c = contactMap.get(rd.Contact__c);
                        o.AccountId = c.AccountId;
                        
                        if (ConIDForRole != null){
                            o.put((string)c.id, 'npe01__Contact_Id_For_Role__c');
                        }
                    }                           
                                	   
                    o.Amount = rd.Installment_Amount__c;
                    
                    if (rd.Installment_Period__c == System.Label.RecurringDonationInstallmentPeriodYearly){
                        o.CloseDate = (maxOpenPaymentMap.get(rd.id)).addYears(1);
                    } 
                    else if (rd.Installment_Period__c == System.Label.RecurringDonationInstallmentPeriodQuarterly){
                        o.CloseDate = (maxOpenPaymentMap.get(rd.id)).addMonths(3);
                    } 
                    else if (rd.Installment_Period__c == System.Label.RecurringDonationInstallmentPeriodMonthly){
                        o.CloseDate = (maxOpenPaymentMap.get(rd.id)).addMonths(1);
                    } 
                    else if (rd.Installment_Period__c == System.Label.RecurringDonationInstallmentPeriodWeekly){
                        o.CloseDate = (maxOpenPaymentMap.get(rd.id)).addDays(7);
                    }
                    else if (rd.Installment_Period__c == System.label.RecurringDonationInstallmentPeriodCustom){
                        o.CloseDate = (maxOpenPaymentMap.get(rd.id).addDays((integer)rds.Custom_Days__c));
                    }
                    //if its not a valid value, set it to the max last payment date plus the 
                    //the open ended value so we only create one opp max
                    else{
                        o.CloseDate = rd.Last_Payment_Date__c.addMonths(oppMonths);
                    }
                    
                    OppCloseDate = o.CloseDate;
                    
                    String oName = '';
                    oName += rd.Donor_Name__c; 
                    oName += ' ';
                    oName += System.Label.RecurringDonationPrefix;
                    oName += ' (';
                    oName += string.valueOf((oppCountMap.get(rd.id) + 1));
                    oName += ') ';
                    oName += o.CloseDate.format();
                    o.Name = oName;
                
                    o.StageName = System.Label.RecurringDonationStageName;
                    o.Recurring_Donation__c = rd.Id;
                    if (rd.Recurring_Donation_Campaign__c != null){
                       o.CampaignId = rd.Recurring_Donation_Campaign__c;
                    }
                    oppInsertList.add(o);
                }
                while (OppCloseDate < rd.Last_Payment_Date__c.addMonths(oppMonths));
            }
		}
		
		//update recurring donations
		if (!updateMap.values().isEmpty()){
			update updateMap.values();
		}
		
		//insert the opps
		if(!oppInsertList.isEmpty()){
            Database.SaveResult[] lsr = Database.insert(oppInsertList, false);
            
            //if we didn't find the npe01 field on the opp, we need to create OCRs manually
            if (ConIDForRole == null){
                Set<Id> createdOppIds = new Set<Id>();
                for (Database.SaveResult s : lsr){
                    if (s.isSuccess() == true){
                    //get all the new OppIds into a list
                        createdOppIds.add(s.getId());
                    }
                }
                oppContactRoles(createdOppIds);
            }
        }
	}

	
	
	@future
	public static void changeOppSchedule(list<id> recurringDonations){
		
		
	}	
	
	 //get the settings. handles the case where the managed value doesn't exist yet
    public static Recurring_Donations_Settings__c getRecurringDonationsSettings() {
        String oldProcessor = '';
        //if no settings exist, create defaults
        if (recurringDonationsSettings == null) {
            //first see if we already have settings
            recurringDonationsSettings = Recurring_Donations_Settings__c.getOrgDefaults();
            //system.debug(Households_Settings__c.getOrgDefaults());
            if (recurringDonationsSettings == null) { 
                recurringDonationsSettings = new Recurring_Donations_Settings__c();
                recurringDonationsSettings.Open_Opportunity_Behavior__c = '';
                recurringDonationsSettings.Opportunity_Forecast_Months__c = 12; 
                insert recurringDonationsSettings;
            }
        }        
        return recurringDonationsSettings;
    }
}