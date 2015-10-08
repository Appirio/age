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
  
  Double lastThrityDayPoint;
  public Map<Id,Integer> badgeCount {get;set;}
  
  private AgeUser leaderboardAheadUser;
  private AgeUser leaderboardBehindUser;
  
  public class AgeUser {
  	
  	public AgeUser(User user,Decimal points,Integer rank){
  	  this.leaderboardUser = user;
  	  this.points = points;
  	  this.rank = rank;
  	}
  	
    public User leaderboardUser {get;set;}
    public Integer rank {get;set;}
    public Decimal points {get;set;}
  }
  
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
    
    /* updating method to exclude the challenges listed in shoutout challage */
    String  shoutoutChall = Game_Settings__c.getInstance().Shoutout_Challenge_Titles__c;
    List<String> listOfChall = shoutoutChall!=null ? shoutoutChall.split(','):new List<String>();
    
    return [SELECT   Id,
                     Challenge__c,
                     Challenge_Title__c,
                     CreatedDate
            FROM     Points__c
            WHERE    User__r.Id = :user
            AND      Amount__c > 0
            AND      Challenge__c != ''
            AND		 Challenge_Title__c NOT IN :listOfChall
            ORDER BY CreatedDate DESC
            LIMIT 2];
  }
  
  public List<Points__c> getRecentShoutoutChallenges() {
    
    /* updating method to exclude the challenges listed in shoutout challage */
    String  shoutoutChall = Game_Settings__c.getInstance().Shoutout_Challenge_Titles__c;
    List<String> listOfChall = shoutoutChall!=null ? shoutoutChall.split(','):new List<String>();
    
    return [SELECT   Id,
                     Challenge__c,
                     Challenge_Title__c,
                     CreatedDate,
                     Source_Id__c
            FROM     Points__c
            WHERE    User__r.Id = :user
            AND      Amount__c > 0
            AND      Challenge__c != ''
            AND		 Challenge_Title__c  IN :listOfChall
            ORDER BY CreatedDate DESC
            LIMIT 2];
  }
  
  
  public Decimal getLastThirtyDaysPoints(){    
    
    AggregateResult[] last30DaysPointsEarned = [SELECT SUM(Amount__c) points
                                                FROM   Points__c
                                                WHERE  User__r.Id = :user 
                                                AND    Amount__c > 0
                                                AND    RecordType.Name = 'Earned Points'
                                                AND    Date__c = LAST_N_DAYS:30];  
                                                     
    if (last30DaysPointsEarned[0].get('points')==null) {
      lastThrityDayPoint =0;
      return 0;
    } else {
      lastThrityDayPoint = (Double)last30DaysPointsEarned[0].get('points');                                            
      return (Decimal)last30DaysPointsEarned[0].get('points');
    }
  }
  
  /* adding leader board ahead user  :- 1 place ahead */
  public AgeUser getUserAheadInLeaderBoard(){
  	   if(leaderboardAheadUser != null) {
  	     return leaderboardAheadUser;
  	   }
  	
  		AggregateResult[] last30DaysPointsEarned = [SELECT SUM(Amount__c) points,user__c
                                                	FROM   Points__c
                                                	WHERE  Amount__c > 0
                                                	AND    RecordType.Name = 'Earned Points'
                                                	AND    Date__c = LAST_N_DAYS:30
                                                	AND    User__r.Id != :user 
                                                	GROUP By user__c
                                                	HAVING SUM(Amount__c) >=: lastThrityDayPoint
                                                   ];  
  	   // let us find the user with one step ahead
  	   Decimal minValue= 0;
  	   String id;
  	   for(AggregateResult r:last30DaysPointsEarned){
  	   		if (r.get('points')==null) continue;
  	   		Decimal pts = (Decimal)r.get('points');
  	   		if(minValue ==0 || pts < minValue){
  	   			minValue =pts;
  	   			id = (String)r.get('user__c');
  	   		}
  	   }
  	   
  	   
  	  leaderboardAheadUser =  getUser(id,minValue,last30DaysPointsEarned.size());
  	  return leaderboardAheadUser;
  }
  
  private AgeUser getUser(String id,Decimal points,Integer rank){
  	List<User> u= [Select Id,FullPhotoUrl,Full_Name__c,Name,SmallPhotoURL FROM User WHERE id=:id];
  	if( u.size()==0 ) {
  	   return new AgeUser(null,points,rank);
  	} 
  	return new AgeUser(u[0],points,rank);
  }
  
  /* adding leader board behind user  :- 1 place behind */
  public AgeUser getUserBehindInLeaderBoard(){
  	   if(leaderboardBehindUser != null) {
  	     return leaderboardBehindUser;
  	   }
  	
  		AggregateResult[] last30DaysPointsEarned = [SELECT SUM(Amount__c) points,User__c
                                                	FROM   Points__c
                                                	WHERE  Amount__c > 0
                                                	AND    RecordType.Name = 'Earned Points'
                                                	AND    Date__c = LAST_N_DAYS:30
                                                	AND    User__r.Id != :user 
                                                	GROUP By user__c
                                                	HAVING SUM(Amount__c) <=: lastThrityDayPoint
                                                   ];  
  	   // let us find the user with one step ahead
  	   Decimal maxValue= 0;
  	   String id;
  	   for(AggregateResult r:last30DaysPointsEarned){
  	   		if (r.get('points')==null) continue;
  	   		Decimal pts = (Decimal)r.get('points');
  	   		if(maxValue ==0 || pts > maxValue){
  	   			maxValue =pts;
  	   			id = (String)r.get('User__c');
  	   		}
  	   }
  	   leaderboardBehindUser = getUser(id,maxValue,getUserAheadInLeaderBoard().rank+2);
  	   return leaderboardBehindUser;
  }
  
  public Integer getCurrentRank(){
    AgeUser ageUser = getUserAheadInLeaderBoard();
    return ageUser.rank + 1;
  }
  
  
  public List<Badge__c> getBadges() {
    List<Badge__c> badgeUrl = new List<Badge__c>();
    badgeCount = new Map<Id,Integer>();
   
    //@added the order by to sort latest to older
    List<Awarded_Badge__c> badges = [SELECT 
                   Badge__r.Image_Url__c, Badge__c,
                   Badge__r.Title__c
            FROM   Awarded_Badge__c           
            WHERE  User__r.Id = :user 
            ORDER BY Effective_Date__c DESC];
           
    for(Awarded_Badge__c ab : badges) {
      Integer cnt = badgeCount.get(ab.Badge__c)!=null ? badgeCount.get(ab.Badge__c):0; 
      
      //if we have already added the badge then just increment the count
      if(badgeCount.get(ab.Badge__c)!=null){
      	badgeCount.put(ab.Badge__c,cnt+1); 
      	continue; 
      }
      
      Badge__c awardedBadge = new Badge__c();
      awardedBadge.id=ab.Badge__c;
      awardedBadge.Title__c = ab.Badge__r.Title__c;
      awardedBadge.Image_Url__c = ab.Badge__r.Image_Url__c;
      badgeUrl.add(awardedBadge);
      badgeCount.put(ab.Badge__c,cnt+1); 
           
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