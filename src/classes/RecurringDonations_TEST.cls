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
* @description Test class for the RecurringDonations class
*/
@isTest
public class RecurringDonations_TEST {

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
        
        //added to cover
        Custom_Field_Mapping__c cfm = new Custom_Field_Mapping__c(
        Recurring_Donation_Field__c = 'Last_Payment_Date__c',
        Opportunity_Field__c = 'Description',
        Name = 'CFMName00001-Test'
        );
        insert cfm;

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
		r1.Open_Ended_Status__c = 'None'; 
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
		r1.Open_Ended_Status__c = 'None'; 
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
		r1.Open_Ended_Status__c = 'None'; 
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
        setRecurringDonationsSettingsForTest(new Recurring_Donations_Settings__c());	
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
		r1.Open_Ended_Status__c = 'None'; 
		insert r1;
		
		Opportunity[] installments1 = [select Name,amount,accountid,CloseDate,CampaignId from Opportunity where Recurring_Donation__c = :r1.id];
		system.assertEquals(2,installments1.size());
		system.assertEquals(100,installments1[0].Amount);
		system.assertEquals(date.newinstance(1970,6,12),installments1[0].CloseDate);
		system.assertEquals(campaignId,installments1[0].CampaignId);
		system.assertEquals(a.id,installments1[0].AccountId);
		system.assertEquals(100,installments1[1].Amount);
		system.assertEquals(date.newinstance(1970,6,19),installments1[1].CloseDate);
		system.assertEquals(campaignId,installments1[0].CampaignId);
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
		r2.Open_Ended_Status__c = 'None'; 
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
		RecurringDonations_ProcessControl.hasRun = false;
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
		r1.Open_Ended_Status__c = 'None'; 
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
	
	static testMethod void testSettingsCreation(){
		delete [select id from Recurring_Donations_Settings__c];
		Recurring_Donations_Settings__c rds = RecurringDonations.getRecurringDonationsSettings();
		system.assertEquals(12, rds.Opportunity_Forecast_Months__c);
		system.assertEquals(50, rds.Maximum_Donations__c);
		system.assertEquals(RecurringDonations.RecurringDonationCloseOptions.Mark_Opportunities_Closed_Lost.name(), rds.Open_Opportunity_Behavior__c);		     
	}
	
	
	//tests inserts of various types of open ended donations
	static testMethod void insertOpenEndedRecurringDonations(){
        RecurringDonations_TEST.setRecurringDonationsSettingsForTest(
        new Recurring_Donations_Settings__c(
        Opportunity_Forecast_Months__c = 12,
        Maximum_Donations__c = 50,
        Open_Opportunity_Behavior__c = RecurringDonations.RecurringDonationCloseOptions.Mark_Opportunities_Closed_Lost.name()        
        ));				
		
		Account a = new Account();
        a.Name = 'test Individual';
        insert a;
        
        Contact c = new Contact();
        c.FirstName = 'test';
        c.LastName = 'contact';
        c.AccountId = a.Id;
        insert c;       
        
        Campaign camp = new Campaign(name = 'Campaign', isActive = true);
        insert camp;
		
		list<Recurring_Donation__c> rdlist = new list<Recurring_Donation__c>();
		
		Recurring_Donation__c RD = new Recurring_Donation__c();
        RD.Name = 'testweekly';
        RD.Contact__c = c.Id;
        RD.Amount__c = 100;
        RD.Installment_Period__c = System.Label.RecurringDonationInstallmentPeriodWeekly;
        RD.Date_Established__c = date.newinstance(1970,6,12);
        RD.Schedule_Type__c = System.Label.RecurringDonationMultiplyValue;
        RD.Open_Ended_Status__c = System.label.RecurringDonationOpenStatus;
        RD.Next_Payment_Date__c = system.today();
        rdlist.add(RD);
        
        
        RD = RD.clone(false);
        RD.Name = 'testmonthly';
        RD.Installment_Period__c = System.Label.RecurringDonationInstallmentPeriodMonthly;
        RD.Contact__c = null;
        RD.Organization__c = a.id;
        RD.Recurring_Donation_Campaign__c = camp.id;
        rdlist.add(RD);
        
        RD = RD.clone(false);
        RD.Name = 'testquarterly';
        RD.Installment_Period__c = System.Label.RecurringDonationInstallmentPeriodQuarterly;
        rdlist.add(RD);
        
        RD = RD.clone(false);
        RD.Name = 'testyearly';
        RD.Installment_Period__c = System.Label.RecurringDonationInstallmentPeriodYearly;
        rdlist.add(RD);
        
        RD = RD.clone(false);
        RD.Name = 'testbadinstallment';
        RD.Installment_Period__c = 'GarbageValue';
        rdlist.add(RD);
        
        test.startTest();
        insert rdlist;
        test.stopTest();
        
        system.assertEquals(12, [select count() from Opportunity where Recurring_Donation__r.Name = 'testmonthly']);
        system.assertEquals(4, [select count() from Opportunity where Recurring_Donation__r.Name = 'testquarterly']);
        system.assertEquals(1, [select count() from Opportunity where Recurring_Donation__r.Name = 'testyearly']);
        system.assertEquals(53, [select count() from Opportunity where Recurring_Donation__r.Name = 'testweekly']);        
	}
	
