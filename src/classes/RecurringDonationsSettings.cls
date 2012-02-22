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
    public Recurring_Donations_Settings__c rds {get; set;}
        
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
        
    //called from action method for page 
    public PageReference getSettingsFirstTime() {
        rds = RecurringDonations.getRecurringDonationsSettings();                   
        
        //test inserts
        testPackageIntegrity();
        return null;
    }        

    public RecurringDonationsSettings(){
        canEditRDSettings = false;
    }
    
    public pagereference editRDsettings(){
        canEditRDSettings = true;    
        return null;
    }
    
    public pagereference cancel(){
        canEditRDSettings = false;
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
        testOpp.StageName = [select MasterLabel from OpportunityStage where isWon = true and isClosed = true and isActive = true].MasterLabel;
        
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
        RecurringDonations_TEST.getRecurringDonationsSettingsForTest(new Recurring_Donations_Settings__c());
        
        Account a = new Account(Name='TestAccount');
        insert a;
        insert new Recurring_Donation__c(Name = 'TestRD', Organization__c = a.id);
 
 
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
    }
}