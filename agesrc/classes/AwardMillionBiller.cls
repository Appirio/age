global class AwardMillionBiller implements Schedulable { 

// (c) Appirio 2014
//
// Batch job that awards all employees that have billed > 1000000 from
// their time cards. This is for fixed fee as well as T&M projects.
//
// 03/14/2014     Kym Le     Original
// 03/25/2014     Kym Le     Changed class to be schedulable instead of batch.



  
  global void execute(SchedulableContext sc) {
    
    List<AggregateResult> timeCards = new List<AggregateResult>([SELECT   pse__Resource__r.Name, 
                                                                          pse__Resource__r.Id, 
                                                                          SUM(T_M_Equivalent_Revenue__c)
                                                                 FROM     pse__Timecard_Header__c 
                                                                 GROUP BY pse__Resource__r.Id, pse__Resource__r.Name 
                                                                 HAVING   SUM(T_M_Equivalent_Revenue__c) > 1000000]);

     execute(timeCards);
  }


  public static void execute(List<AggregateResult> timeCards){
    
    Map<Id, List<Points__c>> userIdAndPointsMap = new Map<Id, List<Points__c>>();
    Set<Id> userIds = new Set<Id>();
    List<Id> resourceIds = new List<Id>();
    List<GameEngine.AwardedChallenge> awardedChallengesList = new List<GameEngine.AwardedChallenge>();
    String millionBillerChallengeName = Game_Settings__c.getInstance().Challenge_Million_Biller__c;                      
                                                                 
    
    for(AggregateResult ag : timeCards) {
      resourceIds.add((Id)ag.get('Id'));
    }
    
    //get the userId based on the resourceId      
    Map<Id, Contact> contactMap = new Map<Id, Contact>([SELECT Id,
                                                               pse__Salesforce_User__c
                                                        FROM   Contact
                                                        WHERE  Id = :resourceIds]);
                                   
    for(Contact c : contactMap.values()) {
      userIds.add(c.pse__Salesforce_User__c);
    }                                   
    
    //get a map of all the users that have reached 1million and their points that have a targetRecordId
    userIdAndPointsMap = PointsValidator.getAllUsersAndPointsForTargetRecordId(userIds);
    
    for(AggregateResult ag : timeCards) {
      System.debug('process the time card');
      Id resourceId = (Id)ag.get('Id');
      Id userId = contactMap.get(resourceId).pse__Salesforce_User__c;
      
      //we only want to award the challenge once, so, we need to check to see if any of the points from this user already
      //has a record with the targetRecordId of millionbiller    
      if (!PointsValidator.userHasAlreadyBeenAwardedTargetId(userIdAndPointsMap.get(userId), millionBillerChallengeName)) {
                 
        //user has not been awarded this challenge yet.  Go ahead and award it and mark the targetRecordId so it doesn't get
        //awarded the next time the job runs           
        GameEngine.AwardedChallenge awardedChallenge = new GameEngine.AwardedChallenge(millionBillerChallengeName, userId, Date.Today(), 'Reached $1 million in billable work based on logged timecards', '', millionBillerChallengeName);
        awardedChallengesList.add(awardedChallenge);  
      }
    }
      
    if (awardedChallengesList.size() > 0) {      
      GameEngine.AwardChallenge(awardedChallengesList);
    }      
                                                                 
  }
}