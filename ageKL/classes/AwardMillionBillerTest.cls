@istest(SeeAllData=true)
class AwardMillionBillerTest {

// (c) Appirio 2014
//
// Test class to test awarding employees that have billed > 1M in their time cards.
// Had to use 'SeeAllData=true' because there were so many downstream SOQL inserts
// to test and I was hitting the governor.  
//
// 03/14/2014     Kym Le              Original
// 07/13/2014     Glenn Weinstein     Commenting out testMillionBillerPositive() - it is painfully slow due to the
//                                    SOQL query.  It's taking 490 seconds!!!
//

  public static testmethod void testMillionBillerPositive(){  
    /*
    User u = AGETestUtility.CreateTestUser();
    System.runAs(u) { 
    
      String targetRecordId = Game_Settings__c.getInstance().Challenge_Million_Biller__c;
      Id resourceId;
    
      Test.startTest();
    
        //query the database for an employee that has reached > 1M
        List<AggregateResult> timeCards = [SELECT   pse__Resource__r.Name, 
                                                    pse__Resource__r.Id, 
                                                    SUM(T_M_Equivalent_Revenue__c) 
                                           FROM     pse__Timecard_Header__c 
                                           GROUP BY pse__Resource__r.Id, 
                                                    pse__Resource__r.Name 
                                           HAVING   SUM(T_M_Equivalent_Revenue__c) > 1000000 Limit 1];
                                         
        resourceId = (Id)timeCards[0].get('Id');          
          
        //call the award method from the AwardMillionBiller class    
        AwardMillionBiller.execute(timeCards);   
      
        //get the userId based on the resourceId
        Contact awardedContact = [SELECT pse__Salesforce_User__c
                                  FROM   Contact
                                  WHERE  Id = :resourceId];
                                
        //get the list of points for the user and narrow down the query based on the targetRecordId of
        //the MillionBiller challenge
        List<Points__c> points = new List<Points__c>([SELECT Id, 
                                                             Target_Record_Id__c, 
                                                             User__c, 
                                                             Challenge__c 
                                                      FROM   Points__c 
                                                      WHERE  User__c = :awardedContact.pse__Salesforce_User__c
                                                      AND    Target_Record_Id__c = :targetRecordId]); 
  
        //the user should have been awarded the points for the challenge  
        System.AssertEquals(1, points.size());                                                                     
    
      Test.stopTest();  
    }
    */
  }
  
  /*
  public static testmethod void testMillionBillerNegativeDoubleAward(){
    
    User u = AGETestUtility.CreateTestUser();
    System.runAs(u) { 
    
      String targetRecordId = Game_Settings__c.getInstance().Challenge_Million_Biller__c;
      Id resourceId;
    
      Test.startTest();
    
        //query the database for an employee that has reached > 1M
        List<AggregateResult> timeCards = [SELECT   pse__Resource__r.Name, 
                                                    pse__Resource__r.Id, 
                                                    SUM(T_M_Equivalent_Revenue__c) 
                                           FROM     pse__Timecard_Header__c 
                                           GROUP BY pse__Resource__r.Id, 
                                                    pse__Resource__r.Name 
                                           HAVING   SUM(T_M_Equivalent_Revenue__c) > 1000000 Limit 1];
                                         
        resourceId = (Id)timeCards[0].get('Id');     
        
        Challenge__c c = [SELECT Id FROM Challenge__c WHERE Name = :targetRecordId];     
                            
        //get the userId based on the resourceId      
        Contact awardedContact = [SELECT pse__Salesforce_User__c
                                  FROM   Contact
                                  WHERE  Id = :resourceId];

        //create a points record for the user and this particular challenge by the targetRecordId                            
        Points__c testPoints = new Points__c(User__c = awardedContact.pse__Salesforce_User__c, Target_Record_ID__c = targetRecordId,
                                             Challenge__c = c.Id, Awarded_From_Id__c = UserInfo.getUserId()); 
        insert testPoints;
      
        //call the award method from the AwardMillionBiller class        
        AwardMillionBiller.execute(timeCards);         
                                
        //get the list of points for the user and narrow down the query based on the targetRecordId of
        //the MillionBiller challenge
        List<Points__c> points = new List<Points__c>([SELECT Id, 
                                                             Target_Record_Id__c, 
                                                             User__c, 
                                                             Challenge__c 
                                                      FROM   Points__c 
                                                      WHERE  User__c = :awardedContact.pse__Salesforce_User__c
                                                      AND    Target_Record_Id__c = :targetRecordId]); 
        
        //the user should have been awarded only ONCE for the challenge 
        System.AssertEquals(1, points.size());                                                                     
    
      Test.stopTest();  
    }
  } */
  
}