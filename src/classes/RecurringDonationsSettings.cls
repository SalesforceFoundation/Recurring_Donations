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
* @description The controller for the VF page used for settings 
*/
public with sharing class RecurringDonationsSettings {

    public boolean canEditRDSettings {get; set;}
    public boolean canEditCISettings {get; set;}
    public boolean deleteInstallmentMode {get; set;}
    public Recurring_Donations_Settings__c rds {get; set;}
    public list<Custom_Installment_Settings__c> cis {get; set;}
    public string selectedTab {get; set;}
    public integer cisSize{get; set;}
    public string selectedInstallmentName{get; set;}
    public string replacementInstallment{get; set;}
    public list<SelectOption> validInstallments{
        get{
        	list<SelectOption> Installments = new list<SelectOption>(); 
            list<string> custominstallments = new list<string>();
            
            cisMap = Custom_Installment_Settings__c.getAll().clone();
            //custominstallments = cisMap.keySet();
            cisMap.remove(selectedInstallmentName);
                	   
            for (string s : cisMap.keySet()){
                Installments.add(new SelectOption(s,s));
            }
            Installments.add(new SelectOption(System.Label.RecurringDonationInstallmentPeriodYearly,System.Label.RecurringDonationInstallmentPeriodYearly));
            Installments.add(new SelectOption(System.Label.RecurringDonationInstallmentPeriodYearly,System.Label.RecurringDonationInstallmentPeriodWeekly));
            Installments.add(new SelectOption(System.Label.RecurringDonationInstallmentPeriodYearly,System.Label.RecurringDonationInstallmentPeriodQuarterly));
            Installments.add(new SelectOption(System.Label.RecurringDonationInstallmentPeriodYearly,System.Label.RecurringDonationInstallmentPeriodMonthly));
            Installments.add(new SelectOption(System.Label.RecurringDonationInstallmentPeriodYearly,System.Label.RecurringDonationInstallmentPeriod1stand15th));
            return Installments;
        }
    }
    public list<SelectOption> closeOptions{
    	get{
            list<RecurringDonations.RecurringDonationCloseOptions> CloseOptionValues = RecurringDonations.RecurringDonationCloseOptions.values();		
    		list<SelectOption> options = new list<SelectOption>();
            for (RecurringDonations.RecurringDonationCloseOptions rdco : CloseOptionValues){
                options.add(new SelectOption(rdco.name(), rdco.name()));
            }
            return options;
        }
    }
    public map<string, Custom_Installment_Settings__c> cisMap;        
        
    //called from action method for page 
    public PageReference getSettingsFirstTime() {
        rds = RecurringDonations.getRecurringDonationsSettings();                   
        cisMap = Custom_Installment_Settings__c.getAll();
        cis = cisMap.values();
        cisSize = cisMap.keySet().size();
        //test inserts
        testPackageIntegrity();
        return null;
    }        

    public RecurringDonationsSettings(){
    	if (selectedTab == null)
    	   selectedTab = 'general_settings';
        canEditRDSettings = false;
        canEditCISettings = false;
        deleteInstallmentMode = false;
    }
    
    public pagereference editRDsettings(){
        canEditRDSettings = true;    
        selectedTab = 'general_settings';
        return null;
    }
    
    public pagereference editCISettings(){
    	canEditCISettings = true;
    	selectedTab = 'installment_settings';
    	return null;
    }
    
    public pagereference cancel(){
    	cis.clear();
        canEditRDSettings = false;
        canEditCISettings = false;
        deleteInstallmentMode = false;
        cisMap = Custom_Installment_Settings__c.getAll();
        cis = cisMap.values();
        cisSize = cisMap.keySet().size();
        rds = RecurringDonations.getRecurringDonationsSettings();        
        return null;
    }

    public pagereference saveRDSettings(){
        
        try{
            update rds;
            canEditRDSettings = false;
        }
        catch (Exception e){
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.FATAL, e.getMessage());
            ApexPages.addMessage(myMsg);                        
        }
        return null;
    }
    
    //adds a row to the CI page
    public pageReference addCIRow(){    	
    	Custom_Installment_Settings__c c = new Custom_Installment_Settings__c();
    	cis.add(c);
    	return null;
    }
    
    //saves a new CI setting
    public pageReference saveCISettings(){
    	boolean invalidupsert = false;
    	
    	for (Custom_Installment_Settings__c c : cis){
    		if (c.Name == null || c.Value__c < 1 || c.Increment__c == null){
    		    ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.FATAL, system.label.RecurringDonationInvalidCustomInstallment);
                ApexPages.addMessage(myMsg);      
                invalidupsert = true;          
    		}
    		else{
                c.Value__c = c.Value__c.intValue();
    		}
    	}    	
    	if(!invalidupsert){
    	   upsert cis;
    	   canEditCISettings = false;
    	}    	       
    	return null;
    }
    
    //initiates custom installmetn deletion wizard
    public pageReference runDeleteWizard(){
        deleteInstallmentMode = true;    	
    	selectedTab = 'installment_settings';
    	return null;
    }
    
    //handles the delete & replace button
    public pageReference deleteInstallment(){
    	
    	list<Recurring_Donation__c> rdupdatelist = new list<Recurring_Donation__c>();
    	rdupdatelist = [select Installment_Period__c from Recurring_Donation__c where Installment_Period__c = :selectedInstallmentName];
    	for (Recurring_Donation__c rd : rdupdatelist){
    	   rd.Installment_Period__c = replacementInstallment;
    	
    	}
    	delete [select id from Custom_Installment_Settings__c where Name = :selectedInstallmentName];
        cisMap = Custom_Installment_Settings__c.getAll();
        cis = cisMap.values();
        cisSize = cisMap.keySet().size();
        rds = RecurringDonations.getRecurringDonationsSettings(); 
    	
    	selectedTab = 'installment_settings';
    	deleteInstallmentMode = false;   
    	return null;
    }    
    
    //test an opp insert as done in the class
    //and provide a warning if it fails
    private void testPackageIntegrity(){
        
        //test closed lost opp settings        
        string closedoppstage = system.label.RecurringDonationClosedLostOpportunityStage;
        integer x = 0;
        x = [select count() from OpportunityStage where MasterLabel = :closedoppstage and isClosed = true and isActive = true and isWon = false];
        
        string page_message = '';
        Savepoint sp = Database.setSavepoint();
            
        Opportunity testOpp = new Opportunity();
        testOpp.AccountID = [select id from Account limit 1].id;
        testOpp.Amount = 100;
        testOpp.CloseDate = system.today();
        testOpp.Name = 'TestOpp';
        
        //If there's no closed/won stage??
        string SName = '';
        SName = [select MasterLabel from OpportunityStage where isWon = true and isClosed = true and isActive = true].MasterLabel;
        testOpp.StageName = SName;        
        
        //use one if we got one, otherwise, create one for testing
        list<Recurring_Donation__c> rd = new list<Recurring_Donation__c>();
        rd = [select id from Recurring_Donation__c];
        if (!rd.isEmpty()){
            testOpp.Recurring_Donation__c = rd[0].id;
        }
        database.saveresult[] sr = database.insert(new list<Opportunity>{testopp}, false);
        database.rollback(sp); 
        ApexPages.Message myMsg;
        
        //we allow isRunningTest code to enter these loops for coverage purposes
        if (x < 1 || test.isRunningTest()){
            myMsg = new ApexPages.Message(ApexPages.Severity.WARNING, system.label.RecurringDonationBadLabelWarning);
            ApexPages.addMessage(myMsg);
        }   
        
        if(!sr[0].isSuccess() || test.isRunningTest()){ 
            Database.Error[] ers = sr[0].getErrors();  
            
            for (Database.Error err : ers){
                if (err.getStatusCode() == StatusCode.FIELD_CUSTOM_VALIDATION_EXCEPTION){
                    page_message += ' ' + system.label.RecurringDonationCustomValidationWarning;
                }
                else if (err.getStatusCode() == StatusCode.REQUIRED_FIELD_MISSING){
                    page_message += ' ' + system.Label.RecurringDonationRequiredFieldsWarning;
                }
                else{
                    page_message += ' ' + err.getMessage();
                }
                for (string s : err.getFields()){
                    page_message += s + ' ';                       
                }                                   
            }
            myMsg = new ApexPages.Message(ApexPages.Severity.WARNING, page_message);            
        }   
        if (myMsg != null){
        	ApexPages.addMessage(myMsg);
        }
    }
    
    /** Test Method **/ 
    public static testMethod void TEST_RecurringDonationsSettings() {
        RecurringDonations_TEST.setRecurringDonationsSettingsForTest(new Recurring_Donations_Settings__c());
        
        Account a = new Account(Name='TestAccount');
        insert a;
        insert new Recurring_Donation__c(Name = 'TestRD', Organization__c = a.id, Installment_Period__c='TestValueForUnitTests');
 
 
        Test.setCurrentPageReference(new PageReference('Page.RecurringDonationsSettings'));
        
        //pass the controller into the extension
        RecurringDonationsSettings controller = new RecurringDonationsSettings(); 
        controller.getSettingsFirstTime();
        system.assertNotEquals(null,RecurringDonations.getRecurringDonationsSettings());
        
        list<SelectOption> enumvalues  =  controller.closeOptions; 
        system.assertEquals(3,enumvalues.size());
        
        controller.testPackageIntegrity();
        controller.cancel();
        controller.editRDsettings();
        controller.rds.Open_Opportunity_Behavior__c = '-------------------';
        controller.saveRDSettings();   
        controller.rds.Open_Opportunity_Behavior__c = '1234';
        controller.saveRDSettings();
        controller.addCIRow();        
        controller.editCISettings();
        Custom_Installment_Settings__c c = new Custom_Installment_Settings__c(Name='TestValueForUnitTests', Value__c = 5.0, Increment__c = 'Weeks');
        controller.cis.add(c);
        controller.saveCISettings();
        controller.runDeleteWizard();
        controller.selectedInstallmentName = 'TestValueForUnitTests';
        controller.replacementInstallment = 'Weekly';        
        controller.deleteInstallment();        
        list<SelectOption> mylist = controller.validInstallments;
    }
}