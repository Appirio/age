/******************************************************************************
//Name            : Test class ChallengeManagerControllerTest
//Description     : ChallengeManagerControllerTest covers the following
//                : 1. ChallengeManagerController class
//                : 2. UserChallengeCounter class
//                : 3. afterInsertAwardBadge trigger
//
//Author          : Guna Sevugapperumal Created 09/22/2013
//Update          : Guna Sevugapperumal Revised 10/15/2013 for code best practices 
******************************************************************************/
@isTest(SeeAllData=true)
public class ChallengeManagerControllerTest{   
  //Positive Test case
  public static testmethod void ChallengeManagerControllerPositiveTest(){
    User testUser = AGETestUtility.createTestUser();
      system.runAs(testUser) {
        // Create test data
        Integer numOfChallenges = 10;
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
 
        // Create test points records                                               
        AGETestUtility.createPoints(challenges);
 
        Test.startTest();
        
        // Test the page reference url
        PageReference pageRef = Page.Challenges;
        Test.setCurrentPage(pageRef);
      
        ChallengeManagerController contr = new ChallengeManagerController(); 
        ApexPages.currentPage().getParameters().put('userId',userInfo.getUserId());
        String currentPage =  pageRef.getUrl();
        
        // Verify that page loads with loggedin userid parameters
        System.assertEquals('/apex/challenges?userId='+ userInfo.getUserId(), currentPage);
        System.assertEquals(contr.selectedEmployee, userInfo.getUserId());
        
        // Check if the picklist values for corevalues  are returned by the controller.
        schema.Describefieldresult coreResult = Challenge__c.Core_Value__c.getDescribe();
        List<Schema.PicklistEntry> pleCore = coreResult.getPicklistValues();
        List<String> coreValues = ChallengeManagerController.getCoreValueTypes();
        system.assertEquals(pleCore.size(), coreValues.size());
         
        // Check if the picklist values for focusTypes  are returned by the controller.
        schema.Describefieldresult focusResult = Challenge__c.Focus__c.getDescribe();
        List<Schema.PicklistEntry> pleFocus = focusResult.getPicklistValues();
        List<String> focusTypes = ChallengeManagerController.getFocusTypes();
        system.assertEquals(pleFocus.size(), focusTypes.size());
        
        
        // Check the list of test challenges for the test user who has been 
        // awarded on each challenge note: every other test challenge can be
        // awarded only once and rest only twice. The AGETestUtility class is 
        // configured to create max rewards allowed as either one or 2 for testing 
        // purpose
        List<UserChallengeCounter> userChellengeCounters = 
             challengeManagerController.getAJChallengeMap(UserInfo.getUserId()) ;         
        // check if the test user reached Maxpoints on each of the challenge
        Integer maxawardReached = 0;
        for(UserChallengeCounter userChellengeContr: userChellengeCounters){
            if(userChellengeContr.maxNumberReached == true)
                maxawardReached ++;
        }
        // only half the numOfChallenges would have reached max rewards
        system.assertEquals(numOfChallenges/2, maxawardReached); 
        
        
        // Test the Challenge__C object id
        String newChallengeURL = '';
      Schema.DescribeSObjectResult r = Challenge__c.sObjectType.getDescribe();
      newChallengeURL = '/' + r.getKeyPrefix() + '/o';
        system.assertEquals(newChallengeURL, challengeManagerController.getNewChallengeURL());
      
         
        ChallengeManagerController.SaveResult saveResult = 
                                     new ChallengeManagerController.saveResult() ; 
        String selectedDate = Date.today().format();
        saveResult = challengeManagerController.savePoints(userInfo.GetuserId(), 
                                                 String.valueOf(challenges[0].id), 
                                                 String.valueOf(selectedDate), 1);
         
        // note: If all the points in the bucket used, all the related challenges
        // will turn Inactive. In this case only 10 * 1000 points are awarded,
        // out of 15000 bucket balance. 
        
        system.debug('@@@@@@@@@@@' + saveResult.message);
        system.assertEquals(null, saveResult.message);
        system.assertEquals(true, saveResult.Success);
        system.assertEquals(true, saveResult.maxNumberReached);
        
        // Test again saveresult with no selectedDate. the result should be same as 
        // previous test, since Savepoint function should default the date to today
        selectedDate = '' ;
        saveResult = challengeManagerController.savePoints(userInfo.GetuserId(), 
                                                 String.valueOf(challenges[0].id), 
                                                 String.valueOf(selectedDate), 1);
         
        // In this case only 10 * 1000 and additional 1000 points in the previous step 
        // are awarded, out of 15000 bucket balance. So saveresult should still be 
        // true and max since bucket balance is higher than total awarded. 
        
        system.assertEquals(true, saveResult.Success);
        system.assertEquals(null, saveResult.message);
        system.assertEquals(true, saveResult.maxNumberReached); 
        Test.stopTest();
        }
    
    }


    
  // 3. Negative Test Case
  public static testmethod void ChallengeManagerControllerNegativeTest(){
    User u = AGETestUtility.createTestUser();
    system.runAs(u) {
            
      // Create test data
        Integer numOfChallenges = 10;
        Integer awardPointsAmt = 1000;
        Integer bucketBalance = 10000;
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
        //  do not Create test points records now                                              
         
        Test.startTest();
        List<UserChallengeCounter> userChellengeCounters = 
             challengeManagerController.getAJChallengeMap(UserInfo.getUserId()) ;         
        Integer maxawardReached = 0;
        for(UserChallengeCounter userChellengeContr: userChellengeCounters){
            if(userChellengeContr.maxNumberReached == true)
                maxawardReached ++;
        }
        
        
        // check if the test user reached Maxpoints on each of the challenge
        // Since there is no points awarded to user, none of the test challenges 
        // should have maxed out and maxawardReached should be 0
        system.assertEquals(0, maxawardReached);
        
        // now award points to the challenges
         
        AGETestUtility.createPoints(challenges);
        
        ChallengeManagerController.SaveResult saveResult = 
                                     new ChallengeManagerController.saveResult() ; 
        String selectedDate = Date.today().format();
        saveResult = challengeManagerController.savePoints(userInfo.GetuserId(), 
                                                 String.valueOf(challenges[0].id), 
                                                 String.valueOf(selectedDate), 1);
         
        // If All the 10000 points in the bucket used, all the related challenges
        // should be Inactive. If challenges are inactive no points can be awarded
        // to inactive challenges. Since all 10 * 1000 points are awarded result 
        // should be false 
        
        system.assertEquals(false, saveResult.Success);
        system.assert(saveResult.message != null);
        
        // since ppoints cannot be awarded for inactive challenge, maxNumber
        // reached should be null.
        system.assertEquals(null, saveResult.maxNumberReached);
        
        
        Test.stopTest();
    }
        
    }
}