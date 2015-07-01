public class PointsValidator {

//
// (c) Appirio 2014
//
// Points Validator class.  Returns a Points Validation Result.
//
// 1.  Validate Points based on Challenge being active.
//
// 2.  Validate Points based on Points Bucket having enough points for the Awarding From User or 
//     by the no owner Points Bucket.
//
// 3.  Helper method to return Points Buckets for a list of Challenge Ids.
// 
// 4.  Helper method that determins if user has already been awarded based on a Target Object Id.
//
// 5.  Helper method that gets all users who have been awarded Points that have a Target Object Id.
//
// 
// 03/01/2014     Kym Le    Original
// 03/04/2014     Kym Le    Added code to handle error case when user does not send in an @mentions 
//                          to a chatter challenge
// 07/20/2014     Kym Le    Added logic to account for Shareable Points Bucket - points should be taken
//                          from user's Shareable Points Bucket first, then Manager's Points Bucket, and then, lastly,
//                          a Points Bucket that has no owner



  public static PointsValidationResult validatePointsForAwardedChallenge(Challenge__c challenge, User user, List<Points_Bucket__c> pointsBucketList){
    return validatePointsForAwardedChallenge(1, challenge, user, pointsBucketList);
  }
  
  
  public static PointsValidationResult validatePointsForAwardedChallenge(Integer totalTimesChallengeAwarded, Challenge__c challenge, User user, List<Points_Bucket__c> availablePb){
  
    PointsValidationResult result = new PointsValidationResult();
    result.isValid = true;
    result.pointsBucketToUse = null;
    Double rewardPoints = challenge.Reward_Points__c * totalTimesChallengeAwarded;
    
    if (!challenge.Active__c) {
      result.isValid = false;
      result.errorMessage = 'You can not award an inactive Challenge';
      
      return result;
    }
    
    if (totalTimesChallengeAwarded == 0) {
      result.isValid = false;
      result.errorMessage = 'Challenge needs to be awarded to at least 1 user';
    }
    
    if(availablePb == null){
      return result;
    }
    
    //if the Awarded From User is not specified, set it to the logged in User
    if (user == null) {
      user = [SELECT Id, 
                     Name 
              FROM   User 
              WHERE  Id = :UserInfo.getUserId()];
    }
    
    //point bucket that has createdby and owner as the same Id
    Points_Bucket__c ownerShareablePointBucket = null;
    
    Points_Bucket__c ownerPointBucket = null;
    Points_Bucket__c noOwnerPointBucket = null;
            
    //find out if there's a point bucket owned by the awarding user
    for(Points_Bucket__c pb : availablePb) {
      if(pb.Owner__c == user.Id && pb.CreatedById == user.Id) {
        ownerShareablePointBucket = pb;
      }  
      else if(pb.Owner__c == user.Id && pb.CreatedById != user.Id) {
        ownerPointBucket = pb;
      }
    }         

    //find out if there's a point bucket with no owner
    for(Points_Bucket__c pb : availablePb) {
      if(pb.Owner__c == null){
        noOwnerPointBucket = pb;
        break;
      }
    }
    
    //figure out which Points Bucket to use
    if (ownerShareablePointBucket != null && ownerShareablePointBucket.Current_Balance__c >= rewardPoints) {
      result.pointsBucketToUse = ownerShareablePointBucket;
    } else if (ownerPointBucket != null && ownerPointBucket.Current_Balance__c >= rewardPoints) {
      result.pointsBucketToUse = ownerPointBucket;
    } else {
      result.pointsBucketToUse = noOwnerPointBucket;
    }
      
      
    //if the owners Shareable Points Bucket does not have enough points and there is no other Points Bucket
    if (ownerShareablePointBucket != null && ownerPointBucket == null && noOwnerPointBucket == null && ownerShareablePointBucket.Current_Balance__c < rewardPoints) {
      System.debug('Adding to Exception list');
      result.isValid = false;
      result.errorMessage = 'There is no available Points Bucket with sufficient points for ' + user.Name + ' to award this challenge.';
    }
    
    //if the owners Shareable Points Bucket and Manager Points Bucket do not have enough points and there is no open Points Bucket
    if (ownerShareablePointBucket != null && ownerPointBucket != null && noOwnerPointBucket == null && ownerShareablePointBucket.Current_Balance__c < rewardPoints && ownerPointBucket.Current_Balance__c < rewardPoints) {
      System.debug('Adding to Exception list');
      result.isValid = false;
      result.errorMessage = 'There is no available Points Bucket with sufficient points for ' + user.Name + ' to award this challenge.';
    }
        
    //no Points Bucket for the user, there's an open Points Bucket but not enough points in there
    if (ownerShareablePointBucket == null && ownerPointBucket == null && noOwnerPointBucket != null && noOwnerPointBucket.Current_Balance__c < rewardPoints){
      System.debug('Adding to Exception list');
      result.isValid = false;
      result.errorMessage = 'There is no available Points Bucket with sufficient points for ' + user.Name + ' to award this challenge.';
    }

    //no Points Bucket for the user
    if (ownerShareablePointBucket == null && ownerPointBucket == null && noOwnerPointBucket == null && !availablePb.isEmpty()){
      System.debug('Adding to Exception list - Here!');
      result.isValid = false;
      result.errorMessage = 'There is no available Points Bucket for ' + user.Name + ' to award this challenge.';
    }   
        
    return result;     
  }
  
  
  public static Map<Id, List<Points_Bucket__c>> getPointsBucketsForChallenges(Set<Id> challengeIds) {
    //map of Challenge Id and list of Points Bucket                                        
    Map<Id, List<Points_Bucket__c>> challengeIdAndPointsBucketMap = new Map<Id, List<Points_Bucket__c>>();  

    //list of all the Points Buckets Ids that are possible for the Challenges coming in from the trigger                                                        
    List<Id> pointsBucketIds = new List<Id>();


    //list of all the challenge points buckets by challenge from the trigger                                                    
    List<Challenge_Points_Bucket__c> avaliableChallengePointsBuckets = [SELECT Id, 
                                                                               Challenge__c, 
                                                                               Points_Bucket__c 
                                                                        FROM   Challenge_Points_Bucket__c 
                                                                        WHERE  Challenge__c in :challengeIds];  
                                                                          
    if (avaliableChallengePointsBuckets.size() == 0) {
      return challengeIdAndPointsBucketMap;
    }                                                                          

    //populate the list with the Ids of the possible Points Buckets for the Challenges
    for (Challenge_Points_Bucket__c challengePointsBucket : avaliableChallengePointsBuckets) {
      pointsBucketIds.add(challengePointsBucket.Points_Bucket__c);
    }                                                                                                                                                                        
    
    //get all the Points Buckets that are possible
    Map<Id, Points_Bucket__c> pointsBucketMap = new Map<Id, Points_Bucket__c>([SELECT Id, 
                                                                                      Current_Balance__c, 
                                                                                      Owner__c,
                                                                                      CreatedById
                                                                               FROM   Points_Bucket__c 
                                                                               WHERE  Id in :pointsBucketIds]);                                          
                                       
    //loop through the possible Challenge Points Bucket and populate the list and map needed later
    for (Challenge_Points_Bucket__c cpb : avaliableChallengePointsBuckets) {

      List<Points_Bucket__c> pB = challengeIdAndPointsBucketMap.get(cpb.Challenge__c);
      
      if (pB == null) {
        pB = new List<Points_Bucket__c>();
      }
      
      pB.add(pointsBucketMap.get(cpb.Points_Bucket__c));
      challengeIdAndPointsBucketMap.put(cpb.Challenge__c, pB);
    }

    return challengeIdAndPointsBucketMap; 
  }
  
  
  public static Map<Id, List<Points__c>> getAllUsersAndPointsForTargetRecordId(Set<Id> userIds) {
  
    Map<Id, List<Points__c>> userIdAndPointsMap = new Map<Id, List<Points__c>>();
    
    //get the list of all points for all the users that have a target record id
    List<Points__c> userPoints = new List<Points__c>([SELECT Id, 
                                                             User__c, 
                                                             Target_Record_Id__c 
                                                      FROM   Points__c 
                                                      WHERE  User__c in :userIds
                                                      AND    Target_Record_Id__c != '']);                        
                        
    for (Points__c point : userPoints) {
      List<Points__c> pointsList = userIdAndPointsMap.get(point.User__c);
      
      if (pointsList == null) {
        pointsList = new List<Points__c>();
        
      }
      
      pointsList.add(point);    
      userIdAndPointsMap.put(point.User__c, pointsList);
    }  
    
    return userIdAndPointsMap;      
  }
  
  
  public static Boolean userHasAlreadyBeenAwardedTargetId(List<Points__c> userPoints, String targetRecordId) {
  
    if (userPoints != null) {
      for (Points__c point : userPoints) {
        System.debug('point: ' + point.Target_Record_Id__c);
        if (point.Target_Record_Id__c == targetRecordId) {
          return true;
        }
      }  
    }
        
    return false;
  }
  
}