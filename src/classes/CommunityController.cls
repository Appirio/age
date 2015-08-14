public class CommunityController extends AgeUserController {

//
// (c) Appirio 
//
// Appirio's Gamification App
//
// 9/18/13     Kym Le             Original
// 9/2/14      Glenn Weinstein    Rewrite query for Practice list, from aggregate query on User object (which consumes
//                                too many SOQL rows in test methods) to a straight query on Practice object
//

  public CommunityController() {
  
  }
  
  public class CommunityTotals {
      private Decimal totalChallengesCompleted {get;set;}
      private Decimal averageNumberOfChallengesCompleted {get;set;}
      private Decimal averageNumberOfPointsEarned {get;set;}
      private Decimal currentPointsAvailable {get;set;}
      private List<Points__c> mostRecentlyCompletedChallenges {get;set;}     
      private List<AggregateResult> mostOftenCompletedChallenges {get;set;}
      private List<Awarded_Badge__c> mostRecentlyEarnedBadges {get;set;}
      private List<AggregateResult> mostOftenEarnedBadges {get;set;}
      private Decimal funFactor {get;set;}
      private List<String> coreValueTypes {get;set;}      
      private List<String> focusTypes {get;set;}
      private List<String> regions {get;set;}
      private List<String> practices {get;set;}            
  }

  @RemoteAction
  public static CommunityTotals getCommunityTotals() {
      CommunityTotals totals = new CommunityTotals();
      totals.totalChallengesCompleted = getTotalChallengesCompleted();
      totals.averageNumberOfChallengesCompleted = getAverageNumberOfChallengesCompleted();
      totals.averageNumberOfPointsEarned = getAverageNumberOfPointsEarned();
      totals.currentPointsAvailable = getCurrentPointsAvailable();
      totals.mostRecentlyCompletedChallenges = getMostRecentlyCompletedChallenges();
      totals.mostOftenCompletedChallenges = getMostOftenCompletedChallenges();
      totals.mostRecentlyEarnedBadges = getMostRecentlyEarnedBadges();
      totals.mostOftenEarnedBadges = getMostOftenEarnedBadges();
      totals.funFactor = getFunFactor();
      totals.coreValueTypes = getCoreValueTypes();
      totals.focusTypes = getFocusTypes();
      totals.regions = getRegions();
      totals.practices = getPractices();            
      return totals;
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
  public static List<String> getRegions() {
  
    List<String> regions = new List<String>();
    
    List<AggregateResult> userRegions = [SELECT   Region__c 
                                         FROM     User 
                                         WHERE    Region__c != ''
                                         GROUP BY Region__c
                                         ORDER By Region__c];
            
    for (AggregateResult u : userRegions) {
      regions.add((String)u.get('Region__c'));
    }
    
    return regions;
  }
  
  
  @RemoteAction
  public static List<String> getPractices() {
  
    List<String> practices = new List<String>();
    
    List<pse_Practice__c> practiceList = [SELECT   Name 
                                           FROM     pse_Practice__c 
                                           WHERE    Assignable_To_Resources__c = true
                                           AND      (NOT Name LIKE '%Resource Requests%')
                                           ORDER By Name];
            
    for (pse_Practice__c p : practiceList) {
      practices.add(p.Name);
    }
    
    return practices;
  }

  @RemoteAction
  public static Decimal getTotalChallengesCompleted() {
    
    AggregateResult[] totalChallengesCompleted = [SELECT COUNT(Id) Challenges
                                                  FROM   Points__c
                                                  WHERE  Source__c = 'Challenge Completed'
                                                  AND    CreatedDate = LAST_N_DAYS:30];  
                                                
    if (totalChallengesCompleted[0].get('Challenges') == null) {
      return 0;
    } else {                                              
      return (Decimal)totalChallengesCompleted[0].get('Challenges');
    }
  }
  
  @RemoteAction
  public static Decimal getAverageNumberOfChallengesCompleted() {
  
    Decimal challenges = getTotalChallengesCompleted();
                                                   
    if (challenges == 0) {
      return 0;
    } else {        
    
      List<User> allUsers = AgeUserController.getAllUsers();
      Decimal users = allUsers.size();                        
                                           
      return challenges/users;
    }
  }
  
  @RemoteAction
  public static Decimal getAverageNumberOfPointsEarned() {
  
    AggregateResult[] totalPoints = [SELECT SUM(Amount__c) Points
                                     FROM   Points__c
                                     WHERE  Source__c = 'Challenge Completed'
                                     AND    CreatedDate = LAST_N_DAYS:30];
    
    if (totalPoints[0].get('Points') == null) {
      return 0;
    } else {        
    
      List<User> allUsers = AgeUserController.getAllUsers();
                                     
      Decimal points = (Decimal)totalPoints[0].get('Points');
      Decimal users = allUsers.size();                       
                                           
      return points/users;
    }
  }

  @RemoteAction 
  public static Decimal getCurrentPointsAvailable() {
  
    AggregateResult[] currentPoints = [SELECT  SUM(Reward_Points__c) Points
                                         FROM  Challenge__C
                                         WHERE Active__c = true];

    if (currentPoints[0].get('Points') == null) {
      return 0;
    } else {                                              
      return (Decimal)currentPoints[0].get('Points');
    }
  }


  @RemoteAction
  public static List<Points__c> getMostRecentlyCompletedChallenges() {
  
    return [SELECT Challenge__c, 
                   Challenge__r.Title__c, 
                   User__c, 
                   User__r.Name, 
                   CreatedDate
            FROM   Points__c
            WHERE  Source__c = 'Challenge Completed'
            AND    Challenge__r.Active__c = true
            ORDER  BY CreatedDate DESC LIMIT 3];
  }

  @RemoteAction
  public static List<AggregateResult> getMostOftenCompletedChallenges() {
  
    return [SELECT   COUNT(Challenge__c), 
                     Challenge__r.Id, 
                     Challenge__r.Title__c
            FROM     Points__c
            WHERE    CreatedDate = LAST_N_DAYS:30
            AND      Source__c = 'Challenge Completed'
            AND      Challenge__r.Active__c = true
            GROUP BY Challenge__r.Id, Challenge__r.Title__c
            ORDER BY count(Challenge__c) DESC LIMIT 3];
  }


  @RemoteAction
  public static List<Awarded_Badge__c> getMostRecentlyEarnedBadges() {
  
    return [SELECT   Badge__c, 
                     Badge__r.Title__c,
                     Badge__r.Image_Url__c, 
                     User__c, 
                     User__r.Name, 
                     CreatedDate
            FROM     Awarded_Badge__c
            WHERE    Badge__r.Active__c = true
            ORDER BY CreatedDate DESC LIMIT 3];
  }

  @RemoteAction
  public static List<AggregateResult> getMostOftenEarnedBadges() {
  
    return [SELECT   COUNT(Badge__c), 
                     Badge__r.Id, 
                     Badge__r.Title__c,
                     Badge__r.Image_Url__c
            FROM     Awarded_Badge__c
            WHERE    CreatedDate = LAST_N_DAYS:30
            AND      Badge__r.Active__c = true
            GROUP BY Badge__r.Id, Badge__r.Title__c, Badge__r.Image_Url__c
            ORDER BY count(Badge__c) DESC LIMIT 3];
  }
  
  @RemoteAction
  public static Decimal getFunFactor() {
  
    List<Game_Settings__c> gs = [SELECT Fun_Factor__c 
                                 FROM   Game_Settings__c 
                                 WHERE  Fun_Factor__c != null];
    
    return gs[0].Fun_Factor__c;
  }
  
  
  static Map<String, String> userImageMap = new Map<String, String>();

  static{

     List<User> userImage = [SELECT Id, 
                                    SmallPhotoUrl 
                             FROM   User
                             WHERE  UserType = 'Standard'];
     
     for(User u : userImage){
       userImageMap.put(u.Id, u.SmallPhotoUrl);
     }
  }


  @RemoteAction
  public static List<PointsHolder2> getAllTimeLeaders() {
    return getUserPointsByDateCriteria2(' ');
  }

  @RemoteAction
  public static List<PointsHolder2> getThisQuartersLeaders(){
    return getUserPointsByDateCriteria2(' AND CreatedDate = THIS_QUARTER');
  }

  @RemoteAction
  public static List<PointsHolder2> getLastQuartersLeaders(){
    return getUserPointsByDateCriteria2(' AND CreatedDate = LAST_QUARTER');     
  }

  @RemoteAction
  public static List<PointsHolder2> getLast2QuartersLeaders(){
    return getUserPointsByDateCriteria2(' AND CreatedDate = LAST_N_QUARTERS:2');            
  }
  
  @RemoteAction
  public static List<PointsHolder2> getThisMonthsLeaders(){
    return getUserPointsByDateCriteria2(' AND CreatedDate = THIS_MONTH');                  
  }
  
  @RemoteAction
  public static List<PointsHolder2> getThisYearsLeaders(){
    return getUserPointsByDateCriteria2(' AND CreatedDate = THIS_YEAR');                         
  }
  
  @RemoteAction
  public static List<PointsHolder> getAllTimePracticeLeaders() {
    return getPracticePointsByDateCriteria(' ');
  }
  
  @RemoteAction
  public static List<PointsHolder> getThisQuartersPracticeLeaders(){
    return getPracticePointsByDateCriteria(' AND CreatedDate = THIS_QUARTER');
  }
  
  @RemoteAction
  public static List<PointsHolder> getLastQuartersPracticeLeaders(){
    return getPracticePointsByDateCriteria(' AND CreatedDate = LAST_QUARTER');    
  }
  
  @RemoteAction
  public static List<PointsHolder> getLast2QuartersPracticeLeaders(){
    return getPracticePointsByDateCriteria(' AND CreatedDate = LAST_N_QUARTERS:2'); 
  }
  
  @RemoteAction
  public static List<PointsHolder> getThisMonthsPracticeLeaders(){
    return getPracticePointsByDateCriteria(' AND CreatedDate = THIS_MONTH');    
  }
  
  @RemoteAction
  public static List<PointsHolder> getThisYearsPracticeLeaders(){
    return getPracticePointsByDateCriteria(' AND CreatedDate = THIS_YEAR');    
  }    
  
  
  private static List<PointsHolder2> getUserPointsByDateCriteria2(String andClause) {
    Map<Id, PointsHolder2> totalPointsPerUser = new Map<Id, PointsHolder2>();
    
    String pointsSource = 'Earned Points';
    String baseSOQL = 'SELECT User__r.Id, User__r.Name, User__r.Region__c, User__r.Practice__c , Amount__c, Challenge__r.Core_Value__c, Challenge__r.Focus__c, Challenge__r.Title__c, Challenge__r.id, Challenge__r.Reward_Points__c FROM Points__c WHERE Amount__c > 0 AND RecordType.Name = :pointsSource';
    String soql = baseSOQL + andClause;
    
    List<Points__c> userPoints = Database.query(soql);
    
    for (Points__c pt : userPoints) {
      PointsHolder2 ph2 = totalPointsPerUser.get(pt.User__r.Id);
      
      if(ph2 == null) {
        ph2 = new PointsHolder2(pt, userImageMap.get(pt.User__r.Id));
      } 
        
      ph2.addPoint(pt);
      
      totalPointsPerUser.put(pt.User__r.Id, ph2);
    
    }
    
    return totalPointsPerUser.values();
  }
  
  
  private static List<PointsHolder> getUserPointsByDateCriteria(String andClause){
    List<PointsHolder> totalPointsPerUser = new List<PointsHolder>();
    
    String pointsSource = 'Earned Points';
    String baseSOQL = 'SELECT User__r.Id UserId, User__r.Name Name, User__r.Region__c Region, User__r.Practice__c Practice, SUM(Amount__c) Points FROM Points__c WHERE Amount__c > 0 AND RecordType.Name = :pointsSource';                                    
    String groupBySOQL = ' GROUP BY User__r.Id, User__r.Name, User__r.Region__c, User__r.Practice__c';
    String orderBySOQL = ' ORDER BY SUM(Amount__c) desc, User__r.Name';      
    
    String soql = baseSOQL + andClause + groupBySOQL + orderBySOQL;
                            
    AggregateResult[] allPoints =  Database.query(soql); 
       
    List<String> userIds = new List<String>();
                                    
    for(AggregateResult ar : allPoints){
     userIds.add((String)ar.get('UserId'));  
    }  
                        
    Map<String, List<Challenge__c>> uch = createUserChallengeMap(userIds);                                   
                                          
    for(AggregateResult ar : allPoints){
      String userId = (String)ar.get('UserId');
      totalPointsPerUser.add(new PointsHolder(ar, userImageMap.get(userId), uCh.get(userId)));  
    }  
    
    return totalPointsPerUser;       
  }


  private static List<PointsHolder> getPracticePointsByDateCriteria(String andClause){
    List<PointsHolder> totalPointsPerPractice = new List<PointsHolder>();
    
    String pointsSource = 'Earned Points';
    String baseSOQL = 'SELECT User__r.Practice__c Practice, SUM(Amount__c) Points FROM Points__c WHERE Amount__c > 0 AND RecordType.Name = :pointsSource';                                    
    String groupBySOQL = ' GROUP BY User__r.Practice__c';
    String orderBySOQL = ' ORDER BY SUM(Amount__c) desc, User__r.Practice__c';      
    
    String soql = baseSOQL + andClause + groupBySOQL + orderBySOQL;
                            
    AggregateResult[] allPoints =  Database.query(soql);
                            
    Map<String, User> userPracticeMap = new Map<String, User>([SELECT Id, 
                                                                      Practice__c, 
                                                                      Region__c
                                                               FROM   User 
                                                               WHERE  UserType = 'Standard']);  
                                       
    List<String> userIds = new List<String>();
    userIds.addAll(userPracticeMap.keySet());                                       
                                       
    Map<String, List<Challenge__c>> uch = createUserChallengeMap(userIds);                                   
                                          
    for (AggregateResult ar : allPoints) {
      String practice = (String)ar.get('Practice');
      List<String> usersForPractice = new List<String>();
      List<Challenge__c> practiceChallenges = new List<Challenge__c>();
      List<String> regionsForPractice = new List<String>();
      
      for (String uId : userPracticeMap.keySet()) {
        User u = userPracticeMap.get(uId);
      
        if (u.Practice__c == practice) {
          usersForPractice.add(uId);
          regionsForPractice.add(u.Region__c);
        }
      }
      
      for (String uId : usersForPractice) {
        if (uch.get(uId) != null) {
          practiceChallenges.addAll(uch.get(uId));
        }
      }
      
      totalPointsPerPractice.add(new PointsHolder(ar, regionsForPractice, practiceChallenges));
    } 
    
    return totalPointsPerPractice;       
  }
  
  
  private static Map<String, List<Challenge__c>> createUserChallengeMap(List<String> userIds){
    
    Map<String, List<Id>> userChallengeMap = new Map<String, List<Id>>();                  
   
    List<Points__c> userChallenges = [SELECT User__c,
                                             Challenge__c
                                      FROM   Points__c
                                      WHERE  User__c in :userIds];  
        
    List<Id> allChallengeIds = new List<Id>();
                
    for(Points__c p : userChallenges) {
   
      List<Id> challenge = userChallengeMap.get(p.User__c);
     
      if(challenge == null) {
        challenge = new List<Id>();
      }
     
      allChallengeIds.add(p.challenge__c);
      challenge.add(p.challenge__c);
      userChallengeMap.put(p.User__c, challenge);
    }    
   
    List<Challenge__c> listChallenge = [SELECT Id, 
                                               Title__c, 
                                               Focus__c ,
                                               Core_Value__c,
                                               Reward_Points__c
                                        FROM   Challenge__c 
                                        WHERE  Id in :allChallengeIds];    
   
    Map<String, List<Challenge__c>> uCh = new Map<String, List<Challenge__c>>();
    
    for(Id uId : userChallengeMap.keySet()) {
      List<Id> me = userChallengeMap.get(uId);
      List<Challenge__c> listChallengeLoop = new List<Challenge__c>();
     
      for(Challenge__c cloop : listChallenge) {
        for(Id cId : me) {
          if(cId == cloop.Id){
            listChallengeLoop.add(cloop);
          }  
        }
      }  
      uCh.put(uId,listChallengeLoop); 
    }
    
    return uCh;
  }
  
  public class PointsHolder2 {
    public String userId {get;private set;}
    public String name {get;private set;}
    public List<String> regions {get;private set;}
    public String practice {get;private set;}
    public String imageUrl {get;private set;}
    public List<Points__c> points {get;private set;}
    public List<Challenge__c> challenges {get;private set;}
    
    public PointsHolder2(Points__c pt, String userImageURL){
      userId = pt.User__r.Id;
      name = pt.User__r.Name;
      regions = new List<String>();  
      regions.add(pt.User__r.Region__c);
      practice = pt.User__r.Practice__c;
      imageUrl = userImageUrl;
      points = new List<Points__c>();
      challenges = new List<Challenge__c>();

    }
    
    
    public void addPoint(Points__c pt){
    
      points.add(pt);
      
      Challenge__c ch = new Challenge__c();
      ch.Title__c = pt.Challenge__r.Title__c;
      ch.Reward_Points__c = pt.Amount__c;
      ch.Focus__c = pt.Challenge__r.Focus__c;
      ch.Core_Value__c = pt.Challenge__r.Core_Value__c;
      
      challenges.add(ch);
    }
  
  
  }

  public class PointsHolder {
  
    public String userId {get;private set;}
    public String name {get;private set;}
    public List<String> regions {get;private set;}
    public String practice {get;private set;}
    public String imageUrl {get;private set;}
    public Decimal points {get;private set;}
    public List<Challenge__c> challenges {get; private set;}
  
    
    //use for practice
    public PointsHolder(AggregateResult ar, List<String> regionsForPractice, List<Challenge__c> userChallenges){
      name = (String)ar.get('Practice');
      regions =  regionsForPractice;
      practice =  (String)ar.get('Practice');
      points = (Decimal)ar.get('Points');
      challenges = userChallenges;
    }
    
    public PointsHolder(AggregateResult ar, String userImageUrl, List<Challenge__c> userChallenges){
      userId = (String)ar.get('UserId');
      name = (String)ar.get('Name');
      regions = new List<String>();  
      regions.add((String)ar.get('Region'));
      practice =  (String)ar.get('Practice');
      imageUrl = userImageUrl;
      points = (Decimal)ar.get('Points');
      challenges = userChallenges;
    }
  }

}