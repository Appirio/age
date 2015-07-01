public with sharing class ChatterFeedTriggerHandler {
  
  
//
// (c) Appirio
//
// When an Appirian has Chattered something that contains a Hashtag, check the 
// Challenges table and see if there are any Challenges associated to the tag.  If
// there are, check to see if the Challenge is being awarded by a Post and then
// award the Challenge based on the criteria of Poster or @mentions 
//
// 08/26/2013     Kym Le             Original
// 11/04/2013     Kym Le             Added in additional logic to check for points bucket.  If there 
//                                   is no valid points bucket for the challenge, we allow the chatter 
//                                   to post but email the user to let them know points were not awarded.
// 01/12/2014     Kym Le             Changed logic to figure out the hashtags in the post.  Now using the
//                                   ConnectApi.
// 01/27/2014     Kym Le             Specify current user's communityId (via Network.getNetworkId) in call to 
//                                   ConnectApi.ChatterFeeds.getFeedItem, in case it's a community user
// 02/05/2014     Kym Le             Major code refactoring.
// 03/04/2014     Kym Le             Added code to handle error case when user does not send in an @mentions 
//                                   to a chatter challenge
// 03/06/2014     Kym Le             Added logic to make sure the post is an original post.  We do not want to
//                                   award challenges to a repost.
// 08/18/2014     Kym Le             Added try-catch around ConnectAPI call.  It was throwing errors that were not easily
//                                   understandable and showing users weird error message in Chatter
// 9/11/2014      Glenn Weinstein    Put more details in Log Messages, for debugging

  
  private boolean m_isExecuting = false;
  
                                            
  public ChatterFeedTriggerHandler(boolean isExecuting){
    m_isExecuting = isExecuting;
  }
  
  
  public void onAfterInsertFeedItem(Map<Id, FeedItem> feedItemList){
  
    Map<Id, AlteredFeedObject> feedIdAndAlteredFeedObject = new Map<Id, AlteredFeedObject>();
    List<String> hashtagsToSearch = new List<String>();

    //for each FeedItem being inserted, check to see if any of them are associated to an active
    //challenge based on the hashtag
    for(FeedItem f : feedItemList.values()){

      ConnectApi.FeedItem feedItem;
      
      try {
        //use the ConnectApi in order to get information for the Feed; hashtags, feed type and @mentions if needed
        feedItem = ConnectApi.ChatterFeeds.getFeedItem(Network.getNetworkId(), f.Id);
      } catch (Exception e) {
        insert new Log_Message__c(Type__c = 'ChatterFeedTriggerHandler', 
                                  Message__c = e.getMessage() + '\n\n---\n' +
                                              'FeedItem Id: ' + f.Id + '\n\n' +
                                              'FeedItem Body:\n' + f.Body);
        continue;
      }      
      
      //make sure there's something in the body and the post is an original post and not a repost
      if (feedItem.OriginalFeedItem == null && f.Body != null) {
        
        //get the Message Segments
        List<ConnectApi.MessageSegment> messageSegments = feedItem.body.messageSegments;      
 
        //create a custom Feed Object to hold all the necessary data elements for the Feed Object 
        AlteredFeedObject alteredFeedObject = getNewFeedObject(f.CreatedById, f.body, messageSegments);

        //if there are any custom Feed Objects, add it to the list of custom Feed Objects so we can
        //later do bulked queries
        if (alteredFeedObject != null){
          feedIdAndAlteredFeedObject.put(f.id, alteredFeedObject);

        }
      }
    }
    
    if (feedIdAndAlteredFeedObject.size() == 0) {
      return;
    }

    feedIdAndAlteredFeedObject = processChallengesForFeed(feedIdAndAlteredFeedObject, 'Post');

    //if there are no challenges, stop processing
    if (feedIdAndAlteredFeedObject.size() == 0) {
      return;
    }

    processFeed(feedIdAndAlteredFeedObject);
  }


  public void onAfterInsertFeedComment(Map<Id, FeedComment> feedItemList){
  
    Map<Id, AlteredFeedObject> feedIdAndAlteredFeedObject = new Map<Id, AlteredFeedObject>();
    List<String> hashtagsToSearch = new List<String>();

    //for each FeedItem being inserted, check to see if any of them are associated to an active
    //challenge based on the hashtag
    for(FeedComment f : feedItemList.values()){
      ConnectApi.Comment feedItem;
      
      try {
        //use the ConnectApi in order to get information for the Feed; hashtags, feed type and @mentions if needed
        feedItem = ConnectApi.ChatterFeeds.getComment(Network.getNetworkId(), f.Id);
      } catch (Exception e) {
        insert new Log_Message__c(Type__c = 'ChatterFeedTriggerHandler', 
                                  Message__c = e.getMessage() + '\n\n---\n' +
                                              'FeedComment Id: ' + f.Id + '\n\n' +
                                              'FeedComment Body:\n' + f.CommentBody);
        continue;
      }
      
      //make sure there's something in the body before adding to the maps 
      if (f.commentBody != null) {
        
        //get the Message Segments
        List<ConnectApi.MessageSegment> messageSegments = feedItem.body.messageSegments;      
 
        //create a custom Feed Object to hold all the necessary data elements for the Feed Object 
        AlteredFeedObject alteredFeedObject = getNewFeedObject(f.CreatedById, f.commentBody, messageSegments);

        //if there are any custom Feed Objects, add it to the list of custom Feed Objects so we can
        //later do bulked queries
        if (alteredFeedObject != null){
          feedIdAndAlteredFeedObject.put(f.id, alteredFeedObject);

        }
      }
    }
    
    if (feedIdAndAlteredFeedObject.size() == 0) {
      return;
    }

    feedIdAndAlteredFeedObject = processChallengesForFeed(feedIdAndAlteredFeedObject, 'Comment');

    //if there are no challenges, stop processing
    if (feedIdAndAlteredFeedObject.size() == 0) {
      return;
    }

    processFeed(feedIdAndAlteredFeedObject);
  }
  
 
  private void processFeed(Map<Id, AlteredFeedObject> feedIdAndAlteredFeedObject){

    Set<Id> userIds = new Set<Id>();
    Set<Id> challengeIds = new Set<Id>();
    //list of Points objects that will need to be updated because we need 
    //to award the Poster or @mentions
    List<Points__c> pointsToAward = new List<Points__c>();
    
    //list of emails that need to be sent out to notify user of the error
    List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();

    Map<Id, List<Points_Bucket__c>> challengeIdAndPointsBucketMap = new Map<Id, List<Points_Bucket__c>>();
    Map<Id, List<Id>> feedIdAndMentionedUsersMap = new Map<Id, List<Id>>();
    List<GameEngine.AwardedChallenge> awardedChallengesList = new List<GameEngine.AwardedChallenge>();

    
    for (AlteredFeedObject afo : feedIdAndAlteredFeedObject.values()) {
      userIds.add(afo.CreatedById);
      for (Challenge__c afoch : afo.feedChallenges){
        challengeIds.add(afoch.Id);
      }
    }

    Map<Id, User> userMap = new Map<Id, User>([SELECT Id, 
                                                      Name, 
                                                      Email 
                                               FROM   User 
                                               WHERE  Id in :userIds]); 
 
  
    //populate the map of challenges and the points bucket per challenge
    challengeIdAndPointsBucketMap = PointsValidator.getPointsBucketsForChallenges(challengeIds);
 
   
    for(Id feedItemId : feedIdAndAlteredFeedObject.keySet()){     

      AlteredFeedObject afo = feedIdAndAlteredFeedObject.get(feedItemId);        
      
      //get the list of Challenges that matched the hashtag of the Chatter post
      List<Challenge__c> challenges = afo.feedChallenges;
        
      Id feedCreatedById = afo.createdById;
          
      //for every Challenge, we need to check if there's a Points Bucket and if there is,
      //we need to check if the balance will cover the Challenge reward points
      for (Challenge__c c : challenges) {

        PointsValidationResult pointsValidationResult = new PointsValidationResult();
        
        //if the Challenge is awarded to the poster, add it to the poster map
        if (c.Points_Awarded_To__c == 'Poster') {
          System.debug('AWARD TO POSTER');     
              
          pointsValidationResult = PointsValidator.validatePointsForAwardedChallenge(c, userMap.get(feedCreatedById), challengeIdAndPointsBucketMap.get(c.Id));
          System.debug('PVR: ' + pointsValidationResult);          
                    
          //if the Challenge is awarded to @mentions, use the Connect API call to get the mentions segment  
        } else {
          System.debug('AWARD TO MENTIONS' + feedItemId);
  
          List<Id> mentionedUsersList = getMentionedUsersForFeed(afo.feedMessageSegments);
              
          pointsValidationResult = PointsValidator.validatePointsForAwardedChallenge(mentionedUsersList.size(), c, userMap.get(feedCreatedById), challengeIdAndPointsBucketMap.get(c.Id));
              
          if (pointsValidationResult.isValid) {
            feedIdAndMentionedUsersMap.put(feedItemId, mentionedUsersList);
          }
        }
            
        if (!pointsValidationResult.isValid) {  
          System.debug('POINTS VALIDATOR RETURNED INVALID');    
          System.debug('not added to points trigger - email should be sent');

          User u = userMap.get(feedCreatedById);          
          String appEnvironmentURL = URL.getSalesforceBaseUrl().toExternalForm();

          Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
          email.setToAddresses(new String[] {u.Email});
          email.setOrgWideEmailAddressId(Game_Settings__c.getInstance().Chatter_From_Email_Address_Id__c); 
          email.setSubject('Your attempt to award an AGE Challenge via Chatter failed');
          email.setHtmlBody('Your attempt to award an <a href="' + appEnvironmentURL + '/home/home.jsp?fId=' + feedItemId + '">AGE Challenge</a> via Chatter has failed: ' + pointsValidationResult.errorMessage + '<br/> Challenge: ' + c.Title__c + '<br/> Chatter post: ' + afo.feedBody);
          emails.add(email);
            
          feedIdAndAlteredFeedObject.remove(feedItemId);
        }        
      }  
    }   
        
        
    for (Id fdId : feedIdAndAlteredFeedObject.keySet()){
      AlteredFeedObject afo = feedIdAndAlteredFeedObject.get(fdId);        
      List<Challenge__c> ch = afo.feedChallenges;
          
      for(Challenge__c c : ch) {
        if (c.Points_Awarded_To__c == '@mentions') {
          for (List<Id> uIds : feedIdAndMentionedUsersMap.values()) {
            for (Id id : uIds) {
            
              String note = 'Mentioned in a Chatter post for ' + c.Title__c;
            
              GameEngine.AwardedChallenge awardedChallenge = new GameEngine.AwardedChallenge(c.Name, id, afo.createdById, Date.Today(), note); 
              awardedChallengesList.add(awardedChallenge);
            }
          }
        } else if (c.Points_Awarded_To__c == 'Poster') {
          System.debug('awarding to poster');
              
          String note = 'Posted in Chatter for ' + c.Title__c;
       
          GameEngine.AwardedChallenge awardedChallenge = new GameEngine.AwardedChallenge(c.Name, afo.createdById, afo.createdById, Date.Today(), note); 
          
          System.debug('Awarded Challenge: ' + awardedChallenge);
          
          awardedChallengesList.add(awardedChallenge);
        }
      }
    }
      
      
    if (awardedChallengesList.size() >0) {
      System.debug('Awarded Points By Chatter' + awardedChallengesList);
      GameEngine.AwardChallenge(awardedChallengesList);
    }
    
    if (emails.isEmpty() == false) {
    
      Messaging.sendEmail(emails);
    }
    
  }

  //This method uses the ConnectApi to get all the hashtags and returns a list of strings
  public List<String> getHashtagsForMessageSegment(List<ConnectApi.MessageSegment> messageSegments){
    List<String> hashtags = new List<String>();
  
    System.debug('CONNECT API MESSAGE SEGMENTS FROM NEW METHOD: ' + messageSegments);
                
    for (ConnectApi.MessageSegment messageSegment : messageSegments) {
      //If the segment is a hashtag
      if (messageSegment instanceof ConnectApi.HashtagSegment) {
        //Get the data for the hashtag segment from the ConnectApi
        ConnectApi.HashtagSegment hashtagSegment = (ConnectApi.HashtagSegment) messageSegment;
        System.debug('CONNECT API MENTION SEGMENT HASHTAGS FROM NEW METHOD: ' + hashtagSegment);
                
        hashtags.add(hashtagSegment.tag.toLowerCase());
      }
    } 
              
    return hashtags;
  }


  public AlteredFeedObject getNewFeedObject(Id createdById, String feedBody, List<ConnectApi.messageSegment> feedMessageSegments) {
    
    List<String> feedHashtags = getHashtagsForMessageSegment(feedMessageSegments);

    if (feedHashtags.size() == 0) {
      return null;
    } else {
      return new AlteredFeedObject(createdById, feedBody, feedMessageSegments, feedHashtags);
    }
  }


  public Map<Id, AlteredFeedObject> processChallengesForFeed(Map<Id, AlteredFeedObject> feedIdAndAlteredFeedObject, String chatterFeedType) {
    Map<Id, AlteredFeedObject> afoWithChallenges = new Map<Id, AlteredFeedObject>();
    List<String> hashtagsToSearch = new List<String>();
    List<Challenge__c> challenges = new List<Challenge__c>();

    //loop through all the custom Feed objects and check to see if there is a list of message segments
    //if there are, loop through each message segment and get the hashtags and add all the hashtags to the 
    //list of hashtags to query for challenges
    for(AlteredFeedObject afo : feedIdAndAlteredFeedObject.values()){
        hashtagsToSearch.addAll(afo.feedHashtags);
    } 
    
    System.debug('HASH TAGS TO SEARCH: ' + hashtagsToSearch); 

    //if there are no hashtags, stop processing
    if (hashtagsToSearch.size() == 0) {
      return afoWithChallenges;
    }

    if(chatterFeedType == 'Post') {
      //populate the Challenge Map based on hashtags associated to the Challenge
      challenges = new List<Challenge__c>([SELECT Id, 
                                                  Name,
                                                  Title__c, 
                                                  Hashtag__c,
                                                  Points_Awarded_To__c,
                                                  Reward_Points__c,
                                                  Active__c
                                           FROM   Challenge__c 
                                           WHERE  Active__c = true
                                           AND    Action__c INCLUDES('Post')    
                                           AND    Hashtag__c IN:hashtagsToSearch
                                           AND    Hashtag__c != null]);
    } else {
      challenges = new List<Challenge__c>([SELECT Id, 
                                                  Name,
                                                  Title__c, 
                                                  Hashtag__c,
                                                  Points_Awarded_To__c,
                                                  Reward_Points__c,
                                                  Active__c
                                           FROM   Challenge__c 
                                           WHERE  Active__c = true
                                           AND    Action__c INCLUDES('Comment')   
                                           AND    Hashtag__c IN:hashtagsToSearch
                                           AND    Hashtag__c != null]);
    }

    //loop through the feedIdAndAlteredFeedObject and poulate the challenges
    for (Id feedId : feedIdAndAlteredFeedObject.keySet()){
      AlteredFeedObject afo2 = feedIdAndAlteredFeedObject.get(feedId);

      for (String afoHashtag : afo2.feedHashtags) {
        for (Challenge__c challenge : Challenges){
          if (afoHashtag == challenge.Hashtag__c){
            afo2.addChallenge(challenge);
          
          }
        }
      }
      
      if (afo2.feedChallenges.size() > 0) {
        afoWithChallenges.put(feedId, afo2);   

      }
    }

    return afoWithChallenges;
  }

  
  public List<Id> getMentionedUsersForFeed (List<ConnectApi.MessageSegment> feedMessageSegments) {
    List<Id> mentionedUsersList = new List<Id>();
    List<ConnectApi.MessageSegment> messageSegments = feedMessageSegments;
  
    for (ConnectApi.MessageSegment messageSegment : messageSegments) {
      //If the segment is a mention
      if (messageSegment instanceof ConnectApi.MentionSegment) {
        //Get the data for the mention segment from the ConnectApi
        ConnectApi.MentionSegment mentionSegment = (ConnectApi.MentionSegment) messageSegment;
        System.debug('CONNECT API MENTION SEGMENT: ' + mentionSegment);
                
        //Add the mentioned user to list
        mentionedUsersList.add(mentionSegment.record.id);
      }
    }
    return mentionedUsersList;
  }

  public class AlteredFeedObject {
    private Id createdById {get; set;}
    private String feedBody {get; set;}
    private List<Challenge__c> feedChallenges {get; set;}
    private List<ConnectApi.MessageSegment> feedMessageSegments {get; set;}
    private List<String> feedHashtags {get; set;}

    
    public AlteredFeedObject(Id feedCreatedById, String bodyContent, List<ConnectApi.MessageSegment> messageSegments, List<String> hashtags){
      feedChallenges = new List<Challenge__c>();
      feedMessageSegments = new List<ConnectApi.MessageSegment>();
      feedHashtags = new List<String>();

      createdById = feedCreatedById;
      feedBody = bodyContent;
      feedMessageSegments.addAll(messageSegments);
      feedHashtags.addAll(hashtags);

    }

    public void addChallenge(Challenge__c challenge){
      feedChallenges.add(challenge);
    }
  }

}