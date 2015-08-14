/******************************************************************************
//Name            : Test class UserChallengeCounterTest
//Description     : This test class covers the unit of the following
//                : 1. UserChallengeCounter class
//                : 2. AfterInsertAwardedBadge Trigger
//
//Author          : Guna Sevugapperumal Created 19 Sep, 2013
//Update          : Guna 10/16/2013 Revised the code to adopt to best practice 
******************************************************************************/
@isTest
public class UserChallengeCounterTest{
  
  public static List<challenge__c> createTestData(){
  	// Create test data
  	Integer numOfChallenges = 1;
  	Integer awardPointsAmt = 1000;
  	Integer bucketBalance = 15000;
  	String  bucketName = 'Test Certification Bucket';
  	String  badgeName = 'Test Certification Master';
  
 
  	// Create test collaboration group
  	CollaborationGroup collabGroup = AGETestUtility.createTestCollaborationGroup();
  
  	// Create a test badge record
  	List<badge__c> badges = AGETestUtility.createTestBadges(badgeName);
  
  	// Create test point Bucket    
  	List<points_bucket__c> pointbuckets = AGETestUtility.CreatePointsBuckets(
              																							bucketName, 
              																							bucketBalance);
  
  	// Create test challenge records
  	List<Challenge__c> challenges = AGETestUtility.CreateChallenge(
                                                 numOfChallenges, 
                                                 awardPointsAmt, 
                                                 badges[0],
                                                 pointbuckets[0]);
   return challenges;
  }
  
  
  public static testmethod void UserChallengeCounterPositiveTest(){
    User testUser = AGETestUtility.createTestEmployeeUser();
      System.runAs(testUser) {
      	// Create a test challenge record
      	
      	
        List<Challenge__c> challenges = createTestData();
        
        Test.startTest();
        date challengeDate;
        // test the UserChallengeCounter for each challenge created
        for(Challenge__c challenge : challenges){
        	
	        UserChallengeCounter userChallenge = new UserChallengeCounter(challenge);
	        userChallenge.challenge.Max_Number_of_Achievements_Per_User__c = 0;
	        // On initializing class default maxNumberReached should be false
	        system.assertEquals(false, userChallenge.maxNumberReached);
	        // count should be same as Max_Number_of_Achievements_Per_User__c
	        system.assertEquals(userChallenge.challenge.Max_Number_of_Achievements_Per_User__c, 
	                                                        userChallenge.count);
	        // Challenge record should have been assinged to the member variable
	        system.assertEquals(challenge, userChallenge.challenge);
	        
	        // Check for lastAwardedDate = null
	        userChallenge.lastAwardedDate = null;
	        challengeDate =  Date.Today().addDays(-3);
	        userChallenge.inspectChallenge(challengeDate);
	        system.assertEquals(userChallenge.lastAwardedDate, challengeDate);
	        
	        // check for challengeDate > lastAwardedDate 
	        userChallenge.lastAwardedDate = Date.today().addDays(-5);
	        
	        userChallenge.inspectChallenge(challengeDate);
	        // this should return lastawarded data == challengedate
	        system.assertEquals(userChallenge.lastAwardedDate, challengeDate);
	        
	        // check if the count is 1 after calling the method inspectChallenge
	        // since the challenge.Max_Number_of_Achievements_Per_User__c is set to 0
	        system.assertEquals(true, userChallenge.maxNumberReached);
	       
	        Test.stopTest();
        }
      } 
    } 
        
    // 3. Run Negative Test case
    public static testmethod void UserChallengeCounterNegativeTest(){
        User u = AGETestUtility.createTestEmployeeUser();
      System.runAs(u) {
        List<Challenge__c> challenges = createTestData();
        Test.startTest();
        date challengeDate;
        for(Challenge__c challenge : challenges){
            UserChallengeCounter userChallenge = new UserChallengeCounter(challenge);
            userChallenge.challenge.Max_Number_of_Achievements_Per_User__c = 5;
            
            // Check for lastAwardedDate = null
            userChallenge.lastAwardedDate = null;
            
            // set the challengeDate to  null
            challengeDate =  null;
            userChallenge.inspectChallenge(challengeDate);
            // in this case lastawardeddate and challengedate should be same
            system.assertEquals(userChallenge.lastAwardedDate, challengeDate);
            
            // set the challengeDate > lastAwardedDate 
            userChallenge.lastAwardedDate = Date.today().addDays(-5);
            challengeDate =  Date.Today().addDays(-3);
            userChallenge.inspectChallenge(challengeDate);
            // this should return lastawarded data == challengedate
            system.assertEquals(userChallenge.lastAwardedDate, challengeDate);
            
            // check if the maxNumberReached is still false after calling method inspectChallenge
            // since the challenge.Max_Number_of_Achievements_Per_User__c is set to 5
            system.assertEquals(false, userChallenge.maxNumberReached);
             test.stopTest();
        }
      }
    } 
}