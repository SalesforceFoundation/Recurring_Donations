public with sharing class RecurringDonationsSettings {


    //enforce recurring donation open-ended as required
    
    //setting for both triggers
    
    //auto naming
    
    //clear open opps when donation is closed
    
    
    //called from action method for page 
    public PageReference getSettingsFirstTime() {
        //set a null page reference
        PageReference pr = null;                
        if (pr != null){
            pr.setRedirect(true);
        }
        return pr;
    }        



}