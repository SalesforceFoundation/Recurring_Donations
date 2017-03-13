/*
    Copyright (c) 2017, Salesforce.org
    All rights reserved.
    
    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:
    
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of Salesforce.org nor the names of
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
private with sharing class UTIL_CustomLabel_TEST {
    
    //we have some packaged labels that we no longer reference by the underlying package.
    //unfortunately, this causes our local DE Orgs to not include them in our local package.
    //so we now refer to them here, just so our DE Orgs will keep the in our local package.
    private static testmethod void keepPackagedLabelsInPackage() {
        string str;
        str = Label.RecurringDonationBadFieldMapping;
        str = Label.RecurringDonationBadLabelWarning;
        str = Label.RecurringDonationCantDeleteError;
        str = Label.RecurringDonationClosedLostOpportunityStage;
        str = Label.RecurringDonationClosedStatus;
        str = Label.RecurringDonationContactRole;
        str = Label.RecurringDonationCustomValidationWarning;
        str = Label.RecurringDonationDivideValue;
        str = Label.RecurringDonationErrorEmailBody;
        str = Label.RecurringDonationInstallmentPeriod1stand15th;
        str = Label.RecurringDonationInstallmentPeriodMonthly;
        str = Label.RecurringDonationInstallmentPeriodQuarterly;
        str = Label.RecurringDonationInstallmentPeriodWeekly;
        str = Label.RecurringDonationInstallmentPeriodYearly;
        str = Label.RecurringDonationInvalidCustomInstallment;
        str = Label.RecurringDonationMissingDataError;
        str = Label.RecurringDonationMultiplyValue;
        str = Label.RecurringDonationOpenStatus;
        str = Label.RecurringDonationPrefix;
        str = Label.RecurringDonationRequiredFieldsWarning;
        str = Label.RecurringDonationSchedulingError;
        str = Label.RecurringDonationSettingsDescription;
        str = Label.RecurringDonationStageName;
        str = Label.RecurringDonationTooManyInstallmentsError;
    }
}