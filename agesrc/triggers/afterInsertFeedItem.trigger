trigger afterInsertFeedItem on FeedItem (after insert) {
  
//
// (c) Appirio 2013
//
// When an Appirian has Chattered something that contains a Hashtag, check the 
// Challenges table and see if there are any Challenges associated to the tag.  If
// there are, check to see if the Challenge is being awarded by a Post and then
// award the Challenge based on the criteria of Poster or @mentions 
//
// 08/26/2013     Kym Le    Original
// 11/04/2013     Kym Le    Added in additional logic to check for points bucket.  If there 
//                          is no valid points bucket for the challenge, we allow the chatter 
//                          to post but email the user to let them know points were not awarded.
  
  
  
  ChatterFeedTriggerHandler handler = new ChatterFeedTriggerHandler(Trigger.isExecuting);

  if(Trigger.isInsert && Trigger.isAfter){
    handler.onAfterInsertFeedItem(Trigger.newMap);
  }  
  

/*  
  //list of all Chatter posts from the trigger
  List<FeedItem> feedItemList = Trigger.new;
  
  //list of the posters of the Chatter posts
  List<User> posters = new List<User>();
  
  //list of all the Users from the @mentions in the body of the post
  List<User> mentionedUsers = new List<User>();
  
  //list of Points objects that will need to be updated because we need 
  //to award the Poster or @mentions
  List<Points__c> awardedPointsByChatter = new List<Points__c>();
  
  //list of hashtags that we will need to query the Challenges table
  List<String> hashtagsToSearch = new List<String>();
  
  //map of the Chatter poster Id and the post 
  Map<Id, String> posterIdAndFeedItemMap = new Map<Id, String>();
  
  //map of the @mentions Users' Id and names
  Map<Id, String> mentionedUsersMap = new Map<Id, String>(); 
  
  //map of the post
  Map<Id, FeedItem> feedMap = new Map<Id, FeedItem>();
  
  //map of the post Id and list of hashtags
  Map<Id, List<String>> challengeHashTags = new Map<Id, List<String>>(); 
  
  //map of the post Id and the Challenge associated to it 
  Map<Id, List<Challenge__c>> feedItemIdAndChallengeMap = new Map<Id, List<Challenge__c>>();
  
  //map of hashtags and the Challenges associated to it
  Map<String, Challenge__c> hashChallengeMap = new Map<String, Challenge__c>();
  
  //list of all the Points Buckets Ids that are possible for the Challenges coming in from the trigger                                                        
  List<Id> pointsBucketIds = new List<Id>();
  
  //map of Challenge Id and list of Points Bucket                                        
  Map<Id, List<Points_Bucket__c>> pbChallengeMap = new Map<Id, List<Points_Bucket__c>>();  
  
  //list of emails that need to be sent out to notify user of the error
  List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
  
  //map of User Ids and User  
  Map<Id, User> userMap = new Map<Id, User>();
                                           
                                           
  System.debug('FEED ITEM LIST: ' + feedItemList);                                           

  //for each FeedItem being inserted, check to see if any of them meet the criteria within an active
  //challenge based on the hashtag
  for(FeedItem f : feedItemList){
  
    //get all the strings with a tag '#' in the feed body and add them to the userNames Map and
    //feed map
    //make sure there's something in the body before adding to the maps 
    if (f.Body != null) {
      challengeHashTags.put(f.Id, getTaggedStrings(f.Body, 0));
      feedMap.put(f.Id, f);
      userMap.put(f.CreatedById, null);
    }
  }
 
  userMap = new Map<Id, User>([SELECT Id, 
                                      Name, 
                                      Email 
                               FROM   User 
                               WHERE  Id in :userMap.keySet()]); 
 
  //add all the hashtags found in the body to the list to search against Challenges 
  for(List<String> hashtag : challengeHashTags.values()){
    hashtagsToSearch.addAll(hashtag);
  } 
  
  System.debug('HASH TAGS TO SEARCH: ' + hashtagsToSearch);
  
  //create a list of Challenges based on the hashtags
  if (hashtagsToSearch.size() > 0) {
    Map<Id, Challenge__c> challengesMap = new Map<Id, Challenge__c>([SELECT Id, 
                                                                          Title__c, 
                                                                          Hashtag__c,
                                                                          Points_Awarded_To__c,
                                                                          Reward_Points__c,
                                                                          Active__c
                                                                   FROM   Challenge__c 
                                                                   WHERE  Active__c = true
                                                                   AND    Action__c INCLUDES ('Post')   
                                                                   AND    Hashtag__c IN:hashtagsToSearch
                                                                   AND    Hashtag__c != null]);
                                                            
 
    //for every Challenges, map the hastag associated to it
    for(Challenge__c hc : challengesMap.values()) {
      hashChallengeMap.put(hc.Hashtag__c.toLowerCase(), hc);
    }
  
    for(Id id : challengeHashTags.keySet()){
      List<Challenge__c> challenges = new List<Challenge__c>();  
      List<String> hashtags = challengeHashTags.get(id);
    
      for(String s : hashtags){
                                                                       
        if(hashChallengeMap.containsKey(s)){
          challenges.add(hashChallengeMap.get(s));
        }
      }
      feedItemIdAndChallengeMap.put(id, challenges);
    }
  
  
    // 11/04/2013 Kym Le - added Points Bucket logic check
  
    //list of all the challenge points buckets by challenge from the trigger                                                    
    List<Challenge_Points_Bucket__c> avaliableChallengePointsBuckets = [SELECT Id, 
                                                                               Challenge__c, 
                                                                               Points_Bucket__c 
                                                                        FROM   Challenge_Points_Bucket__c 
                                                                        WHERE  Challenge__c in :challengesMap.keySet()];  

    //populate the list with the Ids of the possible Points Buckets for the Challenges
    for (Challenge_Points_Bucket__c chaPoBucket : avaliableChallengePointsBuckets) {
      pointsBucketIds.add(chaPoBucket.Points_Bucket__c);
    }                                                                                                                                                                        
    
    
    //get all the Points Buckets that are possible
    Map<Id, Points_Bucket__c> pbMap = new Map<Id, Points_Bucket__c>([SELECT Id, 
                                                                            Current_Balance__c, 
                                                                            Owner__c 
                                                                     FROM   Points_Bucket__c 
                                                                     WHERE  Id in :pointsBucketIds]);                                          
                                       
    //loop through the possible Challenge Points Bucket and populate the list and map needed later
    for (Challenge_Points_Bucket__c cpb : avaliableChallengePointsBuckets) {

      List<Points_Bucket__c> poBucket = pbChallengeMap.get(cpb.Challenge__c);
      
      if (poBucket == null) {
        poBucket = new List<Points_Bucket__c>();
      }
      
      poBucket.add(pbMap.get(cpb.Points_Bucket__c));
      pbChallengeMap.put(cpb.Challenge__c, poBucket);
    }
  
    // end of Points Bucket logic
  
  
    //if there are Challenges associated to the Chatter post      
    if(feedItemIdAndChallengeMap.isEmpty() == false) {    
    
      for(Id feedItemId : feedItemIdAndChallengeMap.keySet()){             
      
        //get the list of Challenges that matched the hashtag of the Chatter post
        List<Challenge__c> ch = feedItemIdAndChallengeMap.get(feedItemId);
        //get the post
        FeedItem f1 = feedMap.get(feedItemId);
      
        //for every Challenge, we need to check if there's a Points Bucket and if there is,
        //we need to check if the balance will cover the Challenge reward points
        for (Challenge__c checkCh : ch) {

          PointsBucketValidationMessage pbvm = PointsBucketValidator.hasEnoughPointsInPointsBucket(checkCh, userMap.get(f1.CreatedById), pbChallengeMap, pbMap);
        
          //if the Points Bucket is valid
          if (pbvm.isValid) {
        
            //if the Challenge is awarded to the poster, add it to the poster map
            if (checkCh.Points_Awarded_To__c == 'Poster') {
              System.debug('AWARD TO POSTER');     
              posterIdAndFeedItemMap.put(f1.CreatedById, feedItemId);
        
            //if the Challenge is awarded to @mentions, use the Connect API call to get the mentions segment  
            } else {
              System.debug('AWARD TO MENTIONS' + feedItemId);
        
              //get the @mentions user information from the body of the feed from ConnectApi
              ConnectApi.FeedItem feedItem = ConnectApi.ChatterFeeds.getFeedItem(null, feedItemId);
          
              System.debug('CONNECT API FEED ITEM:' + feedItem);
          
              //Get the feed item message segments
              List<ConnectApi.MessageSegment> messageSegments = feedItem.body.messageSegments;
              System.debug('CONNECT API MESSAGE SEGMENTS: ' + messageSegments);
          
              //For each segment in the feed item
              for (ConnectApi.MessageSegment messageSegment : messageSegments) {
                //If the segment is a mention
                if (messageSegment instanceof ConnectApi.MentionSegment) {
                  //Get the data for the mention segment from the ConnectApi
                  ConnectApi.MentionSegment mentionSegment = (ConnectApi.MentionSegment) messageSegment;
                  System.debug('CONNECT API MENTION SEGMENT: ' + mentionSegment);
                
                  //Add the mentioned user to the mentionedUsersMap(userid, feedItemId)
                  mentionedUsersMap.put(mentionSegment.user.id, feedItemId);
                }
              }
            }
          } else {
            User u = userMap.get(f1.CreatedById);
            System.debug('not added to points trigger - email should be sent');
          
            String appEnvironmentURL = URL.getSalesforceBaseUrl().toExternalForm();

            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new String[] {u.Email});
            email.setOrgWideEmailAddressId(Game_Settings__c.getInstance().Chatter_From_Email_Address_Id__c);
                                   
            email.setSubject('Your attempt to award an AGE Challenge via Chatter failed');
            email.setHtmlBody('Your attempt to award an <a href="' + appEnvironmentURL + '/home/home.jsp?fId=' + f1.Id + '">AGE Challenge</a> via Chatter has failed: ' + pbvm.errorMessage + '<br/> Challenge: ' + checkCh.Title__c + '<br/> Chatter post: ' + f1.Body);
        
            emails.add(email);
          }        
        }  
      }  
    
      if (posterIdAndFeedItemMap.isEmpty() == false) {
        //Get the poster user records
        posters = [SELECT Id 
                   FROM   User 
                   WHERE  Id IN :posterIdAndFeedItemMap.keySet()];
      
        for (User u : posters){
          List<Challenge__c> ch = feedItemIdAndChallengeMap.get(posterIdAndFeedItemMap.get(u.Id));

          for(Challenge__c c : ch) {
            Points__c p = new Points__c();
            p.User__c = u.id;
            p.Amount__c = c.Reward_Points__c;
            p.Challenge__c = c.Id;
            p.Source__c = 'Challenge Completed';
            p.Type__c = 'General';
            p.Date__c = Date.Today(); 
            p.Notes__c = 'Posted in Chatter for ' + c.Title__c;
       
            awardedPointsByChatter.add(p);
          }
        }
      }
   
   
      System.debug('MENTIONED USERS: ' + mentionedUsersMap);   
      if (mentionedUsersMap.isEmpty() == false) {
   
        //Get the mentioned user records
        mentionedUsers = [SELECT Id 
                          FROM   User 
                          WHERE  Id IN :mentionedUsersMap.keySet()];
   
        for (User u : mentionedUsers){
          List<Challenge__c> ch = feedItemIdAndChallengeMap.get(mentionedUsersMap.get(u.Id));

          for(Challenge__c c : ch) {
            Points__c p = new Points__c();
            p.User__c = u.id;
            p.Amount__c = c.Reward_Points__c;
            p.Challenge__c = c.Id;
            p.Source__c = 'Challenge Completed';
            p.Type__c = 'General';
            p.Date__c = Date.Today(); 
            p.Notes__c = 'Mentioned in a Chatter post for ' + c.Title__c;
     
            awardedPointsByChatter.add(p);
          }
        }
      
        System.debug('USERS MENTIONED' + mentionedUsers);
      }   
    }
   
    if (awardedPointsByChatter.isEmpty() == false) {
      System.debug('Awarded Points By Chatter' + awardedPointsByChatter);
      insert awardedPointsByChatter;
    }
    
    if (emails.isEmpty() == false) {
    
      Messaging.sendEmail(emails);
    }
  
  } 
  
  
  
   
  //This method finds all the tagged strings in the post and returns a list with these strings
  //@param body :The body of the post
  //@param index :The index of the last characted for the last tagged string found.
  //              This tells the method where to begin searching for tags
  //@return :List of tagged strings
  public List<String> getTaggedStrings(String body, Integer index){
    List<String> taggedNames = new List<String>();//List to return
    //Get the index of the first tag in the body starting from the given index
    Integer tagStartIndex = body.indexOf('#', index);
    Integer tagStopIndex;
    //delimeter that denotes the end of the tagged string
    String delimeter = ' ';
    //If a tag '#' is found
    if(tagStartIndex != -1){
      //Get the index of the delimeter
      tagStopIndex = body.indexOf(delimeter, tagStartIndex);//Get the index of the first ' ' after the #
      
      if(tagStopIndex == -1){
        tagStopIndex = body.length();
      }
      //Get the string between the startIndex and stopIndex removing the # and any trailing spaces
      String tag = body.substring(tagStartIndex + 1, tagStopIndex).trim();//Get the tagged string
      taggedNames.add(tag.toLowerCase());//Add the tagged string to the list
      taggedNames.addAll(getTaggedStrings(body, tagStopIndex));//Look for more tagged strings in this post
    }
    return taggedNames;//Return the final list
  }
*/
}