	static testMethod void updateOpenEndedRecurringDonationMonthly(){
        RecurringDonations_TEST.setRecurringDonationsSettingsForTest(
        new Recurring_Donations_Settings__c(
        Opportunity_Forecast_Months__c = 12,
        Maximum_Donations__c = 50,
        Open_Opportunity_Behavior__c = RecurringDonations.RecurringDonationCloseOptions.Mark_Opportunities_Closed_Lost.name()        
        ));           
        
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
        r1.Open_Ended_Status__c = System.label.RecurringDonationOpenStatus;
        r1.Next_Payment_Date__c = system.today();
        insert r1;
        
        map<id, Opportunity> originalOpps = new map<id, Opportunity>([select id, Name,amount,accountid,CloseDate from Opportunity where Recurring_Donation__c = :r1.id]);          
        
        system.assertEquals(53, originalOpps.size());
        system.assertEquals(100, originalOpps.values()[0].Amount);
		RecurringDonations_ProcessControl.hasRun = false;
		Test.startTest();
		r1.Installment_Period__c = System.Label.RecurringDonationInstallmentPeriodMonthly;
		update r1;
		Test.stopTest();
		
		system.assertEquals(12, [select count() from Opportunity where Recurring_Donation__c = :r1.id]);		
	}
	static testMethod void updateOpenEndedRecurringDonation1an15(){
		    RecurringDonations_TEST.setRecurringDonationsSettingsForTest(
        new Recurring_Donations_Settings__c(
        Opportunity_Forecast_Months__c = 12,
        Maximum_Donations__c = 50,
        Open_Opportunity_Behavior__c = RecurringDonations.RecurringDonationCloseOptions.Mark_Opportunities_Closed_Lost.name(),
        Add_Campaign_to_All_Opportunites__c = true        
        ));           
        
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
        r1.Installment_Period__c = System.Label.RecurringDonationInstallmentPeriod1stand15th;
        r1.Date_Established__c = date.newinstance(1970,6,12);
        r1.Schedule_Type__c = System.Label.RecurringDonationMultiplyValue;
        r1.Open_Ended_Status__c = System.label.RecurringDonationOpenStatus;
        r1.Next_Payment_Date__c = system.today();
       
        RecurringDonations_ProcessControl.hasRun = false;
        Test.startTest();
        insert r1;
        Test.stopTest();
        map<id, Opportunity> originalOpps = new map<id, Opportunity>([select id, Name,amount,accountid,CloseDate from Opportunity where Recurring_Donation__c = :r1.id]);          
        system.assertEquals(25, originalOpps.size());
        system.assertEquals(100, originalOpps.values()[0].Amount);        
	}
	
	static testMethod void updateOpenEndedRecurringDonationYearly(){
        RecurringDonations_TEST.setRecurringDonationsSettingsForTest(
        new Recurring_Donations_Settings__c(
        Opportunity_Forecast_Months__c = 12,
        Maximum_Donations__c = 50,
        Open_Opportunity_Behavior__c = RecurringDonations.RecurringDonationCloseOptions.Mark_Opportunities_Closed_Lost.name()        
        ));           
        
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
        r1.Open_Ended_Status__c = System.label.RecurringDonationOpenStatus;
        r1.Next_Payment_Date__c = system.today();
        insert r1;
        
        map<id, Opportunity> originalOpps = new map<id, Opportunity>([select id, Name,amount,accountid,CloseDate from Opportunity where Recurring_Donation__c = :r1.id]);          
        
        system.assertEquals(53, originalOpps.size());
        system.assertEquals(100, originalOpps.values()[0].Amount);
        RecurringDonations_ProcessControl.hasRun = false;
        Test.startTest();
        r1.Installment_Period__c = System.Label.RecurringDonationInstallmentPeriodYearly;
        update r1;
        Test.stopTest();
        
        system.assertEquals(1, [select count() from Opportunity where Recurring_Donation__c = :r1.id]);
    }
    static testMethod void updateOpenEndedRecurringDonationWeekly(){
            RecurringDonations_TEST.setRecurringDonationsSettingsForTest(
        new Recurring_Donations_Settings__c(
        Opportunity_Forecast_Months__c = 12,
        Maximum_Donations__c = 50,
        Open_Opportunity_Behavior__c = RecurringDonations.RecurringDonationCloseOptions.Mark_Opportunities_Closed_Lost.name()        
        ));           
        
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
        r1.Installment_Period__c = System.Label.RecurringDonationInstallmentPeriodMonthly;
        r1.Date_Established__c = date.newinstance(1970,6,12);
        r1.Schedule_Type__c = System.Label.RecurringDonationMultiplyValue;
        r1.Open_Ended_Status__c = System.label.RecurringDonationOpenStatus;
        r1.Next_Payment_Date__c = system.today();
        insert r1;
        
        map<id, Opportunity> originalOpps = new map<id, Opportunity>([select id, Name,amount,accountid,CloseDate from Opportunity where Recurring_Donation__c = :r1.id]);          
        
        system.assertEquals(12, originalOpps.size());
        system.assertEquals(100, originalOpps.values()[0].Amount);
        RecurringDonations_ProcessControl.hasRun = false;
        Test.startTest();
        r1.Installment_Period__c = System.Label.RecurringDonationInstallmentPeriodWeekly;
        update r1;
        Test.stopTest();        
        system.assertEquals(53, [select count() from Opportunity where Recurring_Donation__c = :r1.id]);
    }
    
    static testMethod void updateOpenEndedRecurringDonationQuarterly(){
        RecurringDonations_TEST.setRecurringDonationsSettingsForTest(
        new Recurring_Donations_Settings__c(
        Opportunity_Forecast_Months__c = 12,
        Maximum_Donations__c = 50,
        Open_Opportunity_Behavior__c = RecurringDonations.RecurringDonationCloseOptions.Mark_Opportunities_Closed_Lost.name()        
        ));           
        
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
        r1.Open_Ended_Status__c = System.label.RecurringDonationOpenStatus;
        r1.Next_Payment_Date__c = system.today();
        insert r1;
        
        map<id, Opportunity> originalOpps = new map<id, Opportunity>([select id, Name,amount,accountid,CloseDate from Opportunity where Recurring_Donation__c = :r1.id]);          
        
        system.assertEquals(53, originalOpps.size());
        system.assertEquals(100, originalOpps.values()[0].Amount);
        RecurringDonations_ProcessControl.hasRun = false;
        Test.startTest();
        r1.Installment_Period__c = System.Label.RecurringDonationInstallmentPeriodQuarterly;
        update r1;
        Test.stopTest();
        
        system.assertEquals(4, [select count() from Opportunity where Recurring_Donation__c = :r1.id]);
    }    
    	
