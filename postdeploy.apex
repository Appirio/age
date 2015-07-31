// Create a new Chatter Group to post AGE messages
CollaborationGroup myGroup = new CollaborationGroup();
myGroup.Name='AGE Feed';
myGroup.CollaborationType='Public';
insert myGroup;

// Query for the new AGE Chatter Group
CollaborationGroup cg = [SELECT Id FROM CollaborationGroup WHERE Name = 'AGE Feed'];

// Update the reference to the Chatter Group in Custom Settings
Game_Settings__c gs = [SELECT Id, Chatter_Group_ID_All_Activities__c FROM Game_Settings__c];
gs.Chatter_Group_ID_All_Activities__c = cg.id;
update gs;
