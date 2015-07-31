trigger afterInsertAwardedBadge on Awarded_Badge__c (after insert) {

//
// (c) Appirio 2013
//
// When a AGE user has been awarded a Badge, Chatter it 
//
// 08/26/2013     Kym Le    Original
// 10/04/2013     Guna Sevugapperumal Added a isRunningTest check below allow
//                                    testing continue when test cases run.
// 10/09/2013     Kym Le Deleted isRunningTest since we moved the chatterGroupId into a custom setting 
 
  //list of all the Chatter posts to insert
  List<FeedItem> chatterFeedToInsert = new List<FeedItem>();
  
  //chatter group id
  //String chatterGroupId = '';
  String chatterGroupId = Game_Settings__c.getInstance().Chatter_Group_ID_All_Activities__c;
  System.debug('CHATTER GROUP: ' + chatterGroupId);
  
  //list of awarded badges with the badge active status coming from the trigger
  List<Awarded_Badge__c> awardedBadges = [SELECT User__c, 
                                                 User__r.Name,
                                                 Badge__c, 
                                                 Badge__r.Title__c,
                                                 Badge__r.Active__c
                                   FROM   Awarded_Badge__c
                                   WHERE  Id IN :trigger.newMap.keySet()];                                  
   
  //for every item in the trigger, populate the User Id list and the Badge Id list   
  for (Awarded_Badge__c ab : awardedBadges) {
  
    if (ab.Badge__r.Active__c == false) {
      throw new BadgeException('You can not award an inactive Badge');
    }
    
    FeedItem post = new FeedItem();
    //ParentId to the AGE Chatter Group
    post.ParentId = chatterGroupId;
    post.body =  ab.User__r.Name + ' has just achieved the ' + ab.Badge__r.Title__c +  ' badge!!';
    
    chatterFeedToInsert.add(post);
    
  }
 
  //if the list is not empty, update it
  if (chatterFeedToInsert.size() > 0 && !Test.isRunningTest()) { 
        insert chatterFeedToInsert;   
  }
  
 
  
}