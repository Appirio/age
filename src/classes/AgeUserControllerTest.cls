/**************************************************************************************
//Name            : Test class AgeUserControllerTest
//Description     : This test class AgeUserControllerTest covers the unit of the following
//                : 1. AgeUserController class
//
//Author          : Guna Sevugapperumal Created 19 Sep, 2013
//Update          :  
***************************************************************************************/
@isTest
public class AgeUserControllerTest{
    
    // 1. Prepare test data
    public static void setGameSecurity(Boolean createNewChallenge, Boolean awardPoints, Boolean createNewBadge){
        Game_Security__c gameSecurity = new Game_Security__c(SetupOwnerId = userinfo.getUserId(), 
                                                             Create_New_Challenge__c = createNewChallenge, 
                                                             Award_Points_to_Another_User__c = awardPoints, 
                                                             Create_New_Badge__c = createNewBadge);
        insert gameSecurity;
        
    }
    // 2. Run Positive Test case
    public testmethod static void ageUserControllerPositiveTest() {
        Integer userCount = AgeUserController.getAllUsers().size();
        User u = AGETestUtility.createTestEmployeeUser();
        System.runAs(u) {
            
            Test.startTest();
            
            // Insert a Game security setting for the test user
            setGameSecurity(true, true, true);
            
            // Check if the user has SmallPhotoUrl value;         
            User loggedUser = AgeUserController.getLoggedInUser();
            system.assert(loggedUser.SmallPhotoUrl.length() > 0);
            
            // Check if user count incresed by 1 after 
            system.assertequals(userCount+1, AgeUserController.getAllUsers().size());
            
            // Check the Game security
            Game_Security__c gameSecurity = AgeUserController.getUserSecuritySettings();
            system.assert(gameSecurity.Create_New_Challenge__c == true);
            system.assert(gameSecurity.Award_Points_to_Another_User__c == true);
            system.assert(gameSecurity.Create_New_Badge__c == true);
            
            Test.stopTest();
        }
    }
    
    // 3. Run Negative Test case
    public testmethod static void ageUserControllerNegativeTest() {
        AgeUserController contr = new AgeUserController();
        User u = AGETestUtility.createTestEmployeeUser();        
        System.runAs(u) {
            Test.startTest();
            
            // Insert a Game security setting for the test user
            setGameSecurity(false, false, false);
            
            // Check the Game security
            Game_Security__c gameSecurity = AgeUserController.getUserSecuritySettings();
            system.assertEquals(false, gameSecurity.Create_New_Challenge__c);
            system.assertEquals(false, gameSecurity.Award_Points_to_Another_User__c);
            system.assertEquals(false, gameSecurity.Create_New_Badge__c); 
            
            Test.stopTest(); 
        }
        
    }
    
    

}