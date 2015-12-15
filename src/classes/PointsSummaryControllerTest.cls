/*****************************************************************************
 * Created By       : Kuran Nayee(Appirio Indianapolis)
 * Created Date     : 18 Sept, 2013.
 * Usage            : PointsSummaryControllerTest class covers the following
 *                  : 1. PointsSummaryController class
 *                  : 2. BeforeInsertAndAfterDeletePoints trigger
 *                  : 3. afterInsertAwardedBadge trigger
 *                  : 10/17/2013 Guna updated to call the modified utility class
 *                  :            for test record creation
******************************************************************************/

// 
// 2013-10-19     Glenn Weinstein     Modified to account for replacement of employee picklist with a lookup
//

@isTest(SeeAllData=true)
public with sharing class PointsSummaryControllerTest {

    static testMethod void getSet() {
        Test.startTest();

        // Testing Get, Set Methods because they are public
        PointsSummaryController emp = new PointsSummaryController();
        emp.pointsEarnedTotal = 5;
        System.assertEquals(5, emp.pointsEarnedTotal);

        emp.pointsEarnedThisQuarter = 20;
        System.assertEquals(20, emp.pointsEarnedThisQuarter);
          
        emp.pointsBalance = 40;
        System.assertEquals(40, emp.pointsBalance);
          
        Test.stopTest();
    }
    
    // Test methods to create : EmployeeOptions, Getpoints, Removepoints,
    
    public static testMethod void employeeOptionsTest() {
        Test.startTest();
      
        // 1. Create test data - can't assume same # of Users in all orgs
        // 2. Get the employee options list
        // 3. Verify what's in the list
    
        List<User> testUsers = createTestUsers();
        insert testUsers;
      
        Set<Id> testUserIds = new Set<Id>();  // This may need to be Set<String>
      
        for (User testUser : testUsers) {
            testUserIds.add(testUser.Id);
        }
      
        User testUser = testUsers[0];
 
      
        Test.stopTest(); 
    }
    
    
    public static testMethod void getPointsTest(){
    
        // 1. Create user to assign points
        // 2. Get points for each user created
        // 3. Verify that each user has the same amount of points assigned.
    
        Test.startTest();
    
        List<User> testUsers = createTestUsers();
        insert testUsers;
        
        

        System.runAs(testUsers[0]) {
              List<Points__c> addPoints = createPoints(testUsers);
                insert addPoints;
            PointsSummaryController emp = new PointsSummaryController();
            List<PointsSummaryController.AgeUserPointsSummary> points = emp.getPoints();
            System.assertEquals(0, points.size()); 
            System.assertEquals(0, emp.pointsEarnedTotal);       
            System.assertEquals(0, emp.pointsEarnedThisQuarter);         
            System.assertEquals(0, emp.pointsBalance);         
        }  
        
        System.runAs(testUsers[1]) {
            PointsSummaryController emp = new PointsSummaryController();
            List<PointsSummaryController.AgeUserPointsSummary> points = emp.getPoints();
            System.assertEquals(5, points.size());
            System.assertEquals(14, emp.pointsEarnedTotal);
            System.assertEquals(8, emp.pointsEarnedThisQuarter);         
            System.assertEquals(14, emp.pointsBalance);        
        } 
        
        System.runAs(testUsers[2]) {
            PointsSummaryController emp = new PointsSummaryController();
            List<PointsSummaryController.AgeUserPointsSummary> points = emp.getPoints();
            System.assertEquals(5, points.size());
            System.assertEquals(15, emp.pointsEarnedTotal);
            System.assertEquals(9, emp.pointsEarnedThisQuarter);         
            System.assertEquals(15, emp.pointsBalance);        
        } 
        

        Test.stopTest(); 
    }
    
    static testMethod void removePointsTest(){
        Test.startTest();
    
        List<User> testUsers = createTestUsers();
        insert testUsers;
        
        
        
        System.runAs(testUsers[1]) {
                    List<Points__c> addPoints = createPoints(testUsers);
                    insert addPoints;
            PointsSummaryController emp = new PointsSummaryController();
            List<PointsSummaryController.AgeUserPointsSummary> points = emp.getPoints();
            emp.selectedPointsId = points[1].Id;
            emp.removePoints(); 
            List<Points__c> removeSelected = [ SELECT Name 
                                            FROM   Points__c 
                                            WHERE  Id = :points[1].Id ];
            System.assertEquals(0, removeSelected.size()) ; 

        }  
    
         
        
          

        Test.stopTest(); 
    }
    
    // 1. Create Test Data
    private static List<User> createTestUsers() {
      
        List<User> testUsers = new List<User>() ;
        Profile p = [select id from profile where name='System Administrator'];
 
        User u = new User(alias = 'TSAdmin', email='testsystemadminuser@testorg.com', 
            emailencodingkey='UTF-8', lastname='TestLastName', firstName='FirstName', languagelocalekey='en_US', 
            localesidkey='en_US', profileid = p.Id, 
            timezonesidkey='America/Los_Angeles', username='AppirioAGETestUser1'+Datetime.now().format('MM.dd.yyyy.HH.mm.ss')+'@appirio.com');
        testUsers.add(u); 

        u = new User(alias = 'TSAdmin2', email='testsystemadminuser@testorg.com', 
            emailencodingkey='UTF-8', lastname='TestLastName', firstName='FirstName', languagelocalekey='en_US', 
            localesidkey='en_US', profileid = p.Id, 
            timezonesidkey='America/Los_Angeles', username='AppirioAGETestUser2'+Datetime.now().format('MM.dd.yyyy.HH.mm.ss')+'@appirio.com');
        testUsers.add(u); 

        u = new User(alias = 'TSAdmin3', email='testsystemadminuser@testorg.com', 
            emailencodingkey='UTF-8', lastname='TestLastName', firstName='FirstName', languagelocalekey='en_US', 
            localesidkey='en_US', profileid = p.Id, 
            timezonesidkey='America/Los_Angeles', username='AppirioAGETestUser3'+Datetime.now().format('MM.dd.yyyy.HH.mm.ss')+'@appirio.com');
        testUsers.add(u);

        // Return list of 3 test users we created          
        return testUsers;   
    }
    
    private static List<Points__c> createPoints(List<User> usersWithPoints) {
        
        List<Points__c> addPoints = new List<Points__c>();
        //List<Challenge__c> challenges = AgeTestUtility.CreateChallenge(10, 10);
        
        // Create test Challenges and points
        Integer numOfChallenges = 10;
        Integer awardPointsAmt = 10;
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
         
        
      
        // Not = Null
        Points__c point = new Points__c(User__c = usersWithPoints[1].Id, Amount__c = 2, Date__c = Date.parse('12/27/2009'), Challenge__c = challenges[0].id);
        addPoints.add(point);

        //  Greater than 0
        point = new Points__c( User__c = usersWithPoints[1].Id, Amount__c = 4, Date__c = Date.parse('12/27/2009'), Challenge__c = challenges[1].id);
        addPoints.add(point);
        
        // Less than 0
        point = new Points__c( User__c = usersWithPoints[1].Id, Amount__c = -5, Date__c = Date.parse('12/27/2009'), Challenge__c = challenges[2].id);
        addPoints.add(point);
        
        // Greater than 0 and in current quarter
        point = new Points__c( User__c = usersWithPoints[1].Id, Amount__c = 8, Date__c = Date.today(), Challenge__c = challenges[3].id);
        addPoints.add(point);
        
        // Less than 0 and in current quarter
        point = new Points__c( User__c = usersWithPoints[1].Id, Amount__c = -7, Date__c = Date.today(), Challenge__c = challenges[4].id);
        addPoints.add(point);
        
        //User 2
        
        // Not = Null
        point = new Points__c(User__c = usersWithPoints[2].Id, Amount__c = 2, Date__c = date.parse('12/27/2009'), Challenge__c = challenges[5].id);
        addPoints.add(point);

        //  Greater than 0
        point = new Points__c( User__c = usersWithPoints[2].Id, Amount__c = 4, Date__c = date.parse('12/27/2009'), Challenge__c = challenges[6].id);
        addPoints.add(point);
        
        // Less than 0
        point = new Points__c( User__c = usersWithPoints[2].Id, Amount__c = -5, Date__c = date.parse('12/27/2009'), Challenge__c = challenges[7].id);
        addPoints.add(point);
        
        // Greater than 0 and in current quarter
        point = new Points__c( User__c = usersWithPoints[2].Id, Amount__c = 9, Date__c = Date.today(), Challenge__c = challenges[8].id);
        addPoints.add(point);
        
        // Less than 0 and in current quarter
        point = new Points__c( User__c = usersWithPoints[2].Id, Amount__c = -7, Date__c = Date.today(), Challenge__c = challenges[9].id);
        addPoints.add(point);
                
        // Return list of userswithPoints
        return addPoints;
    }
    
    // Guna added to test thisQuarter function
    // Assign dates with different month. It is dificult to assert since
    // this month is hard coded inside the method
    public static testmethod void testThisQuarter(){
    PointsSummaryController pointsSummary = new PointsSummaryController();
      Date testDate = Date.today();
      pointsSummary.thisQuarter(testDate);
    }
    
    public static testmethod void testRemoveBadge(){
            PointsSummaryController pointsSummary = new PointsSummaryController();
            pointsSummary.removeBadge();
            
            // There is nothing to assert the output value.
            
            List<Awarded_Badge__c> testbadges = pointsSummary.getBadges();
            // I noticed above function was just added a moment ago.
            // I think the entire test case wriiten by Kuran is very confusing
            // needs to rewritten
    }
    
     
}