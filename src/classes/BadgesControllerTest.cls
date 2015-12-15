//
// (c) Appirio 
//
// This test class BadgesControllerTest covers the following
// 1. BadgesController class

//
// 10/01/13     Guna Sevugapperumal     Original
// 10/15/13     Guna Revised the test class for best practice adoption
// 09/22/15     Josh Tuttle - Updated for S-161785

@isTest(SeeAllData=true)
private class BadgesControllerTest {
    static testMethod void BadgeControllerPositiveTest() {
            User testUser = AGETestUtility.createTestUser();
        system.runAs(testUser) {     
        Test.startTest();
        // Check for the current user
            PageReference pageRef = Page.Challenges;
        Test.setCurrentPage(pageRef);
        BadgesController contr = new BadgesController(); 
        System.assertEquals(contr.selectedEmployee, userInfo.getUserId());
        
        // Check if the picklist values for corevalues  are returned
        List<String> coreValues = BadgesController.getCoreValueTypes();
        system.assert(coreValues.size() > 0);
             
        // Check if the picklist values for focusTypes  are returned
        List<String> focusTypes = BadgesController.getFocusTypes();
            system.assert(focusTypes.size() > 0);
        
        // Create test data
        Integer numOfChallenges = 10;
        Integer awardPointsAmt = 1000;
        Integer bucketBalance = 10000;
        String  bucketName = 'Test Certification Bucket';
        String  badgeName = 'Test Certification Master';
      
     
        // Create test collaboration group
        CollaborationGroup collabGroup = AGETestUtility.createTestCollaborationGroup();
      
        //badges in the DB BEFORE the test to create a badge      
        List<BadgesController.BadgeHolder> badgeHoldersBeforeTest = 
                           BadgesController.getAllBadges(userInfo.getUserId());
      
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
        
        
        // Test the getAllBadges method
        List<BadgesController.BadgeHolder> badgeHolders = 
                           BadgesController.getAllBadges(userInfo.getUserId());
        
        // Created only one test badge, this test checks that the new badge count
        // is the count of badges before the test creation PLUS the additional test badge
        system.AssertEquals(badges.size() + badgeHoldersBeforeTest.size(), badgeHolders.size());
        
        
        for(BadgesController.BadgeHolder badgeHolder: badgeHolders){
          if(badgeHolder.getThisBadge().title__c == badgeName){
            // Only one test badge record created so that should be retuned
            system.assertEquals(badgeName, badgeHolder.getThisbadge().title__c);
            // Since the badge is awarded, number of badgeChallenge junction 
            // record should be equal to numOfChallenges
            system.assertEquals(numOfChallenges, badgeHolder.getThisChallenges().size()); 
            }
        }    
        
        // Check getNewBadgeURL method by getting the badge__C object id from schema
        String newBadgeURL = '';
        Schema.DescribeSObjectResult r = Badge__c.sObjectType.getDescribe();
        newBadgeURL = '/' + r.getKeyPrefix() + '/o'; 
        
        system.assertEquals(newBadgeURL, badgesController.getNewBadgeURL());                                     
        
        // Insert a awarded badge record to see if it is inserting
        String selectedUserId = UserInfo.getUserId();
        String selectedBadgeId = [SELECT id FROM Badge__c where active__c = true LIMIT 1].id;
        String selectedDate = system.today().format();
        Boolean awardedBadgeSaved = true;

        System.debug('About to saveAwardedBadge.');

        BadgesController.SaveResult saveResult = 
                                              BadgesController.saveAwardedBadge(
                                              selectedUserId, 
                                              selectedBadgeId, 
                                              selectedDate);

        System.debug('SaveResult : ' + saveResult);
        
        // the save result should be success or true since all values passed
        system.assertEquals(awardedBadgeSaved, saveResult.success);
        
        
        Test.StopTest();
        }
    }


	static testMethod void BadgeControllerNegativeTest() {
        User testUser = AGETestUtility.createTestUser();
        User uEmp = AGETestUtility.createTestEmployeeUser();
		system.runAs(testUser) {     
        Test.startTest();
            // Create test data
            Integer numOfChallenges = 5;
            Integer awardPointsAmt = 1000;
            Integer bucketBalance = 10000;
            String  bucketName = 'Test Certification Bucket';
            String  badgeName = 'Test Certification Master';
            
            
            // Create test collaboration group
            CollaborationGroup collabGroup = AGETestUtility.createTestCollaborationGroup();
            
            List<BadgesController.BadgeHolder> badgeHoldersBeforeTest = 
                               BadgesController.getAllBadges(userInfo.getUserId());
            
            // Create a test badge record
            List<badge__c> badges = AGETestUtility.createTestBadges(badgeName);
            badges[0].Multi_Award__c=false;
            update badges;
            
            
            
            // Create test point Bucket    
            List<points_bucket__c> pointbuckets = AGETestUtility.CreatePointsBuckets(bucketName,bucketBalance);
            
            // Create test challenge records
            List<Challenge__c> challenges = AGETestUtility.CreateChallenge(
                                                         numOfChallenges, 
                                                         awardPointsAmt, 
                                                         badges[0],
                                                         pointbuckets[0]);
            // Create test points records                                               
            AGETestUtility.createPoints(challenges);
            
            
            
            List<BadgesController.BadgeHolder> badgeHolders = 
                                            BadgesController.getAllBadges(uEmp.Id);
                                            
            system.AssertEquals(badges.size() + badgeHoldersBeforeTest.size(), badgeHolders.size());
            
            //  Test awarded badges, but check inserting awarded badge fails
            // by not providing badgeId and leaving the SelectedDate empty.
            String selectedUserId = UserInfo.getUserId();
            String selectedBadgeId = badges[0].Id; 
            String selectedDate = '';
            Boolean awardedBadgeSaved = false;
            
            //once we award the badge
            BadgesController.SaveResult saveResult = 
                                               BadgesController.saveAwardedBadge(
                                               selectedUserId, 
                                               selectedBadgeId, selectedDate);
            
            /***   
            
            // since the badge id i is not provided the save award should fail
            // the save result should be false
            ** you cannot pass the badge id to be null as the code does not take care of the condition when the list has 0 records
            
            */
            
            //after that try to award the same badge
            saveResult = BadgesController.saveAwardedBadge(
                                               selectedUserId, 
                                               selectedBadgeId, 
                                               selectedDate);
            
            system.assertEquals(awardedBadgeSaved, saveResult.success);
        Test.stopTest();
		}
	}
}