	//test closing an opportunity for an open recurring donation
	static testMethod void closeOppForOpenEndedRecurringDonationWeekly(){
        RecurringDonations_TEST.setRecurringDonationsSettingsForTest(
        new Recurring_Donations_Settings__c(
        Opportunity_Forecast_Months__c = 12,
        Maximum_Donations__c = 50,
        Open_Opportunity_Behavior__c = RecurringDonations.RecurringDonationCloseOptions.Mark_Opportunities_Closed_Lost.name()        
        ));           
        
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
        r1.Open_Ended_Status__c = System.label.RecurringDonationOpenStatus;
        r1.Next_Payment_Date__c = system.today();
        insert r1;
        
        map<id, Opportunity> originalOpps = new map<id, Opportunity>([select id, Name,amount,accountid,CloseDate from Opportunity where Recurring_Donation__c = :r1.id]);
        system.assertEquals(53, originalOpps.size());          
        
        Opportunity o = originalOpps.values()[0];
        string closedstage = [select masterlabel from opportunitystage where isActive = true and iswon = true and isClosed = true limit 1].masterlabel;
        o.StageName = closedstage;
        o.CloseDate = system.today();
        RecurringDonations_ProcessControl.hasRun = false;
        Test.startTest();        
        //update opp
        update o;
        //call the update method
        RecurringDonations.evaluateRecurringDonationsForNewOppInsert(new list<Recurring_Donation__c>{r1});
        Test.stopTest();        
        
        Recurring_Donation__c rd = [select Last_Payment_Date__c from Recurring_Donation__c where id = :r1.id];     
        
        system.assert([select count() from Opportunity where Recurring_Donation__c = :r1.id and isClosed = false] > 51);
        system.assert([select count() from Opportunity where Recurring_Donation__c = :r1.id and isClosed = false] < 54);
        system.assertEquals(system.today(), rd.Last_Payment_Date__c);
	}
	//test closing an opportunity for an open recurring donation
    static testMethod void closeOppForOpenEndedRecurringDonationMonthly(){
        RecurringDonations_TEST.setRecurringDonationsSettingsForTest(
        new Recurring_Donations_Settings__c(
        Opportunity_Forecast_Months__c = 6,
        Maximum_Donations__c = 50,
        Open_Opportunity_Behavior__c = RecurringDonations.RecurringDonationCloseOptions.Mark_Opportunities_Closed_Lost.name()        
        ));           
        
        Account a = new Account();
        a.Name = 'test Individual';
        insert a;
        
        Contact c = new Contact();
        c.FirstName = 'test';
        c.LastName = 'contact';
        c.AccountId = a.Id;
        insert c;       

        list<Recurring_Donation__c> rdlist = new list<Recurring_Donation__c>();
        Recurring_Donation__c r1 = new Recurring_Donation__c();
        r1.Name = 'test';
        r1.Installments__c = 2;
        r1.Contact__c = c.Id;
        r1.Amount__c = 100;
        r1.Installment_Period__c = System.Label.RecurringDonationInstallmentPeriodYearly;
        r1.Date_Established__c = date.newinstance(1970,6,12);
        r1.Schedule_Type__c = System.Label.RecurringDonationMultiplyValue;
        r1.Open_Ended_Status__c = System.label.RecurringDonationOpenStatus;
        r1.Next_Payment_Date__c = system.today();
        rdlist.add(r1);
        insert rdlist; 
        
        system.assertNotEquals(null, r1.id);
        map<id, Opportunity> originalOpps = new map<id, Opportunity>([select id, Name,amount,accountid,CloseDate from Opportunity where Recurring_Donation__r.id = :r1.id]);
        system.assertEquals(1, originalOpps.size());          
        
        Opportunity o1 = originalOpps.values()[0];
        string closedstage = [select masterlabel from opportunitystage where isActive = true and iswon = true and isClosed = true limit 1].masterlabel;
        o1.StageName = closedstage;
        o1.CloseDate = system.today();
        list<Opportunity> oppList = new list<Opportunity>{o1};
        RecurringDonations_ProcessControl.hasRun = false;
        Test.startTest();        
        //update opp
        update oppList;
        //call the update method
        RecurringDonations.evaluateRecurringDonationsForNewOppInsert(new list<Recurring_Donation__c>{r1});
        Test.stopTest();
        Recurring_Donation__c rd = [select Last_Payment_Date__c from Recurring_Donation__c where id = :r1.id];     
        system.assertEquals(system.today(), rd.Last_Payment_Date__c);
    }
	
	//test closing an opportunity for an open recurring donation
    static testMethod void closeOppForOpenEndedRecurringDonationQuarterly(){
        RecurringDonations_TEST.setRecurringDonationsSettingsForTest(
        new Recurring_Donations_Settings__c(
        Opportunity_Forecast_Months__c = 12,
        Maximum_Donations__c = 50,
        Open_Opportunity_Behavior__c = RecurringDonations.RecurringDonationCloseOptions.Mark_Opportunities_Closed_Lost.name()        
        ));           
        
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
        r1.Open_Ended_Status__c = System.label.RecurringDonationOpenStatus;
        r1.Next_Payment_Date__c = system.today();
        insert r1;
        
        map<id, Opportunity> originalOpps = new map<id, Opportunity>([select id, Name,amount,accountid,CloseDate from Opportunity where Recurring_Donation__c = :r1.id]);
        system.assertEquals(4, originalOpps.size());          
        
        Opportunity o = originalOpps.values()[0];
        string closedstage = [select masterlabel from opportunitystage where isActive = true and iswon = true and isClosed = true limit 1].masterlabel;
        o.StageName = closedstage;
        o.CloseDate = system.today();
        RecurringDonations_ProcessControl.hasRun = false;
        Test.startTest();        
        //update opp
        update o;
        //call the update method
        RecurringDonations.evaluateRecurringDonationsForNewOppInsert(new list<Recurring_Donation__c>{r1});
        Test.stopTest();
                
        Recurring_Donation__c rd = [select Last_Payment_Date__c from Recurring_Donation__c where id = :r1.id];     
        system.assertEquals(system.today(), rd.Last_Payment_Date__c);
        system.assert([select count() from Opportunity where Recurring_Donation__c = :r1.id and isClosed = false] > 2);
        system.assert([select count() from Opportunity where Recurring_Donation__c = :r1.id and isClosed = false] < 5);        
    }
    
