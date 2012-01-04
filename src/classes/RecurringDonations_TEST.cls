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
@isTest
private class RecurringDonations_TEST {

	/// <name> RecurringDonations_Test </name>
	/// <summary> test default constructor </summary>
	static testMethod void RecurringDonations()
	{
  		RecurringDonations testRecurringDonations = new RecurringDonations();
	}


	/// <name> insertOpportunities_Test </name>
	/// <summary> test method for insertOpportunities function </summary>
	static testMethod void insertOpportunities()
	{
		
		system.debug('multiply: ' + System.Label.RecurringDonationMultiplyValue);
		system.debug('divide: ' + System.Label.RecurringDonationDivideValue);
        Account a = new Account();
        a.Name = 'test Individual';
        insert a;
        
        Contact c = new Contact();
        c.FirstName = 'test';
        c.LastName = 'contact';
        c.AccountId = a.Id;
        insert c;

		Recurring_Donation__c r0 = new Recurring_Donation__c();
		r0.Name = 'test';
		r0.Installments__c = 3;
		r0.Amount__c = 100;
		r0.Installment_Period__c = System.Label.RecurringDonationInstallmentPeriodYearly;
		r0.Date_Established__c = date.newinstance(1970,6,12);
		r0.Schedule_Type__c = System.Label.RecurringDonationMultiplyValue;
		try {
			insert r0;
		} catch (exception e) {
			
		}
		//insert should fail because there is no Contact
		system.assertEquals(null,r0.id);
		

		Recurring_Donation__c r1 = new Recurring_Donation__c();
		r1.Name = 'test';
		r1.Installments__c = 2;
		r1.Contact__c = c.Id;
		r1.Amount__c = 100;
		r1.Installment_Period__c = System.Label.RecurringDonationInstallmentPeriodYearly;
		r1.Date_Established__c = date.newinstance(1970,6,12);
		r1.Schedule_Type__c = System.Label.RecurringDonationMultiplyValue;
		insert r1;
		
		Opportunity[] installments1 = [select Name,amount,accountid,CloseDate from Opportunity where Recurring_Donation__c = :r1.id];
		system.assertEquals(2,installments1.size());
		system.assertEquals(100,installments1[0].Amount);
		system.assertEquals(date.newinstance(1970,6,12),installments1[0].CloseDate);
		system.assertEquals(a.id,installments1[0].AccountId);
		system.assertEquals(100,installments1[1].Amount);
		system.assertEquals(date.newinstance(1971,6,12),installments1[1].CloseDate);
		system.assertEquals(a.id,installments1[1].AccountId);
		system.debug(installments1);
		
		Recurring_Donation__c r3 = new Recurring_Donation__c();
		r3.Name = 'test';
		r3.Installments__c = 55;
		r3.Organization__c = a.Id;
		r3.Amount__c = 100;
		r3.Installment_Period__c = System.Label.RecurringDonationInstallmentPeriodWeekly;
		r3.Date_Established__c = date.newinstance(1970,6,12);
		r3.Schedule_Type__c = System.Label.RecurringDonationMultiplyValue;
		try {
			insert r3;
		} catch (exception e) {
			
		}
		//insert should fail because there is no Contact
		system.assertEquals(null,r3.id);
	}
	
	static testMethod void insertWeeklyOpportunities()
	{
		
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
		r1.Contact__c = c.Id;
		r1.Amount__c = 100;
		r1.Installment_Period__c = System.Label.RecurringDonationInstallmentPeriodWeekly;
		r1.Date_Established__c = date.newinstance(1970,6,12);
		r1.Schedule_Type__c = System.Label.RecurringDonationMultiplyValue;
		insert r1;
		
		Opportunity[] installments1 = [select Name,amount,accountid,CloseDate from Opportunity where Recurring_Donation__c = :r1.id];
		system.assertEquals(2,installments1.size());
		system.assertEquals(100,installments1[0].Amount);
		system.assertEquals(date.newinstance(1970,6,12),installments1[0].CloseDate);
		system.assertEquals(a.id,installments1[0].AccountId);
		system.assertEquals(100,installments1[1].Amount);
		system.assertEquals(date.newinstance(1970,6,19),installments1[1].CloseDate);
		system.assertEquals(a.id,installments1[1].AccountId);
	}
	
	static testMethod void insertQuarterlyOpportunities()
	{
		
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
		r1.Contact__c = c.Id;
		r1.Amount__c = 100;
		r1.Installment_Period__c = System.Label.RecurringDonationInstallmentPeriodQuarterly;
		r1.Date_Established__c = date.newinstance(1970,6,12);
		r1.Schedule_Type__c = System.Label.RecurringDonationMultiplyValue;
		insert r1;
		
		Opportunity[] installments1 = [select Name,amount,accountid,CloseDate from Opportunity where Recurring_Donation__c = :r1.id];
		system.assertEquals(2,installments1.size());
		system.assertEquals(100,installments1[0].Amount);
		system.assertEquals(date.newinstance(1970,6,12),installments1[0].CloseDate);
		system.assertEquals(a.id,installments1[0].AccountId);
		system.assertEquals(100,installments1[1].Amount);
		system.assertEquals(date.newinstance(1970,9,12),installments1[1].CloseDate);
		system.assertEquals(a.id,installments1[1].AccountId);
	}
	
