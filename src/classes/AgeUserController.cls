public virtual class AgeUserController {

  
  public AgeUserController(){
  
  }
  
  @RemoteAction
  public static User getLoggedInUser(){
  
    return [SELECT Name,
                   SmallPhotoUrl
            FROM   User
            WHERE  Id = :UserInfo.getUserId()];
  }


  @RemoteAction
  public static List<User> getAllUsers() {
    
    return [SELECT   Id, 
                     Name, 
                     FirstName,
                     Full_Name__c 
            FROM     User 
            WHERE    Usertype = 'Standard'
            AND      isActive = true
            ORDER BY Full_Name__c];
  }

  @RemoteAction
  public static Game_Security__c getUserSecuritySettings() {
  
    List<Game_Security__c> userSecurity =  [SELECT SetupOwnerId, 
                   Create_New_Challenge__c, 
                   Award_Points_to_Another_User__c,
                   Award_Badge_to_Another_User__c,                    
                   Create_New_Badge__c 
            FROM   Game_Security__c
            WHERE  SetupOwnerId = :UserInfo.getUserId() Limit 1]; 
    
    if (userSecurity.size() == 0) {
      return new Game_Security__c();
    }     
            
    return userSecurity[0];
  }
}