    //test closing an opportunity for an open recurring donation
    static testMethod void closeOppForOpenEndedRecurringDonationCustomWeeks(){
        RecurringDonations_TEST.setRecurringDonationsSettingsForTest(
        new Recurring_Donations_Settings__c(
        Opportunity_Forecast_Months__c = 12,
        Maximum_Donations__c = 50,
        Open_Opportunity_Behavior__c = RecurringDonations.RecurringDonationCloseOptions.Mark_Opportunities_Closed_Lost.name()        
        ));           
        
        Account a = new Account();
        a.Name = 'test Individual';
        insert a;
        
        Contact c = new Contact();
        c.FirstName = 'test';
        c.LastName = 'contact';
        c.AccountId = a.Id;
        insert c;       

        Custom_Installment_Settings__c cis = new Custom_Installment_Settings__c(
        Increment__c = 'Weeks',
        Value__c = 2,
        Name = 'TESTCIS'        
        );
        insert cis;        

        Recurring_Donation__c r1 = new Recurring_Donation__c();
        r1.Name = 'test';
        r1.Installments__c = 2;
        r1.Organization__c = a.id;
        r1.Amount__c = 100;
        r1.Installment_Period__c = 'TESTCIS';
        r1.Date_Established__c = date.newinstance(1970,6,12);
        r1.Schedule_Type__c = System.Label.RecurringDonationMultiplyValue;
        r1.Open_Ended_Status__c = System.label.RecurringDonationOpenStatus;
        r1.Next_Payment_Date__c = system.today();
        insert r1;
        
        map<id, Opportunity> originalOpps = new map<id, Opportunity>([select id, Name,amount,accountid,CloseDate from Opportunity where Recurring_Donation__c = :r1.id]);
        system.assertEquals(27, originalOpps.size());          
        
        Opportunity o = originalOpps.values()[0];
        string closedstage = [select masterlabel from opportunitystage where isActive = true and iswon = true and isClosed = true limit 1].masterlabel;
        o.StageName = closedstage;
        o.CloseDate = system.today();
        RecurringDonations_ProcessControl.hasRun = false;
        Test.startTest();        
        //update opp
        update o;
        //call the update method
        RecurringDonations.evaluateRecurringDonationsForNewOppInsert(new list<Recurring_Donation__c>{r1});
        Test.stopTest();        
        
        Recurring_Donation__c rd = [select Last_Payment_Date__c from Recurring_Donation__c where id = :r1.id];     
        
        system.assert([select count() from Opportunity where Recurring_Donation__c = :r1.id and isClosed = false] > 25);
        system.assert([select count() from Opportunity where Recurring_Donation__c = :r1.id and isClosed = false] < 28);
        system.assertEquals(system.today(), rd.Last_Payment_Date__c);
    }
    
    
       //test closing an opportunity for an open recurring donation
    static testMethod void closeOppForOpenEndedRecurringDonationCustomDays(){
        RecurringDonations_TEST.setRecurringDonationsSettingsForTest(
        new Recurring_Donations_Settings__c(
        Opportunity_Forecast_Months__c = 1,
        Maximum_Donations__c = 50,
        Open_Opportunity_Behavior__c = RecurringDonations.RecurringDonationCloseOptions.Mark_Opportunities_Closed_Lost.name()        
        ));           
        
        Account a = new Account();
        a.Name = 'test Individual';
        insert a;
        
        Contact c = new Contact();
        c.FirstName = 'test';
        c.LastName = 'contact';
        c.AccountId = a.Id;
        insert c;       

        Custom_Installment_Settings__c cis = new Custom_Installment_Settings__c(
        Increment__c = 'Days',
        Value__c = 2,
        Name = 'TESTCIS'        
        );
        insert cis;        

        Recurring_Donation__c r1 = new Recurring_Donation__c();
        r1.Name = 'test';
        r1.Installments__c = 2;
        r1.Organization__c = a.id;
        r1.Amount__c = 100;
        r1.Installment_Period__c = 'TESTCIS';
        r1.Date_Established__c = date.newinstance(1970,6,12);
        r1.Schedule_Type__c = System.Label.RecurringDonationMultiplyValue;
        r1.Open_Ended_Status__c = System.label.RecurringDonationOpenStatus;
        r1.Next_Payment_Date__c = system.today();
        insert r1;
        
        map<id, Opportunity> originalOpps = new map<id, Opportunity>([select id, Name,amount,accountid,CloseDate from Opportunity where Recurring_Donation__c = :r1.id]);

        integer nbops = originalOpps.size();
		//we create one month of donations every other day. month may be from 28-31 days so number created may vary
        system.assert(nbops == 14 || nbops == 15 || nbops ==16);          
        
        Opportunity o = originalOpps.values()[0];
        string closedstage = [select masterlabel from opportunitystage where isActive = true and iswon = true and isClosed = true limit 1].masterlabel;
        o.StageName = closedstage;
        o.CloseDate = system.today();
        RecurringDonations_ProcessControl.hasRun = false;
        Test.startTest();        
        //update opp
        update o;
        //call the update method        
        Test.stopTest();        
        
        Recurring_Donation__c rd = [select Last_Payment_Date__c from Recurring_Donation__c where id = :r1.id];     
        
        system.assertEquals(nbops-1, [select count() from Opportunity where Recurring_Donation__c = :r1.id and isClosed = false]);
        system.assertEquals(system.today(), rd.Last_Payment_Date__c);
    }
    
    
       //test closing an opportunity for an open recurring donation
    static testMethod void closeOppForOpenEndedRecurringDonationCustomMonths(){
        RecurringDonations_TEST.setRecurringDonationsSettingsForTest(
        new Recurring_Donations_Settings__c(
        Opportunity_Forecast_Months__c = 12,
        Maximum_Donations__c = 50,
        Open_Opportunity_Behavior__c = RecurringDonations.RecurringDonationCloseOptions.Mark_Opportunities_Closed_Lost.name(),
        Add_Campaign_to_All_Opportunites__c = true        
        ));           
        
        Account a = new Account();
        a.Name = 'test Individual';
        insert a;
        
        Contact c = new Contact();
        c.FirstName = 'test';
        c.LastName = 'contact';
        c.AccountId = a.Id;
        insert c;       

        Custom_Installment_Settings__c cis = new Custom_Installment_Settings__c(
        Increment__c = 'Months',
        Value__c = 2,
        Name = 'TESTCIS'        
        );
        insert cis;        

        Recurring_Donation__c r1 = new Recurring_Donation__c();
        r1.Name = 'test';
        r1.Installments__c = 2;
        r1.Organization__c = a.id;
        r1.Amount__c = 100;
        r1.Installment_Period__c = 'TESTCIS';
        r1.Date_Established__c = date.newinstance(1970,6,12);
        r1.Schedule_Type__c = System.Label.RecurringDonationMultiplyValue;
        r1.Open_Ended_Status__c = System.label.RecurringDonationOpenStatus;
        r1.Next_Payment_Date__c = system.today();
        insert r1;
        
        map<id, Opportunity> originalOpps = new map<id, Opportunity>([select id, Name,amount,accountid,CloseDate from Opportunity where Recurring_Donation__c = :r1.id]);
        system.assertEquals(6, originalOpps.size());          
        
        Opportunity o = originalOpps.values()[0];
        string closedstage = [select masterlabel from opportunitystage where isActive = true and iswon = true and isClosed = true limit 1].masterlabel;
        o.StageName = closedstage;
        o.CloseDate = system.today();
        RecurringDonations_ProcessControl.hasRun = false;
        Test.startTest();        
        //update opp
        update o;
        //call the update method
        RecurringDonations.evaluateRecurringDonationsForNewOppInsert(new list<Recurring_Donation__c>{r1});
        Test.stopTest();        
        
        Recurring_Donation__c rd = [select Last_Payment_Date__c from Recurring_Donation__c where id = :r1.id];     
        
        system.assert([select count() from Opportunity where Recurring_Donation__c = :r1.id and isClosed = false] > 4);
        system.assert([select count() from Opportunity where Recurring_Donation__c = :r1.id and isClosed = false] < 7);
        system.assertEquals(system.today(), rd.Last_Payment_Date__c);
    }
       //test closing an opportunity for an open recurring donation
    static testMethod void closeOppForOpenEndedRecurringDonationCustomYears(){
        RecurringDonations_TEST.setRecurringDonationsSettingsForTest(
        new Recurring_Donations_Settings__c(
        Opportunity_Forecast_Months__c = 12,
        Maximum_Donations__c = 50,
        Open_Opportunity_Behavior__c = RecurringDonations.RecurringDonationCloseOptions.Mark_Opportunities_Closed_Lost.name(),
        Add_Campaign_to_All_Opportunites__c = true       
        ));           
        
        Account a = new Account();
        a.Name = 'test Individual';
        insert a;
        
        Contact c = new Contact();
        c.FirstName = 'test';
        c.LastName = 'contact';
        c.AccountId = a.Id;
        insert c;       

        Custom_Installment_Settings__c cis = new Custom_Installment_Settings__c(
        Increment__c = 'Years',
        Value__c = 2,
        Name = 'TESTCIS'        
        );
        insert cis;        

        Recurring_Donation__c r1 = new Recurring_Donation__c();
        r1.Name = 'test';
        r1.Installments__c = 2;
        r1.Organization__c = a.id;
        r1.Amount__c = 100;
        r1.Installment_Period__c = 'TESTCIS';
        r1.Date_Established__c = date.newinstance(1970,6,12);
        r1.Schedule_Type__c = System.Label.RecurringDonationMultiplyValue;
        r1.Open_Ended_Status__c = System.label.RecurringDonationOpenStatus;
        r1.Next_Payment_Date__c = system.today();
        insert r1;
        
        map<id, Opportunity> originalOpps = new map<id, Opportunity>([select id, Name,amount,accountid,CloseDate from Opportunity where Recurring_Donation__c = :r1.id]);
        system.assertEquals(1, originalOpps.size());          
        
        Opportunity o = originalOpps.values()[0];
        string closedstage = [select masterlabel from opportunitystage where isActive = true and iswon = true and isClosed = true limit 1].masterlabel;
        o.StageName = closedstage;
        o.CloseDate = system.today();
        RecurringDonations_ProcessControl.hasRun = false;
        Test.startTest();        
        //update opp
        update o;
        //call the update method
        RecurringDonations.evaluateRecurringDonationsForNewOppInsert(new list<Recurring_Donation__c>{r1});
        Test.stopTest();        
        
        Recurring_Donation__c rd = [select Last_Payment_Date__c from Recurring_Donation__c where id = :r1.id];     
        
        system.assert([select count() from Opportunity where Recurring_Donation__c = :r1.id and isClosed = false] < 2);        
        system.assertEquals(system.today(), rd.Last_Payment_Date__c);
    }
    
