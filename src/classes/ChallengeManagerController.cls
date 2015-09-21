public class ChallengeManagerController extends AgeUserController {

//
// (c) Appirio 
//
// Appirio's Gamification App
//    This controller allows users to enter in their completed challenges and 
//    collect the points earned associated to such challenge
//
// 07/01/1    Kym Le              Original
// 09/22/13   Guna Sevugapperumal added public access modifier to SaveResult Inner class
// 10/18/13   Kym Le              Changed Points Buckets logic to use Challenge_Points_Bucket in save method
// 03/01/14   Kym Le              Changed awarding call to use GameEngine.AwardChallenge
// 07/28/14   Kym Le              Added CreatedById for SOQL query to retrieve points bucket to validate
// 09/17/15   Josh Tuttle         Added code for enforcing challenge limits (yearly, monthly, etc)


  public String selectedEmployee {get; set;}

    
  public ChallengeManagerController() { 
    //selectedDate = Date.Today().format();
    
    // URL parameter may specify a particular user for the "Appirian:" picklist
    selectedEmployee = ApexPages.CurrentPage().getParameters().get('userId');
  
    // otherwise, picklist should default to the current user
    if (selectedEmployee == null) selectedEmployee = UserInfo.getUserId();  
      
  }   
  
  @RemoteAction
  public static List<String> getDurationTypes() { 
    List<String> durations = new List<String>(); 
    
    Schema.DescribeFieldResult fieldResult =
      Challenge__c.Duration__c.getDescribe();
    List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
    
    for(Schema.PicklistEntry pl : ple){
      durations.add(pl.getValue());
    }   
    return durations;
  }
  
  @RemoteAction
  public static List<String> getCoreValueTypes() { 
    List<String> coreValues = new List<String>(); 
    
    Schema.DescribeFieldResult fieldResult =
      Challenge__c.Core_Value__c.getDescribe();
    List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
    
    for(Schema.PicklistEntry pl : ple){
      coreValues.add(pl.getValue());
    }   
    return coreValues;
  }
  
  @RemoteAction
  public static List<String> getFocusTypes() {
    List<String> focuses = new List<String>(); 
    
    Schema.DescribeFieldResult fieldResult =
      Challenge__c.Focus__c.getDescribe();
      List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
    
    for(Schema.PicklistEntry pl : ple){
      focuses.add(pl.getValue());
    }   
    return focuses;
  }
  
  @RemoteAction
  public static List<UserChallengeCounter> getAJChallengeMap(String selectedEmployee) {
    Map<String, UserChallengeCounter> challengeMap = new Map<String, UserChallengeCounter>();
    
    List<Challenge__c> cList = [SELECT   Name, 
                                         Title__c,
                                         Reward_Points__c,
                                         Max_Number_of_Achievements_Per_User__c,
                                         Duration__c,
                                         Automated__c,
                                         Hashtag__c,
                                         Start_Date__c,
                                         End_Date__c,
                                         Focus__c,
                                         Core_Value__c,
                                         Description__c,
                                         Active__c,
                                         Recently_Ended__c,
                                         Archived__c,
                                         Ended_in_Last_Year__c
                                FROM     Challenge__c
                                ORDER BY Title__c];
              
    for (Challenge__c challenge : cList) {
      challengeMap.put(challenge.id, new UserChallengeCounter(challenge));
    }
  
    List<Points__c> pList = [SELECT Id,
                                    Name,
                                    Challenge__r.Id,
                                    Amount__c,
                                    Date__c,
                                    Source__c,
                                    RecordType.Name
                             FROM   Points__c
                             WHERE  User__r.Id = :selectedEmployee
                             AND    Challenge__r.id != null
                             ORDER BY Challenge__r.Title__c];
  
    for (Points__c point : pList) {
      challengeMap.get(point.Challenge__r.id).inspectChallenge(point.Date__c);
    }
    return challengeMap.values();
  
  }
  
  public class SaveResult{
  
    public Boolean success;
    public String message;
    public Boolean maxNumberReached;
  
  }
  
  
  @RemoteAction
  public static SaveResult savePoints(String selectedUserId, String selectedChallengeId, String selectedDate, Integer currentAchievementCount) {
        
    Challenge__c c = [SELECT Id,
                             Name,
                             Title__c,
                             Reward_Points__c,
                             Active__c,
                             Max_Number_of_Achievements_Per_User__c,
                             Duration__c
                      FROM   Challenge__c
                      WHERE  Id = :selectedChallengeId];

    User u = [SELECT Id, Name FROM User WHERE Id = :UserInfo.getUserId()];                  
                      
    System.debug('Challenges: ' + c);                      
                      
    String notes = 'For completing challenge ' + c.Title__c;                  
    
    Date effectiveDate;
    
    if (selectedDate == '') {
      effectiveDate = Date.Today(); 
    } else {
      effectiveDate = Date.parse(selectedDate); 
    }
    
    List<Points__c> pList = [SELECT Id,
                                    Name,
                                    Challenge__r.Id,
                                    Amount__c,
                                    Date__c,
                                    Source__c,
                                    RecordType.Name
                             FROM   Points__c
                             WHERE  User__r.Id = :selectedUserId
                             AND    Challenge__r.id = :selectedChallengeId
                             ORDER BY Challenge__r.Title__c];
  
    for (Points__c point : pList) {
      System.debug('Point: ' + point);             
      Date pastEffectiveDate = point.Date__c;
      Integer daysPast = pastEffectiveDate.daysBetween(effectiveDate);
      
      if(c.Duration__c == 'monthly' && daysPast < 30){
      	SaveResult srFailedByDuration = new SaveResult();
        srFailedByDuration.success = false;
        srFailedByDuration.message= 'FAIL! You cannot complete the same challenge in last 30 days';
        
        return srFailedByDuration;
      }
      if(c.Duration__c == 'quarterly' && daysPast < 90){
      	SaveResult srFailedByDuration = new SaveResult();
        srFailedByDuration.success = false;
        srFailedByDuration.message= 'FAIL! You cannot complete the same challenge in last 90 days';
        
        return srFailedByDuration;
      }
      if(c.Duration__c == 'yearly' && daysPast < 365){
      	SaveResult srFailedByDuration = new SaveResult();
        srFailedByDuration.success = false;
        srFailedByDuration.message= 'FAIL! You cannot complete the same challenge in last 365 days';
        
        return srFailedByDuration;
      }
    }
                        
    List<Challenge_Points_Bucket__c> challengePointsBuckets = [SELECT Id, 
                                                   Points_Bucket__r.Id
                                            FROM   Challenge_Points_Bucket__c
                                            WHERE  Challenge__c = :c.Id
                                            AND    Points_Bucket__r.Owner__c = :UserInfo.getUserId() Limit 1]; 
        
    List<Points_Bucket__c> pointsBuckets = new List<Points_Bucket__c>();
    
    if (challengePointsBuckets.size() > 0) {                                        
      pointsBuckets = [SELECT Id, Current_Balance__c, Owner__c, CreatedById FROM Points_Bucket__c WHERE Id = :challengePointsBuckets[0].Points_Bucket__r.Id];                                            
    }
                                            
    PointsValidationResult pointsValidationResult = PointsValidator.validatePointsForAwardedChallenge(c, u, pointsBuckets);
    GameEngine.AwardedChallenge challengeToAward = new GameEngine.AwardedChallenge(c.Name, selectedUserId, UserInfo.getUserId(), effectiveDate, notes);
    
    
    SaveResult sr = new SaveResult();
       

       if (pointsValidationResult.isValid) {
          GameEngine.awardChallenge(challengeToAward);
        
        
          sr.success = true;
          currentAchievementCount++;
                                
          if (currentAchievementCount >= c.Max_Number_of_Achievements_Per_User__c) {
            sr.maxNumberReached = true;
          }   
       } else {                            
                                

        sr.success = false;
        sr.message= 'FAIL! ' + pointsValidationResult.errorMessage;
       }
     
    return sr;
  }
  
  @RemoteAction
  public static String getNewChallengeURL(){
    String newChallengeURL = '';
    
    Schema.DescribeSObjectResult r = Challenge__c.sObjectType.getDescribe();
    System.debug(r);
    
    if (r != null){
      newChallengeURL = '/' + r.getKeyPrefix() + '/o';
    }
    
    return newChallengeURL;
    
  }
  
  
}
