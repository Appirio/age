//
// (c) Appirio 2013
//
// This is test class for afterUpdatePointsBucket Trigger
//  
// 10/04/2013     Guna Sevugapperumal    Original
// 10/14/2013     Guna Sevugapperumal rewrote the code to adopt to best practice
@isTest(SeeAllData=true)
private class afterUpdatePointsBucketTest {
    
  static testMethod void afterUpdatePointsBucketPositiveTest() {  
    User testUser = AGETestUtility.createTestUser();
      
      // 2. Run the test as user
      system.runAs(testUser) { 
        Test.startTest();
        // Create test Challenges and points
      Integer numOfChallenges = 1;
      Integer awardPointsAmt = 1000;
      Integer bucketBalance = 900;
      String  bucketName = 'Test Certification Bucket';
      String  badgeName = 'Test Certification Master';
      // Create test collaboration group
      CollaborationGroup collabGroup = AGETestUtility.createTestCollaborationGroup();
      
      // Create a test badge record
      List<badge__c> badges = AGETestUtility.createTestBadges(badgeName);
      
      // Create test point Bucket    
      List<points_bucket__c> pointsbuckets = AGETestUtility.CreatePointsBuckets(
                                                            bucketName, 
                                                            bucketBalance);
      
      // Create test challenge records
      List<Challenge__c> challenges = AGETestUtility.CreateChallenge(
                                                     numOfChallenges, 
                                                     awardPointsAmt, 
                                                     badges[0],
                                                     pointsbuckets[0]);
      // Create test points records                                               
      try{
      AGETestUtility.createPoints(challenges);
      }
      catch(Exception e){
        system.debug('point cannot be awarded');
      }
      pointsBuckets = [SELECT id, title__c, 
                              current_balance__c 
                       FROM Points_bucket__c
                       WHERE Title__c = 'Test Certification Bucket'];
      
      // Trigger the afterUpdatePointsBucket trigger event.
      // explicility call the AfterUpdatePointsBucket trigger because it will not
      // be executed from the points insert
      update pointsBuckets;
       
      // Since Award Amount is greater than BucketBalance the points cannot be
      // awarded and bucket balance should remin unused         
      system.assertEquals(bucketBalance, pointsBuckets[0].current_balance__c);
      
      // Status of the challenge should be true since the challenge amount 
      // greater than bucket balance and not awarded. 
      Set<id> challengeIds = new Set<Id>();
      for(challenge__c challenge : challenges){
        challengeIds.add(challenge.Id);
      }
      List<challenge__c> updatedChallenge = [SELECT id, active__c,
                                                    reward_points__c 
                                             FROM   challenge__c
                                             WHERE id IN :challengeIds];
                                             
      //challenge is deactivated because no points buckets can fulfill the 
      //challenge award amount                                       
      system.assertEquals(false, updatedChallenge[0].active__c);     
                                                 
      Test.stopTest();   
       }
       
    }
  
    static testMethod void afterUpdatePointsBucketNegativeTest() {
      User testUser = AGETestUtility.createTestUser();
      
      // 2. Run the test as user
      system.runAs(testUser) { 
        Test.startTest();
        // Create test Challenges and points
      Integer numOfChallenges = 1;
      Integer awardPointsAmt = 1000;
      Integer bucketBalance = 5000;
      String  bucketName = 'Test Certification Bucket';
      String  badgeName = 'Test Certification Master';
      // Create test collaboration group
      CollaborationGroup collabGroup = AGETestUtility.createTestCollaborationGroup();
      
      // Create a test badge record
      List<badge__c> badges = AGETestUtility.createTestBadges(badgeName);
      
      // Create test point Bucket    
      List<points_bucket__c> pointsbuckets = AGETestUtility.CreatePointsBuckets(
                                                            bucketName, 
                                                            bucketBalance);
      
      // Create test challenge records
      List<Challenge__c> challenges = AGETestUtility.CreateChallenge(
                                                     numOfChallenges, 
                                                     awardPointsAmt, 
                                                     badges[0],
                                                     pointsbuckets[0]);
      // Create test points records 
      AGETestUtility.createPoints(challenges);                                              
       
      pointsBuckets = [SELECT id, title__c, 
                              current_balance__c 
                       FROM Points_bucket__c
                       WHERE Title__c = 'Test Certification Bucket'];
         
      // Trigger the afterUpdatePointsBucket trigger event.
      update pointsBuckets;
       
      // Since Award Amount is less than BucketBalance the points can be
      // awarded and bucket balance should be current_balance - awardPointsAmt
      // only one points record is created by the utility class. 
      system.assertEquals(bucketBalance - awardPointsAmt, pointsBuckets[0].current_balance__c);
      
      // Status of the challenge should be true since the challenge amount 
      // less than bucket balance and awarded.
      Set<id> challengeIds = new Set<Id>();
      for(challenge__c challenge : challenges){
        challengeIds.add(challenge.Id);
      }
      List<challenge__c> updatedChallenge = [SELECT id, active__c,
                                                    reward_points__c 
                                             FROM   challenge__c
                                             WHERE id IN :challengeIds];
      system.assertEquals(true, updatedChallenge[0].active__c); 
      
      // Try to delete all the points that were awarded and test again
      List<Points__c> testPoints = [SELECT id ,name 
                                    FROM Points__c
                                    WHERE User__c = :testUSer.Id]; 
      delete  testPoints;
      // There should not be any test points available.
      system.assertEquals(0, [SELECT id ,name 
                                    FROM Points__c
                                    WHERE User__c = :testUSer.Id].size());  
                                                 
      Test.stopTest();   
       }
     
    }
}