	static testMethod void insertCampaignOpportunities()
	{
		
		Account a = new Account();
        a.Name = 'test Individual';
        insert a;
        
        Contact c = new Contact();
        c.FirstName = 'test';
        c.LastName = 'contact';
        c.AccountId = a.Id;
        insert c;		

		Campaign camp = new Campaign();
        camp.Name = 'test campaign';
        insert camp;
        
        Id campaignId = camp.id;

		Recurring_Donation__c r1 = new Recurring_Donation__c();
		r1.Name = 'test';
		r1.Installments__c = 2;
		r1.Contact__c = c.Id;
		r1.Amount__c = 100;
		r1.Installment_Period__c = System.Label.RecurringDonationInstallmentPeriodWeekly;
		r1.Date_Established__c = date.newinstance(1970,6,12);
		r1.Schedule_Type__c = System.Label.RecurringDonationMultiplyValue;
		r1.Recurring_Donation_Campaign__c = campaignId;
		insert r1;
		
		Opportunity[] installments1 = [select Name,amount,accountid,CloseDate,CampaignId from Opportunity where Recurring_Donation__c = :r1.id];
		system.assertEquals(2,installments1.size());
		system.assertEquals(100,installments1[0].Amount);
		system.assertEquals(date.newinstance(1970,6,12),installments1[0].CloseDate);
		system.assertEquals(campaignId,installments1[0].CampaignId);
		system.assertEquals(a.id,installments1[0].AccountId);
		system.assertEquals(100,installments1[1].Amount);
		system.assertEquals(date.newinstance(1970,6,19),installments1[1].CloseDate);
		system.assertEquals(campaignId,installments1[1].CampaignId);
		system.assertEquals(a.id,installments1[1].AccountId);
	}
	
	static testMethod void deleteRecurringDonation()
	{
		Account a = new Account();
        a.Name = 'test Individual';
        insert a;
        
		Recurring_Donation__c r2 = new Recurring_Donation__c();
		r2.Name = 'test';
		r2.Installments__c = 3;
		r2.Organization__c = a.Id;
		r2.Amount__c = 100;
		r2.Installment_Period__c = System.Label.RecurringDonationInstallmentPeriodMonthly;
		r2.Date_Established__c = date.newinstance(1970,6,12);
		r2.Schedule_Type__c = System.Label.RecurringDonationDivideValue;
		insert r2;
		
		Opportunity[] installments2 = [select Name,amount,accountid,CloseDate from Opportunity where Recurring_Donation__c = :r2.id];
		system.assertEquals(3,installments2.size());
		system.assertEquals(33.33,installments2[0].Amount);
		system.assertEquals(date.newinstance(1970,6,12),installments2[0].CloseDate);
		system.assertEquals(33.33,installments2[1].Amount);
		system.assertEquals(date.newinstance(1970,7,12),installments2[1].CloseDate);
		system.assertEquals(33.34,installments2[2].Amount);
		system.assertEquals(date.newinstance(1970,8,12),installments2[2].CloseDate);
		system.assertEquals(a.id,installments2[0].AccountId);
		system.debug(installments2);
		
		try{
			delete r2;
		} catch (exception e1) {}
		
		//delete should have failed
		Opportunity[] installments3 = [select amount from Opportunity where Recurring_Donation__c = :r2.id];
		system.assertEquals(3,installments3.size());
		system.assertEquals(33.33,installments3[0].Amount);
	}
	
	static testMethod void contactRolesOnOpps()
	{
		
		 Account a = new Account();
        a.Name = 'test Individual';
        insert a;
        
        Contact c = new Contact();
        c.FirstName = 'test';
        c.LastName = 'contact';
        c.AccountId = a.Id;
        insert c;		
		Test.startTest();
		Recurring_Donation__c r1 = new Recurring_Donation__c();
		r1.Name = 'test';
		r1.Installments__c = 2;
		r1.Contact__c = c.Id;
		r1.Amount__c = 100;
		r1.Installment_Period__c = System.Label.RecurringDonationInstallmentPeriodWeekly;
		r1.Date_Established__c = date.newinstance(1970,6,12);
		r1.Schedule_Type__c = System.Label.RecurringDonationMultiplyValue;
		insert r1;
		Test.stopTest();
		OpportunityContactRole[] installmentCRs = [select ContactId,OpportunityId,Role from OpportunityContactRole where Opportunity.Recurring_Donation__c = :r1.id];
		system.assertEquals(2,installmentCRs.size());
		system.assertEquals(System.Label.RecurringDonationContactRole,installmentCRs[0].Role);
	}
	
	
}