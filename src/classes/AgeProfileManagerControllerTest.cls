/******************************************************************************
//Name            : Test class AgeProfileManagerControllerTest
//Description     : This test class covers the unit of the following
//                : 1. AgeProfileManagerController class
//              
//
//Author          : Guna Sevugapperumal Created 18 Sep, 2013
//Update          : Guna Sevugapperumal update  03 Oct  2013 changed the name of the utility class

// 
// 2013-10-13     Glenn Weinstein     Removed assertion on getQuarterPoints() that was making a bad assumption
//                                    about what points would land in the current quarter
// 2013-10-14     Guna Sevugapperumal Re-wrote the test class to adapt to best practices
******************************************************************************/
@isTest(SeeAllData=true)
public class AgeProfileManagerControllerTest{   
  // 1. Run Positive test case
  public static testmethod void runPositiveTestCase(){
        
    // Create test user
    User u = AGETestUtility.CreateTestUser();
    System.runAs(u) { 
             
      // Create test data
      Integer numOfChallenges = 10;
      Integer awardPointsAmt = 1000;
      Integer bucketBalance = 10000;
      String  bucketName = 'Test Certification Bucket';
      String  badgeName = 'Test Certification Master';
     
      AggregateResult[] quarterPointsEarnedBeforeTest = [ SELECT SUM(Amount__c) points
                                                FROM   Points__c
                                                WHERE  Amount__c > 0
                                                AND    CreatedDate = THIS_QUARTER];
     
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
            AgeProfileManagerController contr = new AgeProfileManagerController();
      test.startTest();
            
      // test getDisplayUser function
      User usr = contr.getDisplayUser();
      System.assertEquals('FirstName TestLastName', usr.name);
      
      // test getTotalPoints function
      Decimal totalPoints = contr.getTotalPoints();
      integer expectedPoints = numOfChallenges * awardPointsAmt;
      System.assertEquals(expectedPoints, totalPoints);
            
      // test getQuarterPoints function
      Decimal quarterPoints = contr.getQuarterPoints();
      AggregateResult[] quarterPointsEarned = [ SELECT SUM(Amount__c) points
                                                FROM   Points__c
                                                WHERE  Amount__c > 0
                                                AND    User__r.Id = :u.Id
                                                AND    RecordType.Name = 'Earned Points'
                                                AND    CreatedDate = THIS_QUARTER];
                                                
                                
        
      //expectedPoints = Integer.valueOf(quarterPointsEarned[0].get('points'));     
      //System.assertEquals(Integer.valueOf(quarterPointsEarned[0].get('points')), quarterPoints);
      //System.assertEquals(u.Id, usr.Id); 
       
      // Check getLast30DaysPoint function   
      Decimal lastThirtyDaysPoints = contr.getLastThirtyDaysPoints();
      quarterPointsEarned = [   SELECT SUM(Amount__c) points
                                                    FROM   Points__c
                                                    WHERE  Amount__c > 0
                                                    AND    User__r.Id = :u.Id
                                                    AND    RecordType.Name = 'Earned Points'
                                                    AND    CreatedDate = LAST_N_DAYS:30];
      expectedPoints = Integer.valueOf(quarterPointsEarned[0].get('points'));
      //System.assertEquals(expectedPoints, lastThirtyDaysPoints);
      
      // check GetPoints function. This value can be equal to  numOfChallenges
      // created. If numOfChallenges < 5 then result should be numOfChallenges.
      // else the result should be 5(since the function query LIMIT is set to 5) 
      List<points__c> points = contr.getPoints();
      if (numOfChallenges <= 5)
        System.assertEquals(numOfChallenges, points.size());
      else
        System.assertEquals(5, points.size());
        
      // check the getbadge function. Since only one test badge is created 
      // there should be only one badge awarded badge returned and 3 dummy image
      // should be returned. There should be total 4 

      List<badge__c> badgeurls = contr.getBadges();
      System.assertequals(badges.size() + 3, badgeurls.size());
      
      // this is straight forward the timezone short value should be returned
      // for all users
      system.assert(contr.getDisplayUserTimeZone().length() > 0);
      
      // Check getChatterURL function. as per the function this will always return
      // a static url.
      try{
        String chatterURL = contr.getChatterURL();
      }
      catch(Exception e){
        system.debug('Cannot get the chatterURL data');          
      }
            
      test.stopTest();
            
    }
  }
    
   
    // 2. Run Negative test case
    public static testmethod void runNegativeTestCase(){
        User uEmp = AGETestUtility.CreateTestEmployeeUser();
        // The following code runs as user 'u'
        System.runAs(uEmp) {
             
          // Create test data and assign no points      
            Integer numOfChallenges = 10;
            Integer awardPointsAmt = 0;
            Integer bucketBalance = 10000;
            String  bucketName = 'Test Certification Bucket';
            String  badgeName = 'Test Certification Master';
            // Create test collaboration group
                CollaborationGroup collabGroup = AGETestUtility.createTestCollaborationGroup();
      
                // Create a test badge record
                List<badge__c> badges = AGETestUtility.createTestBadges(badgeName);
            
            
            //Create test point Bucket, Challenges and award no points to challege    
            List<points_bucket__c> pointbuckets = 
                                            AGETestUtility.CreatePointsBuckets(
                                                                            bucketName, 
                                                                            bucketBalance);
            try{
                List<Challenge__c> challenges = AGETestUtility.CreateChallenge(
                                                     numOfChallenges, 
                                                     awardPointsAmt, 
                                                     badges[0],
                                                     pointbuckets[0]);
            
            AGETestUtility.createPoints(challenges);
            }
            catch(DmlException e){
                system.debug('Insufficient user privilege');
          }
 
          AgeProfileManagerController contr = new AgeProfileManagerController();
          test.startTest();
         
          // test each controller functions for negative test
          User usr = contr.getDisplayUser();
          System.assertEquals('TestLastName', usr.name);
          
          // Since no points amount provided there should not be any points awarded to
          // user
          Decimal totalPoints = contr.getTotalPoints();
          System.assertEquals(awardPointsAmt, totalPoints);
          Decimal quarterPoints = contr.getQuarterPoints();
          System.assertEquals(awardPointsAmt, quarterPoints);
          Decimal lastThirtyDaysPoints = contr.getLastThirtyDaysPoints();
          System.assertEquals(awardPointsAmt, lastThirtyDaysPoints);
          
          // Since each awardPoints is zero amount there should not be any 
          // points record with amount greater than 0
          List<points__c> points = contr.getPoints();
          System.assertEquals(awardPointsAmt, points.size());
          
          
          test.stopTest();
            
        }
        
    }
}