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
* @description Handles XML exchange for webservice callout to compare package versions 
*/
global without sharing class RecurringDonationsPkgVersionCheck {
    
    private Recurring_Donations_Settings__c pageSettings;
    private final string ENDPOINT;
    private final string NAMESPACE_TO_CHECK;
        
    public RecurringDonationsPkgVersionCheck(string namespace){
        if (pageSettings == null){
            pageSettings = RecurringDonations.getRecurringDonationsSettings();
            if (pageSettings.Update_Check_Interval__c == null)
                pagesettings.Update_Check_Interval__c = 90;   
        }        
        
        if (!System.Test.isRunningTest()){
            NAMESPACE_TO_CHECK = namespace;
            ENDPOINT = 'http://foundation.force.com/packages/NPSPVersionCheck?orgid=' + UserInfo.getOrganizationId().substring(0, 15) + '&pkgname=' + namespace;   
        }
            
        else{    
            pageSettings.Enable_Update_Check__c = true;
            pageSettings.Last_Update_Check__c = null;
            NAMESPACE_TO_CHECK = 'test';
            ENDPOINT = 'http://foundation.kbromer.cs0.force.com/packages/NPSPVersionCheck?orgid=' + UserInfo.getOrganizationId().substring(0, 15) + '&pkgname=test';    
        }
    } 
    
    public void RecurringDonationsCheckVersion(boolean useSyncCallOut){        
        
        //if manually initiated callout immediately
        if(useSyncCallOut){
            initiateCallout();
        }    
        
        //if we're due for a checkup, call out async 
        else if (pageSettings.Enable_Update_Check__c && (pageSettings.Last_Update_Check__c == null || pageSettings.Last_Update_Check__c.addDays(integer.valueof(pageSettings.Update_Check_Interval__c.round())) > system.today())){
            RecurringDonationsPkgVersionCheck.FutureCallout(NAMESPACE_TO_CHECK);            
        }     
    }

    //async wrapper for a callout, we have to create a duplicate object
    //to get at the private class, but this gives us a single 
    //interaction point for the class    
    @future (callout = true)    
    private static void FutureCallout(string namespace){
        RecurringDonationsPkgVersionCheck npvc = new RecurringDonationsPkgVersionCheck(namespace);
        npvc.initiateCallout();
    }
    
    private void initiateCallout(){
        string pkgname = NAMESPACE_TO_CHECK;
        string endpoint = ENDPOINT;
        
        HttpRequest req = new HttpRequest();
        req.setEndPoint(constructendpoint(endpoint, pkgname));
        req.setMethod('GET'); 
        Http http = new Http();
        HttpResponse res = new HttpResponse();
        if (!System.Test.isRunningTest())
            res = http.send(req);
        else{
            string testresponsebody = '';
            testresponsebody += '<?xml version="1.0" encoding="UTF-8"?><pkg><namespace>test</namespace><mypkgver>1.5.5</mypkgver><maxpkgver>2.2</maxpkgver><needsupdate>true</needsupdate><updatelink>http://foundation.force.com/packages/affiliations</updatelink></pkg>';
            res.setBody(testresponsebody);
        }
        system.debug('MY RESPONSE BODY======================' + res.getBody());        
        //<pkg>namespace;yourver;maxver;isupdateable;updateurl</pkg>
   
        //if the callout was successful - send for parsing and updating
        if (res.getBody().length() > 0)
            updatePKGInfo(new NPSPEndPointResponse(res.getBody()));         
    }
    
    //method for adding pkgver param to the defined endpoint
    private string constructendpoint(string endpoint, string namespace){
        
        string newendpoint = endpoint;
        
        if (!system.Test.isRunningTest())
            newendpoint = newendpoint + '&pkgver=' + string.valueOf(Package.Version.Request);
        
        else
            newendpoint = newendpoint + '&pkgver=' + '1.5.0';
            
        return newendpoint;
    }
    
    class NPSPEndPointResponse{
        
        public string namespace {get; private set;}
        public string yourversion {get; private set;}
        public string maxversion {get; private set;}
        public string haspackageupdate {get; private set;}
        public string updateURL {get; private set;}
        
        
        NPSPEndPointResponse(string responsebody){
            updateproperties(parseResponseBody(responsebody));
        }
    
        private map<string, string> parseResponseBody(string bodytext){
            
            map<string, string> endpointText = new map<string, string>();
            system.debug('BODYTEXT: ' + bodytext);
            
            if (bodytext.length() > 0 && bodytext.contains('<pkg>')){

                //the body occasionall contains erroneous html characters that need to be stripped
                bodytext = bodytext.replace('</html>', '');
                bodytext = bodytext.replace('<html>', '');
                
                try{
                    XmlStreamReader xsr = new XmlStreamReader(bodytext);
                    string value = '';
                    while (xsr.hasNext()){
                        if(xsr.getEventType() == xmlTag.START_ELEMENT){
                            if (xsr.getLocalName() != 'pkg'){
                                value = getChars(xsr);                              
                                endpointText.put(xsr.getLocalName(), value);
                                system.debug('PUTTING: ' + xsr.getLocalName() + ', ' + value);
                            }
                        }                        
                        xsr.next(); 
                    }                    
                    system.debug(xsr.toString());
                }                
                catch (Exception e){
                    endpointText.put('namespace', 'ERROR');
                    endpointText.put('mypkgver', '0.0.0');
                    endpointText.put('maxpkgver', '0.0.0');
                    endpointText.put('needsupdate', 'UNKNOWN');
                    endpointText.put('updatelink', 'http://nonprofitstarterpack.org');  
                }    
            }
                        
            //malformed return body
            else {
                endpointText.put('namespace', 'ERROR');
                endpointText.put('mypkgver', '0.0.0');
                endpointText.put('maxpkgver', '0.0.0');
                endpointText.put('needsupdate', 'UNKNOWN');
                endpointText.put('updatelink', 'http://nonprofitstarterpack.org');  
            }
            
            return endpointText;
        }
        
        private string getChars(XmlStreamReader xmlreader){
            string returnChars = '';
            while (xmlreader.hasNext()){
                if (xmlreader.getEventType() == xmltag.END_ELEMENT)
                   break;
                else if (xmlreader.getEventType() == xmltag.CHARACTERS){
                    returnChars = xmlreader.getText();
                }                
                xmlreader.next();            
            }
            return returnChars;
        }
        
        private void updateproperties(map<string, string> parsedBody){
            this.namespace = parsedbody.get('namespace');
            this.yourversion = parsedbody.get('mypkgver');
            this.maxversion = parsedbody.get('maxpkgver');
            this.haspackageupdate = parsedbody.get('needsupdate');
            this.updateURL = parsedbody.get('updatelink');
        }
    }

    private void updatePKGInfo(NPSPEndPointResponse epr){
        
        pagesettings.Has_Package_Update__c = epr.haspackageupdate;
        pagesettings.Last_Update_Check__c = system.now();
        pagesettings.Max_Package_Version__c = epr.maxversion;
        pagesettings.Package_Update_URL__c = epr.updateURL;
        
        Database.Update(pagesettings);
        
    }
    
    /*******************TEST METHODS****************************/
    public static testMethod void VersionCheckTest(){
                    
        RecurringDonationsPkgVersionCheck npvc = new RecurringDonationsPkgVersionCheck('test');
        npvc.RecurringDonationsCheckVersion(true);
        npvc.RecurringDonationsCheckVersion(false);
        
        map<string, string> newmap = new map<string, string>();
        
        string invalidbody = '<badbody>junk</badbody>';
        string invalidxml =  '<pkg>invalidxmlstructure<pkg><random>';
        
        NPSPEndPointResponse nerp = new NPSPEndPointResponse(invalidbody);
        system.assert(nerp.haspackageupdate == 'UNKNOWN');
        
        NPSPEndPointResponse nerp2 = new NPSPEndPointResponse(invalidxml);
        system.assert(nerp2.haspackageupdate == 'UNKNOWN');
     
    }
}