    //test closing an opportunity for an open recurring donation
    static testMethod void closeOppForOpenEndedRecurringDonationYearly(){
        RecurringDonations_TEST.setRecurringDonationsSettingsForTest(
        new Recurring_Donations_Settings__c(
        Opportunity_Forecast_Months__c = 12,
        Maximum_Donations__c = 50,
        Open_Opportunity_Behavior__c = RecurringDonations.RecurringDonationCloseOptions.Mark_Opportunities_Closed_Lost.name()        
        ));           
        
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
        r1.Organization__c = a.id;
        r1.Amount__c = 100;
        r1.Installment_Period__c = System.Label.RecurringDonationInstallmentPeriodYearly;
        r1.Date_Established__c = date.newinstance(1970,6,12);
        r1.Schedule_Type__c = System.Label.RecurringDonationMultiplyValue;
        r1.Open_Ended_Status__c = System.label.RecurringDonationOpenStatus;
        r1.Next_Payment_Date__c = system.today();
        insert r1;
        
        map<id, Opportunity> originalOpps = new map<id, Opportunity>([select id, Name,amount,accountid,CloseDate from Opportunity where Recurring_Donation__c = :r1.id]);
        system.assertEquals(1, originalOpps.size());          
        
        Opportunity o = originalOpps.values()[0];
        string closedstage = [select masterlabel from opportunitystage where isActive = true and iswon = true and isClosed = true limit 1].masterlabel;
        o.StageName = closedstage;
        o.CloseDate = system.today();
        RecurringDonations_ProcessControl.hasRun = false;
        Test.startTest();        
        //update opp
        update o;
        //call the update method
        RecurringDonations.evaluateRecurringDonationsForNewOppInsert(new list<Recurring_Donation__c>{r1});
        Test.stopTest();
        
        
        Recurring_Donation__c rd = [select Last_Payment_Date__c from Recurring_Donation__c where id = :r1.id];     
        
        system.assert([select count() from Opportunity where Recurring_Donation__c = :r1.id and isClosed = false] < 2);
        system.assertEquals(system.today(), rd.Last_Payment_Date__c);
    }
	
