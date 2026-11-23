public inherited sharing class AccountRelationshipController {
    private static final Integer ACCOUNT_LIMIT = 20;
    private static final Integer RELATIONSHIP_LIMIT = 75;
    private static final Integer BRANCH_LIMIT = 25;

    @AuraEnabled(cacheable=true)
    public static List<AccountOption> getAvailableAccounts(String searchTerm) {
        String term = String.isBlank(searchTerm) ? '%' : '%' + searchTerm.trim() + '%';
        try {
            List<AccountOption> options = new List<AccountOption>();
            for (Account accountRecord : [
                SELECT Id, Name FROM Account
                WHERE Name LIKE :term
                WITH USER_MODE
                ORDER BY LastModifiedDate DESC
                LIMIT :ACCOUNT_LIMIT
            ]) {
                options.add(new AccountOption(accountRecord.Id, accountRecord.Name));
            }
            return options;
        } catch (QueryException queryError) {
            throw new AuraHandledException('You do not have permission to view Accounts.');
        }
    }

    @AuraEnabled(cacheable=true)
    public static RelationshipResponse getRelationships(Id accountId) {
        if (accountId == null || accountId.getSObjectType() != Account.SObjectType) {
            throw new AuraHandledException('A valid Account is required.');
        }
        try {
            Account accountRecord = [
                SELECT Id, Name, Industry, Type, Phone, Website
                FROM Account
                WHERE Id = :accountId
                WITH USER_MODE
                LIMIT 1
            ];
            RelationshipResponse response = new RelationshipResponse();
            response.nodes.add(accountNode(accountRecord));
            appendContacts(response, accountId);
            appendOpportunities(response, accountId);
            appendCases(response, accountId);
            return response;
        } catch (QueryException queryError) {
            throw new AuraHandledException('The selected Account is unavailable or you do not have sufficient access.');
        }
    }

    @AuraEnabled(cacheable=true)
    public static BranchResponse getExpandedRelationships(Id recordId, String recordType) {
        if (recordId == null || (recordType != 'Account' && recordType != 'Opportunity')) {
            throw new AuraHandledException('Only Account and Opportunity branches can be expanded.');
        }
        try {
            BranchResponse response = new BranchResponse();
            if (recordType == 'Account' && recordId.getSObjectType() == Account.SObjectType) {
                appendAccountBranch(response, recordId);
            } else if (recordType == 'Opportunity' && recordId.getSObjectType() == Opportunity.SObjectType) {
                appendActivityBranch(response, recordId);
            } else {
                throw new AuraHandledException('The selected record type does not match the requested branch.');
            }
            return response;
        } catch (QueryException queryError) {
            throw new AuraHandledException('The selected branch is unavailable or you do not have sufficient access.');
        }
    }

    private static void appendContacts(RelationshipResponse response, Id accountId) {
        for (Contact contactRecord : [
            SELECT Id, Name, Title, Email, Phone FROM Contact
            WHERE AccountId = :accountId WITH USER_MODE
            ORDER BY LastModifiedDate DESC LIMIT :RELATIONSHIP_LIMIT
        ]) response.add(contactNode(contactRecord), accountId);
    }
    private static void appendOpportunities(RelationshipResponse response, Id accountId) {
        for (Opportunity opportunityRecord : [
            SELECT Id, Name, StageName, Amount, CloseDate FROM Opportunity
            WHERE AccountId = :accountId WITH USER_MODE
            ORDER BY LastModifiedDate DESC LIMIT :RELATIONSHIP_LIMIT
        ]) response.add(opportunityNode(opportunityRecord), accountId);
    }
    private static void appendCases(RelationshipResponse response, Id accountId) {
        for (Case caseRecord : [
            SELECT Id, CaseNumber, Subject, Status, Priority FROM Case
            WHERE AccountId = :accountId WITH USER_MODE
            ORDER BY LastModifiedDate DESC LIMIT :RELATIONSHIP_LIMIT
        ]) response.add(caseNode(caseRecord), accountId);
    }
    private static void appendAccountBranch(BranchResponse response, Id accountId) {
        Account accountRecord = [SELECT ParentId FROM Account WHERE Id = :accountId WITH USER_MODE LIMIT 1];
        if (accountRecord.ParentId != null) {
            for (Account parentRecord : [SELECT Id, Name, Industry, Type, Phone FROM Account WHERE Id = :accountRecord.ParentId WITH USER_MODE LIMIT 1]) response.add(accountNode(parentRecord), accountId);
        }
        for (Account childRecord : [SELECT Id, Name, Industry, Type, Phone FROM Account WHERE ParentId = :accountId WITH USER_MODE ORDER BY LastModifiedDate DESC LIMIT :BRANCH_LIMIT]) response.add(accountNode(childRecord), accountId);
        for (Asset assetRecord : [SELECT Id, Name, Status, SerialNumber FROM Asset WHERE AccountId = :accountId WITH USER_MODE ORDER BY LastModifiedDate DESC LIMIT :BRANCH_LIMIT]) response.add(assetNode(assetRecord), accountId);
        appendActivityBranch(response, accountId);
        for (Contract contractRecord : [SELECT Id, ContractNumber, Status, StartDate FROM Contract WHERE AccountId = :accountId WITH USER_MODE ORDER BY LastModifiedDate DESC LIMIT :BRANCH_LIMIT]) response.add(contractNode(contractRecord), accountId);
        for (Order orderRecord : [SELECT Id, OrderNumber, Status, EffectiveDate FROM Order WHERE AccountId = :accountId WITH USER_MODE ORDER BY LastModifiedDate DESC LIMIT :BRANCH_LIMIT]) response.add(orderNode(orderRecord), accountId);
    }
    private static void appendActivityBranch(BranchResponse response, Id parentId) {
        for (Task taskRecord : [SELECT Id, Subject, Status, ActivityDate FROM Task WHERE WhatId = :parentId WITH USER_MODE ORDER BY ActivityDate DESC LIMIT :BRANCH_LIMIT]) response.add(taskNode(taskRecord), parentId);
        for (Event eventRecord : [SELECT Id, Subject, StartDateTime, EndDateTime FROM Event WHERE WhatId = :parentId WITH USER_MODE ORDER BY StartDateTime DESC LIMIT :BRANCH_LIMIT]) response.add(eventNode(eventRecord), parentId);
    }

    private static NodeData node(Id id, String type, String label, String subtitle, String one, String two, Boolean central) {
        NodeData data = new NodeData(); data.id = id; data.type = type; data.label = label; data.subtitle = subtitle; data.detailOne = one; data.detailTwo = two; data.isCentral = central; return data;
    }
    private static NodeData accountNode(Account a) { return node(a.Id, 'Account', a.Name, a.Industry, a.Type, a.Phone, true); }
    private static NodeData contactNode(Contact c) { return node(c.Id, 'Contact', c.Name, c.Title, c.Email, c.Phone, false); }
    private static NodeData opportunityNode(Opportunity o) { return node(o.Id, 'Opportunity', o.Name, o.StageName, String.valueOf(o.Amount), String.valueOf(o.CloseDate), false); }
    private static NodeData caseNode(Case c) { return node(c.Id, 'Case', 'Case ' + c.CaseNumber, c.Subject, c.Status, c.Priority, false); }
    private static NodeData assetNode(Asset a) { return node(a.Id, 'Asset', a.Name, a.Status, a.SerialNumber, null, false); }
    private static NodeData taskNode(Task t) { return node(t.Id, 'Task', t.Subject, t.Status, String.valueOf(t.ActivityDate), null, false); }
    private static NodeData eventNode(Event e) { return node(e.Id, 'Event', e.Subject, String.valueOf(e.StartDateTime), String.valueOf(e.EndDateTime), null, false); }
    private static NodeData contractNode(Contract c) { return node(c.Id, 'Contract', 'Contract ' + c.ContractNumber, c.Status, String.valueOf(c.StartDate), null, false); }
    private static NodeData orderNode(Order o) { return node(o.Id, 'Order', 'Order ' + o.OrderNumber, o.Status, String.valueOf(o.EffectiveDate), null, false); }

    public class AccountOption {
        @AuraEnabled public Id value;
        @AuraEnabled public String label;
        public AccountOption(Id value, String label) { this.value = value; this.label = label; }
    }
    public class RelationshipResponse {
        @AuraEnabled public List<NodeData> nodes = new List<NodeData>();
        @AuraEnabled public List<LinkData> links = new List<LinkData>();
        @AuraEnabled public Integer contactCount = 0;
        @AuraEnabled public Integer opportunityCount = 0;
        @AuraEnabled public Integer caseCount = 0;
        public void add(NodeData node, Id accountId) {
            nodes.add(node); links.add(new LinkData(accountId, node.id));
            if (node.type == 'Contact') contactCount++;
            if (node.type == 'Opportunity') opportunityCount++;
            if (node.type == 'Case') caseCount++;
        }
    }
    public class LinkData {
        @AuraEnabled public Id source;
        @AuraEnabled public Id target;
        public LinkData(Id source, Id target) { this.source = source; this.target = target; }
    }
    public class BranchResponse {
        @AuraEnabled public List<NodeData> nodes = new List<NodeData>();
        @AuraEnabled public List<LinkData> links = new List<LinkData>();
        public void add(NodeData node, Id parentId) { nodes.add(node); links.add(new LinkData(parentId, node.id)); }
    }
    public class NodeData {
        @AuraEnabled public Id id;
        @AuraEnabled public String type;
        @AuraEnabled public String label;
        @AuraEnabled public String subtitle;
        @AuraEnabled public String detailOne;
        @AuraEnabled public String detailTwo;
        @AuraEnabled public Boolean isCentral;
    }
}
