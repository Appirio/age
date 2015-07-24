public class GameEngine implements GameEngineInterface {

  // 
  // (c) Appirio
  //
  // Implementation of the public API for the Appirio Game Engine (AGE).
  //
  // 2013-09-02     Glenn Weinstein     Original
  // 2013-10-20     Glenn Weinstein     Add bulkified methods (that take lists of challenges)
  // 2013-12-23     Glenn Weinstein     Put more detail in Log Messages
  // 2014-03-01     Kym Le              Added new method to award Challenge based on a custom AwardedChallenge class
  // 2014-04-26     Glenn Weinstein     Add ability to pass in Target Name and Target Link
  // 2014-04-29     Glenn Weinstein     Rewrite method that takes lists of strings, to call method that takes AwardedChallenge;
  //                                    made AwardedChallenge members public, to avoid awkward constructors;
  //                                    put in null checks for tag and notes before trying to take left(255);
  //                                    removed @future annotation from method that takes lists of strings
  // 2014-07-14    Kym Le                Added new overloaded method to award Challege with Tag parameter
  
  // **
  // The first method below is the "main" method - it's the one that "does" all the work and has all the logic.
  // This main method takes every possible parameter, in bulk (list) form.
  //
  // All of the other methods below it, are essentially wrappers.  They groom the parameters they get, 
  // supply any missing parameters, bulkify (into lists of 1) if needed, and then call the "main" method.
  // **

  public static void awardChallenge(List<AwardedChallenge> awardedChallengeList) {
    
    List<Points__c> pointsToInsert = new List<Points__c>();
    Set<String> challengeNames = new Set<String>();
    Set<Id> contactIds = new Set<Id>();
    Map<Id, Id> awardToIdAndUserIdMap = new Map<Id, Id>();
    Map<String, Challenge__c> challengeNameMap = new Map<String, Challenge__c>();
    
    //get all the challenge Ids
    for (AwardedChallenge challenge : awardedChallengeList) {
    
      challengeNames.add(challenge.challengeName);
      
      //for the contact Ids, create a list so we can query and get the user record
      if (((String)challenge.awardedToUserId).substring(0,3) == '003') {
        contactIds.add(challenge.awardedToUserId);
      } else {
      
      //if it's not a contact Id, put the Id in a Users map
        awardToIdAndUserIdMap.put(challenge.awardedToUserId, challenge.awardedToUserId);
      }
    }
    
    //get all the Challenges based on the Challenge Name
    Map<Id, Challenge__c> challengeMap = new Map<Id, Challenge__c>([SELECT Id, 
                                                                           Name,
                                                                           Reward_Points__c 
                                                                    FROM   Challenge__c 
                                                                    WHERE  Name in :challengeNames]);
                                                                   
    //populate the ChallengeMap with all the Challenges
    for (challenge__c c : challengeMap.values()) {
      challengeNameMap.put(c.Name, c);
    }                                                            
                     
    //get all the Contacts and the User Id                                                                
    Map<Id, Contact> contactMap = new Map<Id, Contact>([SELECT Id, 
                                                               pse__Salesforce_User__c
                                                        FROM   Contact
                                                        WHERE  Id in :contactIds]);                                                                   
    
    //if there are contacts, populate the map with the Contact Id and the User Id
    if (contactMap.size() > 0) {
      for (Id contactId : contactMap.keySet()) {
        awardToIdAndUserIdMap.put(contactId, contactMap.get(contactId).pse__Salesforce_User__c);      
      }
    }
    
    //now, we go ahead and award the Challenges
    for (AwardedChallenge awardedChallenge : awardedChallengeList){

      try {
        
        Challenge__c challenge = challengeNameMap.get(awardedChallenge.challengeName);
        System.debug('challenge from gameEngine: ' + challenge);
        System.debug('GameEngine awardedFromUser: ' + awardedChallenge.AwardedFromUserId);

        if (challenge == null) {
          System.debug('challenge is null');
          
          throw new GameException('No Challenge found with name ' + awardedChallenge.challengeName +
                                      '\nawardedUserOrContactId = ' + awardedChallenge.awardedToUserId +
                                      '\ntag = ' + awardedChallenge.tag +
                                      '\nnotes = ' + awardedChallenge.notes + 
                                      '\neffectiveDate = ' + awardedChallenge.effectiveDate);
        }
        
        if (awardToIdAndUserIdMap.get(awardedChallenge.awardedToUserId) == null) {
      
          System.debug('gameEngine user is null');
          throw new GameException('No User found to award Challenge ' + awardedChallenge.challengeName +
                                      '\nawardedUserOrContactId = ' + awardedChallenge.awardedToUserId +
                                      '\ntag = ' + awardedChallenge.tag +
                                      '\nnotes = ' + awardedChallenge.notes + 
                                      '\neffectiveDate = ' + awardedChallenge.effectiveDate);
        }
        
        Points__c point = new Points__c();
        point.Challenge__c = challenge.Id;
        point.Amount__c = challenge.Reward_Points__c;
        point.Type__c = 'General';
        point.Source__c = 'Challenge Completed';
        point.User__c = awardToIdAndUserIdMap.get(awardedChallenge.awardedToUserId);
        point.Awarded_From_Id__c = awardedChallenge.AwardedFromUserId;
        point.Notes__c = awardedChallenge.notes !=null ? awardedChallenge.notes.left(255) : null;
        point.Tag__c = awardedChallenge.tag !=null ? awardedChallenge.tag.left(255) : null;    
        point.Target_Record_Id__c = awardedChallenge.targetRecordId;
        point.Target_Name__c = awardedChallenge.targetName;
        point.Target_Link__c = awardedChallenge.targetLink;
        
        pointsToInsert.add(point);
        
      } catch (Exception e) {
        insert new Log_Message__c(Message__c = e.getMessage(), Type__c = 'Game Engine');  
      }
    }
    
    System.debug('Game engine inserting points: ' + pointsToInsert);
    
    //execute a database insert so that the "All Or None" option is false
    if (pointsToInsert.isEmpty() == false) {
      System.debug('Game Engine inserted List of Points' + pointsToInsert);
      database.insert(pointsToInsert, false);
    }
  }


  // 
  // All remaining methods below are really just wrappers.  They groom the parameters and then call
  // the primary method above.
  //
  
  // let user pass in just 1 AwardedChallenge object
  public static void awardChallenge(AwardedChallenge awardChallenge) {
    
    //create a list of AwardedChallenges to all the main awardChallenge method
    List<AwardedChallenge> awardedChallenges = new List<AwardedChallenge>();
    awardedChallenges.add(awardChallenge);
    
    awardChallenge(awardedChallenges);
  }

  // let user pass in a big list of strings, instead of AwardedChallenge objects  
  // (this allows this method to ultimately be an external web service)                                      
  //@future
  public static void awardChallengesWithTagsAndTargets(List<String> challengeNames,
                                                       List<Id>     awardeeUserOrContactIds,
                                                       List<String> tags,
                                                       List<String> notes,
                                                       List<String> effectiveDates,
                                                       List<String> targetNames,
                                                       List<String> targetLinks) {
    List<AwardedChallenge> awardedChallenges = new List<AwardedChallenge>();
    for (Integer i = 0; i < challengeNames.size(); i++) {
      AwardedChallenge ac = new AwardedChallenge();
      ac.challengeName = challengeNames[i];
      ac.awardedToUserId = awardeeUserOrContactIds[i];
      ac.tag = tags[i];
      ac.notes = notes[i];
      ac.effectiveDate = effectiveDates[i] != null ? Date.parse(effectiveDates[i]) : null;
      ac.targetName = targetNames[i];
      ac.targetLink = targetLinks[i];
      awardedChallenges.add(ac);
    }                           
    awardChallenge(awardedChallenges);       
  }
  
  // let callers omit the list of tags
  public static void awardChallengesWithTargets(List<String> challengeNames,
                                                List<Id>     awardeeUserOrContactIds,
                                                List<String> targetNames,
                                                List<String> targetLinks,
                                                List<String> notes,
                                                List<String> effectiveDates) {
    
    // set tags to null
    List<String> tags = new List<String>();
    for (String challengeName : challengeNames) {
      tags.add(null);
    }
    awardChallengesWithTagsAndTargets(
      challengeNames, awardeeUserOrContactIds, tags, notes, effectiveDates, targetNames, targetLinks);
  } 
                                   
  // let callers omit the list of tags and effective dates
  public static void awardChallengesWithTargets(List<String> challengeNames,
                                                List<Id>     awardeeUserOrContactIds,
                                                List<String> targetNames,
                                                List<String> targetLinks,
                                                List<String> notes){
    
    // set tags and effective dates to null
    List<String> tags = new List<String>();
    List<String> effectiveDates = new List<String>();
    for (String challengeName : challengeNames) {
      tags.add(null);
      effectiveDates.add(null);
    }
    awardChallengesWithTagsAndTargets(
      challengeNames, awardeeUserOrContactIds, tags, notes, effectiveDates, targetNames, targetLinks);
  } 

  // let callers omit the list of targets
  public static void awardChallengesWithTags(List<String> challengeNames,
                                             List<Id>     awardeeUserOrContactIds,
                                             List<String> tags,
                                             List<String> notes,
                                             List<String> effectiveDates) { 
       
    // set all target names and target links to null
    List<String> targetNames = new List<String>();
    List<String> targetLinks = new List<String>();
    for (String challengeName : challengeNames) {
      targetNames.add(null);
      targetLinks.add(null);
    }
    awardChallengesWithTagsAndTargets(
      challengeNames, awardeeUserOrContactIds, tags, notes, effectiveDates, targetNames, targetLinks);
  }  


  // let callers omit the lists of effective dates and targets
  public static void awardChallengesWithTags(List<String> challengeNames,
                                             List<Id>      awardeeUserOrContactIds,
                                             List<String>  tags,
                                             List<String>  notes) { 
       
    // set all effective dates, target names, and target links to null
    List<String> effectiveDates = new List<String>();
    List<String> targetNames = new List<String>();
    List<String> targetLinks = new List<String>();
    for (String challengeName : challengeNames) {
      effectiveDates.add(null);
      targetNames.add(null);
      targetLinks.add(null);
    }
    awardChallengesWithTagsAndTargets(
      challengeNames, awardeeUserOrContactIds, tags, notes, effectiveDates, targetNames, targetLinks);
  } 
  
  // let callers omit the lists of tags and targets
  public static void awardChallenges(List<String> challengeNames,
                                     List<Id>     awardeeUserOrContactIds,
                                     List<String> notes,
                                     List<String> effectiveDates){ 
    
    // set all tags, target names, and target links to null
    List<String> tags = new List<String>();
    List<String> targetNames = new List<String>();
    List<String> targetLinks = new List<String>();
    for (String challengeName : challengeNames) {
      tags.add(null);
      targetNames.add(null);
      targetLinks.add(null);
    }
        
    awardChallengesWithTagsAndTargets(
      challengeNames, awardeeUserOrContactIds, tags, notes, effectiveDates, targetNames, targetLinks);
  }  
  
  // let callers omit the lists of tags, effective dates, and targets
  public static void awardChallenges(List<String> challengeNames,
                                     List<Id>     awardeeUserOrContactIds,
                                     List<String> notes){ 
    
    // set all tags, effective dates, target names, and target links to null
    List<String> tags = new List<String>();
    List<String> effectiveDates = new List<String>();
    List<String> targetNames = new List<String>();
    List<String> targetLinks = new List<String>();
    for (String challengeName : challengeNames) {
      tags.add(null);
      effectiveDates.add(null);
      targetNames.add(null);
      targetLinks.add(null);
    }

    awardChallengesWithTagsAndTargets(
      challengeNames, awardeeUserOrContactIds, tags, notes, effectiveDates, targetNames, targetLinks);
  }  
                                
  // let callers pass in fields to award a single challenge
  public static void awardChallengeWithTagAndTarget(String challengeName, 
                                                    Id     awardeeUserOrContactId,
                                                    String tag,
                                                    String notes,
                                                    String effectiveDate,
                                                    String targetName,
                                                    String targetLink) {
                                          
    awardChallengesWithTagsAndTargets(new List<String>{challengeName},
                                      new List<ID>{awardeeUserOrContactId},
                                      new List<String>{tag},
                                      new List<String>{notes},
                                      new List<String>{effectiveDate},
                                      new List<String>{targetName},
                                      new List<String>{targetLink});

  }

  // let users omit the target
  public static void awardChallengeWithTag(String challengeName, 
                                           Id     awardeeUserOrContactId,
                                           String tag,
                                           String notes,
                                           String effectiveDate) {
    awardChallengeWithTagAndTarget(
      challengeName, awardeeUserOrContactId, tag, notes, effectiveDate, null, null);
  }

  // let users call awardChallengeWithTag() without specifying an effective date
  public static void awardChallengeWithTag(String challengeName, 
                                           Id     awardeeUserOrContactId,
                                           String tag,
                                           String notes) {
    awardChallengeWithTag(challengeName, awardeeUserOrContactId, tag, notes, null);                                      
  }

  // for calls made without a tag, set tag to null
  public static void awardChallenge(String challengeName, 
                                    Id     awardeeUserOrContactId,
                                    String notes,
                                    String effectiveDate) {
    awardChallengeWithTag(challengeName, awardeeUserOrContactId, null, notes, effectiveDate);                                      
  }
  
  // for calls made without a tag or effective date, set both to null
  public static void awardChallenge(String challengeName, 
                                    Id     awardeeUserOrContactId,
                                    String notes) {
    awardChallengeWithTag(challengeName, awardeeUserOrContactId, null, notes, null);                                      
  }

  // let callers specify targets but not tags
  public static void awardChallengeWithTarget(String challengeName, 
                                              Id     awardeeUserOrContactId,
                                              String targetName,
                                              String targetLink,
                                              String notes,
                                              String effectiveDate) {
    awardChallengeWithTagAndTarget(
      challengeName, awardeeUserOrContactId, null, notes, effectiveDate, targetName, targetLink);
  }
  
  // let callers specify targets but not tags or effective dates
  public static void awardChallengeWithTarget(String challengeName, 
                                              Id     awardeeUserOrContactId,
                                              String targetName,
                                              String targetLink,
                                              String notes) {
    awardChallengeWithTagAndTarget(
      challengeName, awardeeUserOrContactId, null, notes, null, targetName, targetLink);
  }
  
  public class GameException extends Exception {}

  public class AwardedChallenge {
    public String challengeName {get;set;}
    public String awardedToUserId {get;set;}
    public String awardedFromUserId {get;set;}
    public String notes {get;set;}
    public Date effectiveDate {get;set;}
    public String tag {get;set;}
    public String targetRecordId {get;set;}
    public String targetName {get;set;}
    public String targetLink {get;set;}

    public AwardedChallenge() {}
    
    public AwardedChallenge(String challenge, Id awardedToUser, Date effDate){
      this.challengeName = challenge;
      this.awardedToUserId = awardedToUser;

      //TODO: validate effective date coming into constructor
      this.effectiveDate = effDate;
      
      //TODO: 
      this.notes = '';
      this.tag = '';
    }

    public AwardedChallenge(String challenge, Id user, Date effDate, String challengeNotes){
      this(challenge, user, effDate);
      this.notes = challengeNotes;
    }

    public AwardedChallenge(String challenge, Id user, Date effDate, String challengeNotes, String tg){
      this(challenge, user, effDate, challengeNotes);
      this.tag = tg;
    }
   
    public AwardedChallenge(String challenge, Id user, Date effDate, String challengeNotes, String tg, String targetRecord){
      this(challenge, user, effDate, challengeNotes, tg);
      this.targetRecordId = targetRecord;
      this.awardedFromUserId = Game_Settings__c.getInstance().System_User_Id__c;
    }

    public AwardedChallenge(String challenge, Id user, Id awardedFromUser, Date effDate){
      this(challenge, user, effDate);

      //TODO: validate effective date coming into constructor 
      this.awardedFromUserId = awardedFromUser;
    }

    public AwardedChallenge(String challenge, Id user, Id fromUser, Date effDate, String nts){
      this(challenge, user, fromUser, effDate);
      this.notes = nts;
    }
    
        public AwardedChallenge(String challenge, Id user, Id fromUser, Date effDate, String nts, String tg){
      this(challenge, user, fromUser, effDate);
      this.notes = nts;
      this.tag = tg;
    }
  }

}