	static testMethod void closeOpenEndedRecurringDonationMarkOppsClosedLost(){
		RecurringDonations_TEST.setRecurringDonationsSettingsForTest(
        new Recurring_Donations_Settings__c(
        Opportunity_Forecast_Months__c = 12,
        Maximum_Donations__c = 50,
        Open_Opportunity_Behavior__c = RecurringDonations.RecurringDonationCloseOptions.Mark_Opportunities_Closed_Lost.name()        
        ));           
        
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
        r1.Open_Ended_Status__c = System.label.RecurringDonationOpenStatus;
        r1.Next_Payment_Date__c = system.today();
        insert r1;
        
        map<id, Opportunity> originalOpps = new map<id, Opportunity>([select id, Name,amount,accountid,CloseDate from Opportunity where Recurring_Donation__c = :r1.id]);
        system.assertEquals(53, originalOpps.size());     
        RecurringDonations_ProcessControl.hasRun = false;
        Test.startTest();
        r1.Open_Ended_Status__c = System.label.RecurringDonationClosedStatus;
        update r1;
		Test.stopTest();
		
		//assert all previously open opps are marked closed lost
		system.assertEquals(53, [select count() from Opportunity where isClosed = true and isWon = false and Recurring_Donation__c = :r1.id]);
		
	}
	
	static testMethod void updateRecurringDonationWithClosedOpp(){
        RecurringDonations_TEST.setRecurringDonationsSettingsForTest(
        new Recurring_Donations_Settings__c(
        Opportunity_Forecast_Months__c = 12,
        Maximum_Donations__c = 50, 
        Open_Opportunity_Behavior__c = RecurringDonations.RecurringDonationCloseOptions.Mark_Opportunities_Closed_Lost.name()        
        ));           
        
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
        r1.Open_Ended_Status__c = System.label.RecurringDonationOpenStatus;
        r1.Next_Payment_Date__c = system.today();
        insert r1;
        
        map<id, Opportunity> originalOpps = new map<id, Opportunity>([select id, Name,amount,accountid,CloseDate from Opportunity where Recurring_Donation__c = :r1.id]);
        Opportunity o = originalOpps.values()[0];
        string closedstage = [select masterlabel from opportunitystage where isActive = true and iswon = true and isClosed = true limit 1].masterlabel;
        o.StageName = closedstage;
        o.CloseDate = system.today();
        update o;
        
        //fake the last payment date close operation
        r1.Last_Payment_Date__c = system.today();
        update r1;
        RecurringDonations_ProcessControl.hasRun = false;                
        Test.startTest();        
        r1.Installment_Period__c = System.Label.RecurringDonationInstallmentPeriodYearly;
        update r1;
        Test.stopTest();        
        
        Recurring_Donation__c rd = [select Last_Payment_Date__c from Recurring_Donation__c where id = :r1.id];     
        
        system.assertEquals(1, [select count() from Opportunity where Recurring_Donation__c = :r1.id and isClosed = false]);
        system.assertEquals(system.today(), rd.Last_Payment_Date__c);
	}
	
