public with sharing class RecurringDonationsSettings {


    //enforce recurring donation open-ended as required
    
    //setting for both triggers
    
    //auto naming
    
    //clear open opps when donation is closed
    
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
        
        if (x < 1){
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.WARNING, system.label.RecurringDonationBadLabelWarning);
            ApexPages.addMessage(myMsg);
        }            
        
        
        string page_message = '';
        Savepoint sp = Database.setSavepoint();
            
        Opportunity testOpp = new Opportunity();
        testOpp.AccountID = [select id from Account limit 1].id;
        testOpp.Amount = 100;
        testOpp.CloseDate = system.today();
        testOpp.Name = 'TestOpp';
        testOpp.StageName = [select MasterLabel from OpportunityStage where isWon = true and isClosed = true and isActive = true].MasterLabel;
        
        //use one if we got one, otherwise, create one for testing
        Recurring_Donation__c rd = [select id from Recurring_Donation__c limit 1];
        if (rd != null){
            testOpp.Recurring_Donation__c = rd.id;
        }
        database.saveresult[] sr = database.insert(new list<Opportunity>{testopp}, false);
        database.rollback(sp); 
        
        if(!sr[0].isSuccess()){ 
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
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.WARNING, page_message);
            ApexPages.addMessage(myMsg);
        }   
    }
}