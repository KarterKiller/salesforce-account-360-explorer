@IsTest
private class AccountRelationshipControllerTest {
    @TestSetup static void makeData() {
        Account accountRecord = new Account(Name = 'Graph Test Account', Industry = 'Technology'); insert accountRecord;
        insert new Contact(LastName = 'Contact', AccountId = accountRecord.Id, Email = 'contact@example.test');
        insert new Opportunity(Name = 'Graph Opportunity', AccountId = accountRecord.Id, StageName = 'Prospecting', CloseDate = Date.today().addDays(14));
        insert new Case(AccountId = accountRecord.Id, Subject = 'Graph Case', Status = 'New', Origin = 'Web');
        Opportunity opportunityRecord = [SELECT Id FROM Opportunity LIMIT 1];
        insert new Task(Subject = 'Graph follow-up', WhatId = opportunityRecord.Id, Status = 'Not Started', ActivityDate = Date.today());
    }
    @IsTest static void returnsDirectRelationshipsAndCounts() {
        Account accountRecord = [SELECT Id FROM Account WHERE Name = 'Graph Test Account'];
        Test.startTest(); AccountRelationshipController.RelationshipResponse result = AccountRelationshipController.getRelationships(accountRecord.Id); Test.stopTest();
        System.assertEquals(4, result.nodes.size()); System.assertEquals(3, result.links.size());
        System.assertEquals(1, result.contactCount); System.assertEquals(1, result.opportunityCount); System.assertEquals(1, result.caseCount);
    }
    @IsTest static void accountSearchIsBoundedAndFindsFixture() {
        System.assertEquals(1, AccountRelationshipController.getAvailableAccounts('Graph Test').size());
        System.assert(AccountRelationshipController.getAvailableAccounts(null).size() <= 20);
    }
    @IsTest static void rejectsMissingAccount() {
        try { AccountRelationshipController.getRelationships(null); System.assert(false, 'Expected an exception.'); }
        catch (AuraHandledException expected) { System.assertNotEquals(null, expected); }
    }
    @IsTest static void expandsOnlyRequestedSecondaryBranch() {
        Opportunity opportunityRecord = [SELECT Id FROM Opportunity LIMIT 1];
        AccountRelationshipController.BranchResponse result = AccountRelationshipController.getExpandedRelationships(opportunityRecord.Id, 'Opportunity');
        System.assertEquals(1, result.nodes.size());
        System.assertEquals('Task', result.nodes[0].type);
        System.assertEquals(opportunityRecord.Id, result.links[0].source);
    }
    @IsTest static void userModeReturnsFriendlyErrorForRestrictedUser() {
        Profile minimumAccess = [SELECT Id FROM Profile WHERE Name = 'Minimum Access - Salesforce' LIMIT 1];
        User restrictedUser = new User(
            Alias = 'rgraph', Email = 'restricted.graph@example.test', EmailEncodingKey = 'UTF-8',
            LastName = 'Graph Restricted', LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US',
            ProfileId = minimumAccess.Id, TimeZoneSidKey = 'America/Los_Angeles',
            Username = 'restricted.graph.' + DateTime.now().getTime() + '@example.test'
        );
        insert restrictedUser;
        Id accountId = [SELECT Id FROM Account WHERE Name = 'Graph Test Account' LIMIT 1].Id;
        System.runAs(restrictedUser) {
            try {
                AccountRelationshipController.getRelationships(accountId);
                System.assert(false, 'A user without Account access must not receive relationship data.');
            } catch (AuraHandledException expected) {
                System.assertNotEquals(null, expected, 'The error is intentionally generalized.');
            }
        }
    }
}