	//test closing an opportunity for an open recurring donation
    static testMethod void closeOppForOpenEndedRecurringDonationBadRecurrance(){
        RecurringDonations_TEST.setRecurringDonationsSettingsForTest(
        new Recurring_Donations_Settings__c(
        Opportunity_Forecast_Months__c = 12,
        Maximum_Donations__c = 50,
        Open_Opportunity_Behavior__c = RecurringDonations.RecurringDonationCloseOptions.Mark_Opportunities_Closed_Lost.name()        
        ));           
        
        Account a = new Account();
        a.Name = 'test Individual';
        insert a;
        
        Contact c = new Contact();
        c.FirstName = 'test';
        c.LastName = 'contact';
        c.AccountId = a.Id;
        insert c;       
        
        Campaign camp = new Campaign(Name = 'MyTestCamp', isActive = true);
        insert camp;

        Recurring_Donation__c r1 = new Recurring_Donation__c();
        r1.Name = 'test';
        r1.Installments__c = 2;
        r1.Organization__c = a.id;
        r1.Amount__c = 100;
        r1.Recurring_Donation_Campaign__c = camp.id;
        r1.Installment_Period__c = System.Label.RecurringDonationInstallmentPeriodYearly;
        r1.Date_Established__c = date.newinstance(1970,6,12);
        r1.Schedule_Type__c = System.Label.RecurringDonationMultiplyValue;
        r1.Open_Ended_Status__c = System.label.RecurringDonationOpenStatus;
        r1.Next_Payment_Date__c = system.today();
        insert r1;
        
        map<id, Opportunity> originalOpps = new map<id, Opportunity>([select id, Name,amount,accountid,CloseDate from Opportunity where Recurring_Donation__c = :r1.id]);
        Opportunity o = originalOpps.values()[0];
        string closedstage = [select masterlabel from opportunitystage where isActive = true and iswon = true and isClosed = true limit 1].masterlabel;
        o.StageName = closedstage;
        o.CloseDate = system.today();
        r1.Installment_Period__c = 'GarbageDate';
        update r1;
        RecurringDonations_ProcessControl.hasRun = false;
        Test.startTest();        
        update o;
        Test.stopTest();
    }
	
	   //test closing an opportunity for an open recurring donation
    static testMethod void closeRecurringDonationDeleteOpps(){
        RecurringDonations_TEST.setRecurringDonationsSettingsForTest(
        new Recurring_Donations_Settings__c(
        Opportunity_Forecast_Months__c = 12,
        Maximum_Donations__c = 50,
        Open_Opportunity_Behavior__c = RecurringDonations.RecurringDonationCloseOptions.Delete_Open_Opportunities.name()        
        ));           
        
        Account a = new Account();
        a.Name = 'test Individual';
        insert a;
        
        Contact c = new Contact();
        c.FirstName = 'test';
        c.LastName = 'contact';
        c.AccountId = a.Id;
        insert c;       
        
        Campaign camp = new Campaign(Name = 'MyTestCamp', isActive = true);
        insert camp;

        Recurring_Donation__c r1 = new Recurring_Donation__c();
        r1.Name = 'test';
        r1.Installments__c = 2;
        r1.Organization__c = a.id;
        r1.Amount__c = 100;
        r1.Recurring_Donation_Campaign__c = camp.id;
        r1.Installment_Period__c = System.Label.RecurringDonationInstallmentPeriodYearly;
        r1.Date_Established__c = date.newinstance(1970,6,12);
        r1.Schedule_Type__c = System.Label.RecurringDonationMultiplyValue;
        r1.Open_Ended_Status__c = System.label.RecurringDonationOpenStatus;
        r1.Next_Payment_Date__c = system.today();
        insert r1;
        
        system.assertNotEquals(0, [select count() from Opportunity where Recurring_Donation__c = :r1.id and isClosed = false]);
        //reset the semaphore
        RecurringDonations_ProcessControl.hasRun = false;
        Test.startTest();        
        r1.Open_Ended_Status__c = system.label.RecurringDonationClosedStatus;
        update r1;
        Test.stopTest();
        
        //there should be no open donations
        system.assertEquals(0, [select count() from Opportunity where Recurring_Donation__c = :r1.id and isClosed = false]);        
    }
	
