public class AgeProfileManagerController extends AgeUserController {

//
// (c) Appirio 
//
// Appirio's Gamification App
//    This controller allows users to enter in their completed challenges and 
//    collect the points earned associated to such challenge
//
// 7/30/13     Kym Le     Original
//

  public String user;
  
  
  public AgeProfileManagerController() { 
  
    // URL parameter may specify a particular user for the profile
    user = ApexPages.CurrentPage().getParameters().get('userId');
  
    // otherwise, profile should  default to the current user
    if (user == null) user = UserInfo.getUserId();
    
  }
  
  public String getDisplayUserTimeZone() {
    
    String timeZoneShort = '';
  
    User user = [SELECT TimeZoneSIDKey 
                 FROM   User 
                 WHERE  Id = :user];
                 
    TimeZone userTimeZone = TimeZone.getTimeZone(user.TimeZoneSIDKey);
    String timeZoneName = userTimeZone.getDisplayName();
  
    List<String> timeZoneParts = timeZoneName.split(' ');
      
    for (String s : timeZoneParts) {
      String firstLetter = s.substring(0,1);
      timeZoneShort += firstLetter;
    }
    
    return timeZoneShort;
  }
  
  public User getDisplayUser(){
  
    return [SELECT Name,
                   CompanyName,
                   Title,
                   City,
                   State,
                   Country,
                   Facebook_URL__c,
                   LinkedIn_URL__c,
                   Twitter_URL__c,
                   AGE_Profile_Quote__c,
                   Start_Date__c,
                   Email,
                   Phone,
                   MobilePhone,
                   TimeZoneSidKey,
                   Manager.Name,
                   FullPhotoUrl,
                   SmallPhotoUrl
            FROM   User 
            WHERE  Id = :user];
  }

  public Decimal getTotalPoints(){
    
    AggregateResult[] totalPointsEarned = [SELECT SUM(Amount__c) points
                                           FROM   Points__c
                                           WHERE  User__r.Id = :user 
                                           AND    RecordType.Name = 'Earned Points'
                                           AND    Amount__c > 0];
    
    if (totalPointsEarned[0].get('points')==null) {
      return 0;
    } else {                                              
      return (Decimal)totalPointsEarned[0].get('points');
    }                                                     
  }
  
  public Decimal getQuarterPoints(){
    
    AggregateResult[] quarterPointsEarned = [SELECT SUM(Amount__c) points
                                             FROM   Points__c
                                             WHERE  User__r.Id = :user 
                                             AND    Amount__c > 0
                                             AND    RecordType.Name = 'Earned Points'
                                             AND    Date__c = THIS_QUARTER];
                                
    if (quarterPointsEarned[0].get('points')==null) {
      return 0;
    } else {                                              
      return (Decimal)quarterPointsEarned[0].get('points');
    }                            
  }
  
  
  public List<Points__c> getPoints() {
    return [SELECT   Id,
                     Challenge__c,
                     Challenge_Title__c,
                     CreatedDate
            FROM     Points__c
            WHERE    User__r.Id = :user
            AND      Amount__c > 0
            AND      Challenge__c != ''
            ORDER BY CreatedDate DESC
            LIMIT 5];
  }
  
  
  public Decimal getLastThirtyDaysPoints(){    
    
    AggregateResult[] last30DaysPointsEarned = [SELECT SUM(Amount__c) points
                                                FROM   Points__c
                                                WHERE  User__r.Id = :user 
                                                AND    Amount__c > 0
                                                AND    RecordType.Name = 'Earned Points'
                                                AND    Date__c = LAST_N_DAYS:30];  
                                                
    if (last30DaysPointsEarned[0].get('points')==null) {
      return 0;
    } else {                                              
      return (Decimal)last30DaysPointsEarned[0].get('points');
    }
  }
  
  public List<Badge__c> getBadges() {
    List<Badge__c> badgeUrl = new List<Badge__c>();
    
    //@added the order by to sort latest to older
    List<Awarded_Badge__c> badges = [SELECT 
                   Badge__r.Image_Url__c, 
                   Badge__r.Title__c
            FROM   Awarded_Badge__c
            WHERE  User__r.Id = :user 
            ORDER BY Effective_Date__c DESC];
           
    for(Awarded_Badge__c ab : badges) {
      Badge__c awardedBadge = new Badge__c();
      awardedBadge.Title__c = ab.Badge__r.Title__c;
      awardedBadge.Image_Url__c = ab.Badge__r.Image_Url__c;
      badgeUrl.add(awardedBadge);        
    }
    
    if (badgeUrl.size() < 4) {
      Integer countTo = 4 - badgeUrl.size();
      
      for (integer i = 0; i < countTo; i++){
        Badge__c badge = new Badge__c();
        badge.Image_Url__c = '/resource/1378764846000/AgeResources/i/badges/badge-3.jpg';
        badgeUrl.add(badge);
      }
    }
    
    return badgeUrl;
  }
  
  
  
  public String getChatterURL() {
    String staticURL = 'https://chattereverywhere-staging.herokuapp.com/client/base/?instance_url=';
    String appEnvironmentURL = URL.getSalesforceBaseUrl().toExternalForm();
    String staticAccessTokenURL = '&access_token=';
    String sessionId = UserInfo.getSessionId();
    String staticGroupText = '#/groups/';
    String chatterGroupId = Game_Settings__c.getInstance().Chatter_Group_ID_All_Activities__c;
    String chatterButtonOptions = '?refreshbtn&linkbtn&notify&gallery';
    
    
    return staticURL + appEnvironmentURL + staticAccessTokenURL + sessionId + staticGroupText + chatterGroupId + chatterButtonOptions;
  }

}