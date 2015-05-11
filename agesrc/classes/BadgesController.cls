public class BadgesController extends AgeUserController{

//
// (c) Appirio 
//
// Appirio's Gamification App
//    This controller allows users to enter in their completed challenges and 
//    collect the points earned associated to such challenge
//
// 9/26/13     Kym Le     Original
// 9/30/2013   Guna Sevugapperumal  added 2 methods to BatchHolder inner
//                                  class for covering unit test
//

  public String selectedEmployee {get; set;}

  public BadgesController(){
  
    // URL parameter may specify a particular user for the "Appirian:" picklist
    selectedEmployee = ApexPages.CurrentPage().getParameters().get('userId');
  
    // otherwise, picklist should default to the current user
    if (selectedEmployee == null) selectedEmployee = UserInfo.getUserId();  
  
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
  public static List<BadgeHolder> getAllBadges(String selectedEmployee) {
  
    List<Badge__c> allBadges = [SELECT Id, 
                                       Title__c, 
                                       Image_Url__c,
                                       Focus__c, 
                                       Core_Value__c, 
                                       Active__c,
                                       Description__c,
                                       (SELECT Id, 
                                               CreatedDate 
                                        FROM   Awarded_Badges__r 
                                        WHERE  User__c = :selectedEmployee
                                        ORDER By CreatedDate Desc
                                        LIMIT 1) 
                                FROM   Badge__c];
                              
    List<Badge_Challenge__c> allBadgeChallenges = [SELECT Badge__c, 
                                                          Badge_Title__c, 
                                                          Challenge__c, 
                                                          Challenge_Title__c, 
                                                          Tag_Match__c 
                                                   FROM   Badge_Challenge__c];
    
    
    Map<Id, BadgeHolder> badgeHolderMap = new Map<Id, BadgeHolder>();
    
    for(Badge__c b : allBadges) {
      badgeHolderMap.put(b.Id, new BadgeHolder(b));
    
    }                           
    
    for (Badge_Challenge__c bc : allBadgeChallenges) {
      badgeHolderMap.get(bc.badge__c).addBadgeChallenge(bc);
    
    }
                              
    return badgeHolderMap.values();                          
  }
  
  
  @RemoteAction
  public static SaveResult saveAwardedBadge(String selectedUserId, String selectedBadgeId, String selectedDate) {
    Awarded_Badge__c ab = new Awarded_Badge__c();
        
    ab.User__c = selectedUserId;
    ab.Badge__c = selectedBadgeId;
    
    if (selectedDate == '') {
      ab.Effective_Date__c = Date.Today(); 
    } else {
      ab.Effective_Date__c = date.parse(selectedDate); 
    }
    
    SaveResult sr = new SaveResult();
       
    try {
        insert ab;
        sr.success = true;
                                                      
    } catch (Exception e) {
        sr.success = false;
        sr.message= 'FAIL!' + e.getMessage();
    } 
     
    return sr;
  }
  
  public class SaveResult{
  
    public Boolean success;
    public String message;
  
  }
  
  @RemoteAction
  public static String getNewBadgeURL(){
    String newBadgeURL = '';
    
    Schema.DescribeSObjectResult r = Badge__c.sObjectType.getDescribe();
    System.debug(r);
    
    if (r != null){
      newBadgeURL = '/' + r.getKeyPrefix() + '/o';
    }
    
    return newBadgeURL;
    
  }
  
  public class BadgeHolder{
    private Badge__c badge{get;set;}
    private List<Badge_Challenge__c> badgeChallenges{get;set;}
  
    public BadgeHolder(Badge__c b) {
      badge = b;
      badgeChallenges = new List<Badge_Challenge__c>();
    }
    
    
    public void addBadgeChallenge(Badge_Challenge__c bc) {
      badgeChallenges.add(bc);
    }
    // Guna added this to cover the test cases Sep 30 2013
    public Badge__c getThisBadge(){
        return badge;
    }
   
    // Guna added this to cover the test cases Sep 30 2013 
    public List<Badge_Challenge__c> getThisChallenges(){
        return badgeChallenges;
    }
    
  }
}