	static testMethod void multipleRDInsert(){
		RecurringDonations_TEST.setRecurringDonationsSettingsForTest(
        new Recurring_Donations_Settings__c(
        Opportunity_Forecast_Months__c = 6,
        Maximum_Donations__c = 50,
        Open_Opportunity_Behavior__c = RecurringDonations.RecurringDonationCloseOptions.Mark_Opportunities_Closed_Lost.name()        
        ));           
        
        delete [select id from Custom_Field_Mapping__c];
        Custom_Field_Mapping__c cfm1 = new Custom_Field_Mapping__c(
        Recurring_Donation_Field__c = 'Name',
        Opportunity_Field__c = 'Description',
        Name = 'CFMName00001-Test'
        );
        insert cfm1;
        
        Account a = new Account();
        a.Name = 'test Individual';
        insert a;
        
        Contact c = new Contact();
        c.FirstName = 'test';
        c.LastName = 'contact';
        c.AccountId = a.Id;
        insert c;       

        list<Recurring_Donation__c> rdlist = new list<Recurring_Donation__c>();
        Recurring_Donation__c r1 = new Recurring_Donation__c();
        r1.Name = 'test';
        r1.Installments__c = 2;
        r1.Contact__c = c.Id;
        r1.Amount__c = 100;
        r1.Installment_Period__c = System.Label.RecurringDonationInstallmentPeriodYearly;
        r1.Date_Established__c = date.newinstance(1970,6,12);
        r1.Schedule_Type__c = System.Label.RecurringDonationMultiplyValue;
        r1.Open_Ended_Status__c = System.label.RecurringDonationOpenStatus;
        r1.Next_Payment_Date__c = system.today();
        rdlist.add(r1);
                
        Recurring_Donation__c r2 = new Recurring_Donation__c();
        r2.Name = 'test';
        r2.Installments__c = 2;
        r2.Contact__c = c.Id;
        r2.Amount__c = 100;
        r2.Installment_Period__c = System.Label.RecurringDonationInstallmentPeriodMonthly;
        r2.Date_Established__c = date.newinstance(1970,6,12);
        r2.Schedule_Type__c = System.Label.RecurringDonationMultiplyValue;
        r2.Open_Ended_Status__c = System.label.RecurringDonationOpenStatus;
        r2.Next_Payment_Date__c = system.today();
        rdlist.add(r2);
                                        
        Test.startTest();
        insert rdlist;
        rdlist[0].Amount__c = 50;
        rdlist[1].Amount__c = 50;
        rdlist[1].Next_Payment_Date__c = system.today().addDays(5);
        RecurringDonations_ProcessControl.hasRun = false;
        update rdlist;        
        Test.stopTest();
        
        map<id, Opportunity> originalOpps = new map<id, Opportunity>([select id, Name,amount,accountid,CloseDate from Opportunity where Recurring_Donation__r.id = :r1.id or Recurring_Donation__c = :r2.id]);
        system.assertEquals(7, originalOpps.size());
        system.assertEquals(50, originalOpps.values()[0].Amount);
	}
	static testMethod void tooManyInstallments(){
        RecurringDonations_TEST.setRecurringDonationsSettingsForTest(
        new Recurring_Donations_Settings__c(
        Opportunity_Forecast_Months__c = 6,
        Maximum_Donations__c = 2,
        Open_Opportunity_Behavior__c = RecurringDonations.RecurringDonationCloseOptions.Mark_Opportunities_Closed_Lost.name()        
        ));           
        
        Account a = new Account();
        a.Name = 'test Individual';
        insert a;
        
        Contact c = new Contact();
        c.FirstName = 'test';
        c.LastName = 'contact';
        c.AccountId = a.Id;
        insert c;       

        list<Recurring_Donation__c> rdlist = new list<Recurring_Donation__c>();
        Recurring_Donation__c r1 = new Recurring_Donation__c();
        r1.Name = 'test';
        r1.Installments__c = 50;
        r1.Contact__c = c.Id;
        r1.Amount__c = 100;
        r1.Installment_Period__c = System.Label.RecurringDonationInstallmentPeriodYearly;
        r1.Date_Established__c = date.newinstance(1970,6,12);
        r1.Schedule_Type__c = System.Label.RecurringDonationMultiplyValue;
        r1.Open_Ended_Status__c = 'None';
        r1.Next_Payment_Date__c = system.today();
        try{
            insert r1;
        }
        catch (exception e){}
        //insert should fail because of too many installments
        system.assertEquals(null,r1.id);
    }
    static testmethod void updateOppsFromMultipleRDs(){
    	RecurringDonations_TEST.setRecurringDonationsSettingsForTest(
        new Recurring_Donations_Settings__c(
        Opportunity_Forecast_Months__c = 6,
        Maximum_Donations__c = 50,
        Open_Opportunity_Behavior__c = RecurringDonations.RecurringDonationCloseOptions.Mark_Opportunities_Closed_Lost.name()        
        ));           
        
        //remove any existing custom field mappings
        delete [select id from Custom_Field_Mapping__c];        
        Custom_Field_Mapping__c cfm = new Custom_Field_Mapping__c(
        Recurring_Donation_Field__c = 'Name',
        Opportunity_Field__c = 'Description',
        Name = 'CFMName00001-Test'
        );
        insert cfm;
        
        Account a = new Account(); 
        a.Name = 'test Individual';
        insert a;
        
        Contact c = new Contact();
        c.FirstName = 'test';
        c.LastName = 'contact';
        c.AccountId = a.Id;
        insert c;       
        
        list<Recurring_Donation__c> rdlist = new list<Recurring_Donation__c>();
        Recurring_Donation__c r1 = new Recurring_Donation__c();
        r1.Name = 'test';
        r1.Installments__c = 2;
        r1.Contact__c = c.Id;
        r1.Amount__c = 100;
        r1.Installment_Period__c = System.Label.RecurringDonationInstallmentPeriodYearly;
        r1.Date_Established__c = date.newinstance(1970,6,12);
        r1.Schedule_Type__c = System.Label.RecurringDonationMultiplyValue;
        r1.Open_Ended_Status__c = System.label.RecurringDonationOpenStatus;
        r1.Next_Payment_Date__c = system.today();
        insert r1;
        RecurringDonations_ProcessControl.hasRun = false;
                
        Recurring_Donation__c r2 = new Recurring_Donation__c();
        r2.Name = 'test';
        r2.Installments__c = 2;
        r2.Contact__c = c.Id;
        r2.Amount__c = 100;
        r2.Installment_Period__c = System.Label.RecurringDonationInstallmentPeriodMonthly;
        r2.Date_Established__c = date.newinstance(1970,6,12);
        r2.Schedule_Type__c = System.Label.RecurringDonationMultiplyValue;
        r2.Open_Ended_Status__c = System.label.RecurringDonationOpenStatus;
        r2.Next_Payment_Date__c = system.today();
        insert r2;
        RecurringDonations_ProcessControl.hasRun = false;
        map<id, Opportunity> originalOpps = new map<id, Opportunity>([select id, Name,amount,accountid,CloseDate from Opportunity where Recurring_Donation__r.id = :r1.id or Recurring_Donation__c = :r2.id]);                                
        string closedstage = [select masterlabel from opportunitystage where isActive = true and iswon = true and isClosed = true limit 1].masterlabel;
        system.assert(originalOpps.keySet().size() > 1);
        
        Test.startTest();
        originalOpps.values()[0].Stagename = closedstage;
        originalOpps.values()[1].stagename = closedstage;        
        update originalOpps.values();
        Test.stopTest();
        system.assert(originalOpps.keySet().size() > [select count() from Opportunity where isClosed = false and (Recurring_Donation__c = :r1.id or Recurring_Donation__c = :r2.id)]);        
    }    
	    
    public static void setRecurringDonationsSettingsForTest(Recurring_Donations_Settings__c rds){
        //clear out the old ones and insert this
        delete [select id from Recurring_Donations_Settings__c];
        insert rds;
    }
}