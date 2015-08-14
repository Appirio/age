trigger afterInsertFeedComment on FeedComment (after insert) {
  
//
// (c) Appirio 2013
//
// When an Appirian has commented on a post in Chatter and included a Hashtag, check  
// the Challenges table and see if there are any Challenges associated to the tag.  
// If there are, check to see if the Challenge is being awarded by a Post and then
// award the Challenge based on the criteria of Poster or @mentions 
//
// 08/26/2013     Kym Le    Original
//  

  ChatterFeedTriggerHandler handler = new ChatterFeedTriggerHandler(Trigger.isExecuting);

  if(Trigger.isInsert && Trigger.isAfter){
    handler.OnAfterInsertFeedComment(Trigger.newMap);
  } 

  /*
  //list of all Chatter posts from the trigger
  List<FeedComment> feedItemList = Trigger.new;
  
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
  Map<Id, FeedComment> feedMap = new Map<Id, FeedComment>();
  
  //map of the post Id and list of hashtags
  Map<Id, List<String>> challengeHashTags = new Map<Id, List<String>>(); 
  
  //map of the post Id and the Challenge associated to it 
  Map<Id, List<Challenge__c>> feedItemIdAndChallengeMap = new Map<Id, List<Challenge__c>>();
  
  //map of hashtags and the Challenges associated to it
  Map<String, Challenge__c> hashChallengeMap = new Map<String, Challenge__c>();
                                           
  System.debug('FEED COMMENT LIST: ' + feedItemList);

  //for each FeedItem being inserted, check to see if any of them meet the criteria within an active
  //challenge based on the hashtag
  for(FeedComment f : feedItemList){
  
    //get all the strings with a tag '#' in the feed body and add them to the userNames Map and
    //feed map
    //make sure there's something in the body 
    if (f.CommentBody != null) {
      challengeHashTags.put(f.Id, getTaggedStrings(f.CommentBody, 0));
      feedMap.put(f.Id, f);
    }
  }
 
  //add all the hashtags found in the body to the list to search against Challenges 
  for(List<String> hashtag : challengeHashTags.values()){
    hashtagsToSearch.addAll(hashtag);
  } 
  
  System.debug('HASHTAGS TO SEARCH IN COMMENTS: ' + hashtagsToSearch);
  
  //create a list of Challenges based on the hashtags
  if (hashtagsToSearch.size() > 0) {
    Map<Id, Challenge__c> challengesMap = new Map<Id, Challenge__c>([SELECT Id, 
                                                                          Hashtag__c, 
                                                                          Title__c,
                                                                          Points_Awarded_To__c,
                                                                          Reward_Points__c 
                                                                   FROM   Challenge__c 
                                                                   WHERE  Active__c = true
                                                                   AND    Action__c INCLUDES ('Comment')   
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
        
              
  if(feedItemIdAndChallengeMap.isEmpty() == false) {    
    
    for(Id feedItemId : feedItemIdAndChallengeMap.keySet()){             
      
      List<Challenge__c> ch = feedItemIdAndChallengeMap.get(feedItemId);
      FeedComment f1 = feedMap.get(feedItemId);
      
      for(Challenge__c checkCh : ch){
        if (checkCh.Points_Awarded_To__c == 'Poster') {
      
          posterIdAndFeedItemMap.put(f1.CreatedById, feedItemId);
        }else {
          System.debug('CONNECT API FOR FeedItemID: ' + feedItemId);
        
          //get the @mentions user information from the body of the feed from ConnectApi
          ConnectApi.Comment feedItem = ConnectApi.ChatterFeeds.getComment(null, feedItemId);
          //Get the feed item message segments
          List<ConnectApi.MessageSegment> messageSegments = feedItem.body.messageSegments;
          //For each segment in the feed item
          for (ConnectApi.MessageSegment messageSegment : messageSegments) {
            //If the segment is a mention
            if (messageSegment instanceof ConnectApi.MentionSegment) {
                //Get the data for the mention segment from the ConnectApi
                ConnectApi.MentionSegment mentionSegment = (ConnectApi.MentionSegment) messageSegment;
                //Add the mentioned user to the mentionedUsersMap(userid, feedItemId)
                mentionedUsersMap.put(mentionSegment.user.id, feedItemId);
                
                System.debug('CONNECT API MENTION SEGMENT FROM TRIGGER: ' + mentionSegment);
            }
          }
          
          System.debug('MENTIONED USERS: ' + mentionedUsersMap);
        }         
      }  
    }  
    
    if (posterIdAndFeedItemMap.isEmpty() == false) {
      //Get the poster user records
      posters = [SELECT Id FROM User WHERE Id IN :posterIdAndFeedItemMap.keySet()];
      
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
          p.Notes__c = 'Commented in Chatter for ' + c.Title__c;
     
          awardedPointsByChatter.add(p);
        }
      }
    }
   
    System.debug('MENTIONED USERS MAP FINAL: ' + mentionedUsersMap);   
    if (mentionedUsersMap.isEmpty() == false) {
   
      //Get the mentioned user records
      mentionedUsers = [SELECT Id FROM User WHERE Id IN :mentionedUsersMap.keySet()];
   
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
          p.Notes__c = 'Mentioned in a Chatter comment for ' + c.Title__c;
     
          awardedPointsByChatter.add(p);
        }
      }
    }   
  }
   
  if (awardedPointsByChatter.isEmpty() == false) {
    insert awardedPointsByChatter;
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
      System.debug('tag: ' + tag);
      taggedNames.add(tag.toLowerCase());//Add the tagged string to the list
      taggedNames.addAll(getTaggedStrings(body, tagStopIndex));//Look for more tagged strings in this post
    }
    return taggedNames;//Return the final list
  }
  */

}