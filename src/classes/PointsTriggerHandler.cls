public class PointsTriggerHandler {

//
// (c) Appirio
//
// When an AGE user completes a Challenge, the points associated to the Challenge is entered into the Points object.
// Some Challenges will have a Points Bucket that holds the current available balance of points; once the balance 
// reaches 0, the Challenges is then inactive.  
//
// This trigger handles the actions within the Points object.  There are three uses cases in which we are handling:
//
// 1. An AGE user is awarded Points and the trigger will need to decrement the reward points to the associated
// Points Bucket balance for the Challenge.
//
// 2. An AGE user's Points has been reomoved and the trigger will add the reward points back to the associated
// Points Bucket balance for the Challenge.
//
// 3. An AGE user is awarded Points that is connected to a Challenge and we need to check to see if that fulfills 
// any Badges to award the user.
//
// 9/10/13     Kym Le               Original
// 10/03/13    Guna Sevugapperumal  Added am if statement wrapped to skip few lines in class
//                                  that is blocking test cases from running. Search for guna below
//                                  where my change is commented with my name
// 10/6/13     Glenn Weinstein      For BadgeChallenges with a Tag Match list, only award Badge if Challenge was acheived with a valid tag
// 10/10/13    Glenn Weinstein      Replace hard-coded Chatter Group name with a Custom Setting; added Points.Tag
//                                  to Chatter message
// 10/15/13    Kym Le               Added logic for multiple points buckets per challenge
// 10/17/13    Glenn Weinstein      Fix bug in referencing Points__c.Notes__c without querying for it first
// 10/18/13    Kym Le               Removed references of old Points_Bucket__c on Challenge__c
// 03/01/14    Kym Le               Major code refactoring. Pulled a lot of code out into "helper" methods that will be found in 
//                                  PointsValidator class 
// 04/26/14    Glenn Weinstein      In chatterAwardedPoints(), tack on a linkAttachment if the Points record has a Target Link
//

  private boolean m_isExecuting = false;
  
  
  public PointsTriggerHandler(boolean isExecuting){
    m_isExecuting = isExecuting;
  }
  
  public void onBeforeInsert(List<Points__c> triggerPoints){
    
    Set<Id> challengeIds = new Set<Id>();
    List<Points__c> pointsToUpdate = new List<Points__c>(); 
    Map<Id, Points_Bucket__c> pointsBucketsToUpdateMap = new Map<Id, Points_Bucket__c>(); 
    List<Id> userIds = new List<Id>();     
    Map<Id, List<Points_Bucket__c>> challengeIdAndPointsBucketMap = new Map<Id, List<Points_Bucket__c>>();
  
    System.debug('trigger Points: ' + triggerPoints);
    
    //for every points, get the Challenge Id from the Trigger object
    for (Points__c point : triggerPoints) {  

      //got to next record if it's not an earned point
      if (point.RecordTypeId != '01250000000QzHxAAK'){
        continue;
      }

      challengeIds.add(point.Challenge__c); 
      userIds.add(point.Awarded_From_Id__c);
      userIds.add(point.User__c);
    }
    
    //if there are no challenges, stop processing
    if (challengeIds.size() == 0) {
      return;
    }
    
    //get a map of all Challenges that we need to process coming in from the Trigger
    Map<Id, Challenge__c> challengeMap = new Map<Id, Challenge__c>([SELECT Id, 
                                                                           Title__c,
                                                                           Reward_Points__c,
                                                                           Active__c 
                                                                    FROM   Challenge__c
                                                                    WHERE  Id in :challengeIds]);
                                                                                                                                  

    //populate the User map 
    Map<Id, User> userMap = new Map<Id, User>([SELECT Id, 
                                                      Name 
                                               FROM   User 
                                               WHERE  Id IN :userIds]);

    //get all the points buckets for all the challenges
    challengeIdAndPointsBucketMap = PointsValidator.getPointsBucketsForChallenges(challengeIds);

    
    for (Points__c pointsToValidate : triggerPoints) {
      
      List<Points_Bucket__c> challengePointsBuckets = challengeIdAndPointsBucketMap.get(pointsToValidate.Challenge__c);
      Challenge__c challenge = challengeMap.get(pointsToValidate.Challenge__c);
      
      System.debug('pointsToValidate' + pointsToValidate);
      System.debug('challenge: ' + challenge);

      PointsValidationResult pointsValidationResult = new PointsValidationResult();
      pointsValidationResult = PointsValidator.validatePointsForAwardedChallenge(challenge, userMap.get(pointsToValidate.Awarded_From_Id__c), challengePointsBuckets);
      
      if (pointsValidationResult.isValid) {

        if (pointsValidationResult.pointsBucketToUse != null) {

          Points_Bucket__c pointsBucket = pointsBucketsToUpdateMap.get(pointsValidationResult.pointsBucketToUse.Id);
          
          if(pointsBucket == null){
              pointsBucket = pointsValidationResult.pointsBucketToUse;
          }
          
          pointsBucket.Current_Balance__c -= challenge.Reward_Points__c;
          pointsBucketsToUpdateMap.put(pointsBucket.Id, pointsBucket);

          pointsToValidate.Points_Bucket__c = pointsValidationResult.pointsBucketToUse.Id;
        }
      
      } else {
        System.debug('Validation Error: ' + pointsValidationResult.errorMessage);
        pointsToValidate.addError(pointsValidationResult.errorMessage);
      }
    }

    if (pointsBucketsToUpdateMap.isEmpty() == false) {
      update(pointsBucketsToUpdateMap.values());
    }

  }
  
  
  public void OnAfterDelete(Points__c[] deletedPoints){
  
    System.debug('after delete method');
      
    List<Points__c> pointsToProcess = new List<Points__c>();
    List<Id> pointsBucketIds = new List<Id>();
    List<Points_Bucket__c> pointsBucketsToUpdate = new List<Points_Bucket__c>();
  
    for (Points__c point : deletedPoints) {
      
      //only grab the points that were deleted as an earned point
      if (point.RecordTypeId == '01250000000QzHxAAK') {
        pointsToProcess.add(point);
        pointsBucketIds.add(point.Points_Bucket__c);
      }
    }
    
    //only execute the following code if there's something in the list
    if (pointsToProcess.size() > 0) {
      
      //get the points bucket for every point that was deleted
      Map<Id, Points_Bucket__c> pointsBucketMap = new Map<Id, Points_Bucket__c>([SELECT Id, 
                                                                                        Current_Balance__c 
                                                                                 FROM   Points_Bucket__c 
                                                                                 WHERE  Id in :pointsBucketIds]);

                                               
      //for every deleted point, we need to check the points bucket to see if we need to add the points
      //back to the balance 
      for (Points__c point : pointsToProcess) {
        
        Points_Bucket__c pointsBucket = pointsBucketMap.get(point.Points_Bucket__c);
        
        if (pointsBucket != null) {
          pointsBucket.Current_Balance__c += point.Amount__c;
          pointsBucketsToUpdate.add(pointsBucket);
        
        }    
      }
 
      //check to see if there are any Points Buckets to update the current balance
      if (pointsBucketsToUpdate.isEmpty() == false) {
        update pointsBucketsToUpdate;
      }
    }           
  }


  public void chatterAwardedPoints(List<Points__c> pointsToChatter, Map<Id, Challenge__c> challengeMap) {
  
    String chatterGroupId = Game_Settings__c.getInstance().Chatter_Group_ID_All_Activities__c;

    for (Points__c point : pointsToChatter) {
      Challenge__c challenge = challengeMap.get(point.Challenge__c);
    
      ConnectApi.MessageBodyInput messageInput = new ConnectApi.MessageBodyInput();
      messageInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();
                   
      ConnectApi.MentionSegmentInput mentionSegment = new ConnectApi.MentionSegmentInput();
      mentionSegment.id = point.User__c;
      messageInput.messageSegments.add(mentionSegment);
      
      ConnectApi.TextSegmentInput textSegment = new ConnectApi.TextSegmentInput();
      textSegment.text = ' just earned ' + 
                         point.Amount__c + 
                         ' AGE points for completing the ' + 
                         challenge.Title__c + ' challenge!';
      messageInput.messageSegments.add(textSegment);
      
      
      ConnectApi.FeedItemInput input = new ConnectApi.FeedItemInput();
      input.body = messageInput;

      if (point.Target_Link__c != null) {
        ConnectApi.LinkAttachmentInput linkAttachment = new ConnectApi.LinkAttachmentInput();
        linkAttachment.url = point.Target_Link__c;
        linkAttachment.urlName = point.Target_Name__c;
        input.attachment = linkAttachment;
      }
      
      ConnectApi.FeedItem feedItemRep = ConnectApi.ChatterFeeds.postFeedItem(null,  // no community id
                                                                             ConnectApi.FeedType.Record, 
                                                                             chatterGroupId, 
                                                                             input, 
                                                                             null   // no file to upload
                                                                            );
    }
  }
  
  
  public void onAfterInsert(List<Points__c> triggerPoints){
  
    System.debug('Chatter Awarded Points and Award Badges');
  
    //award badges based on the new Points that have been awarded  
    Set<Id> possibleBadgeIdsToAward = new Set<Id>();
    List<Awarded_Badge__c> badgesToAward = new List<Awarded_Badge__c>(); 
    List<Id> challengeIds = new List<Id>();
    List<Id> userIds = new List<Id>();
    List<Points__c> pointsToProcess = new List<Points__c>();   
    Map<Id, List<Badge_Challenge__c>> availableBadgesByChallengeIdMap = new Map<Id, List<Badge_Challenge__c>>();
    Map<Id, List<Badge_Challenge__c>> availableBadgesByBadgeIdMap = new Map<Id, List<Badge_Challenge__c>>();    
    Map<Id, List<Awarded_Badge__c>> awardedBadgesByUserIdMap = new Map<Id, List<Awarded_Badge__c>>();
    Map<Id, List<Points__c>> pointsByUserIdMap = new Map<Id, List<Points__c>>();
    
    
    for (Points__c point : triggerPoints) {  

      //got to next record if it's not an earned point
      if (point.RecordTypeId != '01250000000QzHxAAK'){
        continue;
      }

      challengeIds.add(point.Challenge__c); 
      userIds.add(point.Awarded_From_Id__c);
      userIds.add(point.User__c);
      pointsToProcess.add(point);
    }
    
    
    //if there are no challenges, stop processing
    if (challengeIds.size() == 0) {
      return;
    }
    
    //get a map of all Challenges that we need to process coming in from the Trigger
    Map<Id, Challenge__c> challengeMap = new Map<Id, Challenge__c>([SELECT Id, 
                                                                           Title__c,
                                                                           Reward_Points__c,
                                                                           Active__c 
                                                                    FROM   Challenge__c
                                                                    WHERE  Id in :challengeIds]);
    
    if (!Test.isRunningTest()) {
      chatterAwardedPoints(pointsToProcess, challengeMap);
    }                                                                                                                                  

    //populate the User map 
    Map<Id, User> userMap = new Map<Id, User>([SELECT Id, 
                                                      Name 
                                               FROM   User 
                                               WHERE  Id IN :userIds]);
    
    
    
    
    //get all the badges associated to the challenges that are tied to the points off the trigger
    //this represents all badges that can possibly be awarded based on the challenges that are required
    List<Badge_Challenge__c> availableBadgesToLoop  =  [SELECT Badge__c, Challenge__c 
                                                        FROM   Badge_Challenge__c 
                                                        WHERE  Challenge__c in :challengeMap.keySet()
                                                        AND    Badge__r.Active__c = TRUE];

    //if there aren't any badges associated to the awarded challenges, exit out
    if (availableBadgesToLoop.isEmpty() == true) {
      return;
    }
    
    //for all the possible badges, we need to populate two maps; 
    //one that has the challenge id as the key and the list of badge_challenges
    //another that has the badge id as the key and the list of badge_challenges                                                
    for(Badge_Challenge__c bc : availableBadgesToLoop) {
      List<Badge_Challenge__c> badgeList = availableBadgesByChallengeIdMap.get(bc.Challenge__c);
      
      if(badgeList == null) {
        badgeList = new List<Badge_Challenge__c>();
      } 
      
      badgeList.add(bc);
    
      availableBadgesByChallengeIdMap.put(bc.Challenge__c, badgeList);
      availableBadgesByBadgeIdMap.put(bc.Badge__c, null);
    }

    //list of the required challenges for the available badges to award
    List<Badge_Challenge__c> availableBadgesToLoop2  =  [SELECT Badge__c, Challenge__c, Tag_Match__c
                                                         FROM   Badge_Challenge__c 
                                                         WHERE  Badge__c in :availableBadgesByBadgeIdMap.keySet()
                                                         AND    Badge__r.Active__c = TRUE];
    
    
    //for all the required challenges, populate the map the ties the badges to the list of challenges
    for(Badge_Challenge__c bc : availableBadgesToLoop2) {
      List<Badge_Challenge__c> badgeList = availableBadgesByChallengeIdMap.get(bc.Challenge__c);
      
      if(badgeList == null) {
        badgeList = new List<Badge_Challenge__c>();
      } 
      
      badgeList.add(bc);
    
      availableBadgesByChallengeIdMap.put(bc.Challenge__c, badgeList);

      List<Badge_Challenge__c> badgeList2 = availableBadgesByBadgeIdMap.get(bc.Badge__c);
      
      if(badgeList2 == null) {
        badgeList2 = new List<Badge_Challenge__c>();
      } 
      
      badgeList2.add(bc);

      availableBadgesByBadgeIdMap.put(bc.Badge__c, badgeList2);
    }                                                  
    
    
    //the list of awarded badges the user already has
    List<Awarded_Badge__c> awardedBadgesToLoop = [SELECT Badge__c, User__c
                                                  FROM   Awarded_Badge__c
                                                  WHERE  User__c in :userMap.keySet()];
    
    //loop through the list and populate the map                                          
    for(Awarded_Badge__c ab : awardedBadgesToLoop) {
      List<Awarded_Badge__c> awardBadgeList = awardedBadgesByUserIdMap.get(ab.User__c);
      
      if(awardBadgeList == null) {
        awardBadgeList = new List<Awarded_Badge__c>();
      }
      
      awardBadgeList.add(ab);
      
      awardedBadgesByUserIdMap.put(ab.User__c, awardBadgeList);
    }   
    
    
    //all the challenges the user has already achieved
    List<Points__c> userAchievedPointsToLoop = [SELECT Challenge__c, User__c, Tag__c
                                                FROM   Points__c 
                                                WHERE  User__c in :userMap.keySet()];
    
    //loop through the list and populate the map
    for(Points__c pts : userAchievedPointsToLoop) {
      List<Points__c> pointsList = pointsByUserIdMap.get(pts.User__c);
      
      if (pointsList == null) {
        pointsList = new List<Points__c>();
      }
    
      pointsList.add(pts);
      
      pointsByUserIdMap.put(pts.User__c, pointsList);
    }                      

    /*
    System.debug('Points by User Map: ' + pointsByUserIdMap.keySet());       
    System.debug('Awarded Badges by User Map: ' + awardedBadgesByUserIdMap.keySet() + 'value : ' + awardedBadgesByUserIdMap.values());       
    System.debug('Available Badges by Challenge Id: ' + availableBadgesByChallengeIdMap.keySet() + 'values : ' + availableBadgesByChallengeIdMap.values());  
    System.debug('Available Badges by Badge Id: ' + availableBadgesByBadgeIdMap);
    System.debug('Points to Process: ' + pointsToProcess);
    */
         
    //loop through all the points
    for (Points__c pt : pointsToProcess) {
      Challenge__c ch = challengeMap.get(pt.Challenge__c);
      User user = userMap.get(pt.User__c);
      
      //all possible badges associated to the challenge
      List<Badge_Challenge__c> availableBadges  =  availableBadgesByChallengeIdMap.get(ch.Id);
      if (availableBadges == null) {
        continue;
      }
      
      System.debug('user: ' + user);
      System.debug('awardedBadgeUserMap: ' + awardedBadgesByUserIdMap);
      
      //all the badges that the user already has
      List<Awarded_Badge__c> awardedBadges = awardedBadgesByUserIdMap.get(user.Id);
      if (awardedBadges == null) {
        awardedBadges = new List<Awarded_Badge__c>();
      }
                                              
      //loop through the available badges and see if the user already has that badge                                       
      for(Badge_Challenge__c bc : availableBadges) {
        Boolean matchFound = false;
      
        for(Awarded_Badge__c ab : awardedBadges) {
          if(bc.Badge__c == ab.Badge__c) {
            matchFound = true;
            break;
          }      
        }        
        if (matchFound == false) {
            possibleBadgeIdsToAward.add(bc.Badge__c);
        }                                
      }
    
      //System.debug('Possible Badges to Award: ' + possibleBadgeIdsToAward);  
    
      //grab all the challenges the user has achieved
      List<Points__c> userAchievedPoints = pointsByUserIdMap.get(user.Id);
         
      //for every badge in the list of possible badges to award, check to see if the 
      //user achieved all the required challenges                                            
      for (Id badgeId : possibleBadgeIdsToAward) {

        boolean add = true;
        for(Awarded_Badge__c alreadyAwarded : badgesToAward) {
          if(alreadyAwarded.Badge__c == badgeId && alreadyAwarded.User__c == user.Id){
            System.debug('Found a awarded badge for this user.');
            add = false;
            break;
          }
        }
        if(!add){
          continue;
        }


        System.debug('BadgeID: ' + badgeId);
        List<Points__c> userAchievedPointsToCheck = userAchievedPoints; 
        
        List<Badge_Challenge__c> challengesForBadge = availableBadgesByBadgeIdMap.get(badgeId);     
        System.debug('Challenges for Badge: ' + challengesForBadge);      
        //some badges have no challenges required 
        if (challengesForBadge == null) {
          continue;
        }
        
        //list of all challenge Ids required for the badge to be awarded
        List<Id> challengeIdRequiredForBadge = new List<Id>();        
        
        for (Badge_Challenge__c badgeC : challengesForBadge) {
          challengeIdRequiredForBadge.add(badgeC.Challenge__c);
        }
      
        System.debug('Challenges for Badge List: ' + challengeIdRequiredForBadge.size());             
        //loop through the two lists and remove the matches
        //if the userPoint list ends up being empty, we know the user has
        //achieved all the required challenges for the badge
        for (Points__c userPoints : userAchievedPointsToCheck) {
        
          // GlennW 10/6/13
          // get the Tag Match list (if any) on the BadgeChallenge that corresponds to our Points record
          String tagMatchList = null;
          for (Badge_Challenge__c bc : challengesForBadge) {
            if (bc.Challenge__c == userPoints.Challenge__c) {
              tagMatchList = bc.Tag_Match__c;
            }
          }
          
          // if there's a Tag Match list, make sure the Points tag matches at least one Tag in the Tag Match list
          if (tagMatchList != null) {
            List<String> tagList = tagMatchList.split(',');   // Tag Match list on BadgeChallenge is comma-delimited
            Boolean tagMatched = false;
            for (String tag : tagList) {
              if (tag.trim() == userPoints.Tag__c) {
                tagMatched = true;
              }
            }
            // only strike this Challenge off the list of Required Challenges if the Points record had a Tag matching the Tag Match list
            if (tagMatched) {
              challengeIdRequiredForBadge = listWithIdRemoved(challengeIdRequiredForBadge, userPoints.Challenge__c);            
            }
          } else {
            // there's no Tag Match list to worry about, so always strike this Challenge off the list of Required Challenges
            challengeIdRequiredForBadge = listWithIdRemoved(challengeIdRequiredForBadge, userPoints.Challenge__c);
          }
          // GlennW 10/6/13 - end of changes
          
          if (challengeIdRequiredForBadge.isEmpty()){
            break;
          }
        }
        //System.debug('User points: ' + userAchievedPointsToCheck);             
        //if the user has achieved all the challenges, award the badge
        if (challengeIdRequiredForBadge.isEmpty()) {
          System.debug('Awarding Badge : ' + badgeId);
          Awarded_Badge__c awardBadge = new Awarded_Badge__c();
          awardBadge.Badge__c = badgeId;
          awardBadge.User__c = user.Id;
          awardBadge.Effective_Date__c = Date.Today();

          badgesToAward.add(awardBadge);
          
        }
      }                                             
    }

    if(badgesToAward.isEmpty()==false){
      insert badgesToAward;
    }
  }
  
  //helper method to mimic java-like remove functionality in a list
  public List<Id> listWithIdRemoved (List<Id> idList, Id idToRemove) {
  
    List<Id> newList = new List<Id>();
    boolean removed = false;
        
    for (Id id : idList) {
      if (!removed && id == idToRemove) {
        removed = true;
      } else {
        newList.add(id);
      }
    }
    
    return newList;
  }

}