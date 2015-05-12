trigger afterUpdatePointsBucket on Points_Bucket__c (after update) {

//
// (c) Appirio 2013
//
// When a Points Bucket Current Value gets decremented, we need to make sure that 
// the new Current Value is larger than any of the Challenges Reward Points that the
// Points Bucket is sourced to.
//  
// 
// 08/26/13     Kym Le    Original
// 10/18/13     Kym Le    changed logic around Points Buckets with new Challenge_Points_Bucket object
//

  //list of Challenges that we need to deactivate because the Rewards Points is
  //greater than what's left in the Points Bucket
  List<Challenge__c> challengesToDeactivate = new List<Challenge__c>();                                 
  
  //Points Bucket map
  Map<Id, Points_Bucket__c> pointsBucketMap = new Map<Id, Points_Bucket__c>(trigger.new);

  //List of all Challenge_Points_Buckets associated to the Points Bucket from the trigger
  List<Challenge_Points_Bucket__c> challengePointsBuckets = [SELECT Id, Challenge__c, Challenge__r.Active__c, Points_Bucket__c, Points_Bucket__r.Current_Balance__c
                                       FROM   Challenge_Points_Bucket__c
                                       WHERE  Points_Bucket__c in :pointsBucketMap.keySet()];
  
  //challenge ids of all challenges associated to the points bucket from the trigger
  Map<Id, Id> challengesFromPointsBucket = new Map<Id, Id>();
                                       
  for(Challenge_Points_Bucket__c cpb : challengePointsBuckets) {
    challengesFromPointsBucket.put(cpb.Challenge__c, cpb.Challenge__c);
  }                                     

  System.debug('CHALLENGES FROM POINTS BUCKET: ' + challengesFromPointsBucket);

  //map of Challenges based on the Points Buckets from the trigger
  Map<Id, Challenge__c> challengesMap = new Map<Id, Challenge__c>([SELECT Id, Reward_Points__c, Active__c
                                   FROM   Challenge__c
                                   WHERE  Id IN :challengesFromPointsBucket.keySet()]);
                                   
  Map<Id, Challenge_Points_Bucket__c> challengePointsBucketsMap = new Map<Id, Challenge_Points_Bucket__c>([SELECT Id, Challenge__c, Challenge__r.Active__c, Points_Bucket__c, Points_Bucket__r.Current_Balance__c
                                       FROM   Challenge_Points_Bucket__c
                                       WHERE  Challenge__c in :challengesMap.keySet()]);
                                                                          
  Map<Id, ChallengePointsBucketHolder> cpbh = new Map<Id, ChallengePointsBucketHolder>();
                                   
  for(Challenge_Points_Bucket__c cpb : challengePointsBucketsMap.values()) {
    ChallengePointsBucketHolder cpbHolder = cpbh.get(cpb.Challenge__c);
    
    if (cpbHolder == null) {
      cpbHolder = new ChallengePointsBucketHolder(challengesMap.get(cpb.Challenge__c));
    }  
    
    cpbHolder.addChallengePointsBucket(cpb);
    cpbh.put(cpb.Challenge__c, cpbHolder);
    System.debug('CPB HOLDER: ' + cpbHolder);  
  }                 
  
                  
                               
                                                                                                
  //for every Challenge in the trigger, check to see if the rewards points is greater than
  //the current balance of the Points Bucket.  If it is, add it to the list to deactivate
  for (ChallengePointsBucketHolder c : cpbh.values()) {
    
    System.debug('C: ' + c);
    System.debug('CHALLENGE ACTIVE: ' + c.challenge.Active__c);
    
    if (c.deactivateChallenge()) {
      c.challenge.Active__c = false;
      
      challengesToDeactivate.add(c.challenge);  
    }  
  }
  
  System.debug('CHALLENGES TO DEACTIVATE' + challengesToDeactivate);

  //if we have something in the list to update
  if (challengesToDeactivate.isEmpty() == false){
    update challengesToDeactivate;
  } 
  
  

}