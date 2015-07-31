/******************************************************************************
//Name        : Utility class AGETestUtility
//Usage       : This class AGETestUtility currently used by Test classes below
//            : 1. AgeProfileManagerControllerTest class
//            : 2. AgeUserControllerTest Class
//            : 3. ChallengeManagerControllerTest class
//            : 4. UserChallengeCounterTest
//            : 5. CommunityController
//            : 6. BadgesController
//            : 7. afterInsertFeedItem - added by Kym Le
//            : 8. afterInsertFeedComment - added by Kym Le
//
//Author      : Guna Sevugapperumal Created 21 Sep, 2013
//Update      : Guna Sevugapperumal Updated  30 Sep, 2013, Added Region and 
//            : practice values to user
//            : Kym Le Update 10/08/2013 Added method to create chatter challenge
//            : Kym Le Update 10/08/2013 Added method to get existing chatter collaboration group id
//            : Kym Le Update 10/09/2013 Added method to create different types of users
//            : Guna Update 10/14/15 modified the CreateChallenge & createpoints
//            :                      method to adopt to best practice.
/*****************************************************************************/
global class AGETestUtility{
    // Create a test user with system admin profile with no input
    public static user createTestUser() {
      Profile profileName = [SELECT id 
                             FROM profile 
                             WHERE name='System Administrator'];
                              
      User testUser = new User(
                            alias = 'TSAdmin', 
                            email='UnitTestAdminuser@appirio.com', 
                            emailencodingkey='UTF-8', 
                            lastname='TestLastName', 
                            firstName='FirstName', 
                            languagelocalekey='en_US', 
                            localesidkey='en_US', 
                            profileid = profileName.Id, 
                            timezonesidkey='America/Los_Angeles', 
                            username= 'AppirioAGETestUser'+Datetime.now().format('MM.dd.yyyy.HH.mm.ss')+'@appirio.com',
                            Region__c = 'Corporate', 
                            Practice__c = 'CloudSpokes'); 
      return testUser;
    }
    
    
    
    
    // Create a test user with Appirio Employee Profile with no input
    public static user createTestEmployeeUser() { 
        Long currentTime = System.currentTimeMillis();
        String profileName = 'Appirio Employee';
        Account anAccount = new Account(Name= 'Appirio');
        insert anAccount;

        User existingUser = [SELECT Id, LastName, Email, Alias, TimeZoneSidKey,
                                    LocaleSidKey, EmailEncodingKey,
                                    LanguageLocaleKey, ProfileId
                            FROM    User
                            WHERE   Profile.Name = :profileName and 
                                    IsActive = true
                            limit   1];

        User testUser = new User(
                                        Username = 'testuser' + currentTime + '@appirio.com',
                                        LastName = 'TestLastName',
                                        Email = 'UnitTestuser@appirio.com',
                                        Alias = 'TSAdmin',
                                        CommunityNickname = 'testuser' + currentTime,
                                        TimeZoneSidKey = existingUser.TimeZoneSidKey,
                                        LocaleSidKey = existingUser.LocaleSidKey,
                                        EmailEncodingKey = existingUser.EmailEncodingKey,
                                        LanguageLocaleKey = existingUser.LanguageLocaleKey,
                                        ProfileId = existingUser.ProfileId,
                                        Region__c = 'Jaipur',
                                        Practice__c = 'SFDC - Service Cloud');
      
    insert testUser;
    return testuser;
   }
   
   
   
   
   
  //Create a user with input parameters. Takes in a boolean for a 
  // sysadmin profile type as well as first name and lastname   
  public static User createTestUser(Boolean isSysAdmin, 
                                                                    String firstName, string lastName) {
    String profileType;
    if (isSysAdmin){
      profileType = 'System Administrator'; 
    } else {
      profileType = 'Appirio Employee'; 
    }
    System.debug('PROFILE TYPE: ' + profileType);
    
    Profile userProfile = [ SELECT Id 
                                        FROM   Profile 
                                        WHERE  Name = :profileType]; 
    
    User testUser = new User( 
                                         Alias = 'TSAdmin', 
                       Email = 'UnitTestAdminUser@appirio.com', 
                       EmailEncodingKey = 'UTF-8', 
                       LastName = lastName, 
                       FirstName = firstName, 
                       LanguageLocaleKey = 'en_US', 
                       LocaleSidKey = 'en_US', 
                       ProfileId = userProfile.Id, 
                       TimezoneSidKey = 'America/Los_Angeles', 
                       Username = firstName + lastName + '@testorg.com',
                       Region__c = 'Corporate', 
                       Practice__c = 'CloudSpokes'); 
    
    insert testUser;                   
    return testUser;
  }   
  
  
  
  // Create chatter gamification collaboration group. This is necessary for the 
  // triggers to post to chatter feed for the group 
  public static CollaborationGroup getCollaborationGroup() {
    
    return [SELECT Id 
            FROM   CollaborationGroup 
            WHERE  Name = 'Gamification']; 
  }  
    
    
    
  // Create Test gamification collaboration group.  
  public static CollaborationGroup createTestCollaborationGroup() {
    CollaborationGroup collabGroup = new collaborationgroup(
                                                                                name = 'TestGamification', 
                                                                                CollaborationType = 'Public');
    insert collabGroup;
    
    // 2. insert the custom settings if it is not populated
      // Following logic is work around to test against TestGamification group
      // created in above step. 
      if(Game_Settings__c.getInstance().Chatter_Group_ID_All_Activities__c == null){
        Game_Settings__c gameSetting = new Game_Settings__c();
        gameSetting.Chatter_Group_ID_All_Activities__c = collabGroup.Id;
        insert gameSetting;
      }
    return collabGroup; 
  }  
  
    
    
  // create a single chatter challenge based on reward points, hashtag phrase 
  // and who gets the award for hashtag phrase, do not include the # symbol
  // for pointsAwardedTo, this could be to the Poster or @Mentions 
  public static Challenge__c createChatterChallenge(Integer reward, 
                                                     String hashtagPhrase, String pointsAwardedTo) {
    Integer numOfDays = 150; 
    Challenge__c chatterChallenge = new Challenge__c (
                                                                title__c = 'Test Chatter Challenge', 
                                  reward_points__c = reward,
                                  Start_date__c = Date.today(),
                                  End_date__c = Date.today().addDays(numOfDays),
                                  Hashtag__c = hashtagPhrase,
                                  Action__c = 'Comment;Post',
                                  Points_Awarded_To__c = pointsAwardedTo,
                                  Active__c = true);
                                                        
    insert chatterChallenge;
    return chatterChallenge;
  }
  
  
  
  
    // Create test record for Points Buckets 
    public static List<points_bucket__c> CreatePointsBuckets(String bucketName,
                                                        Integer bucketBalance){
      List<points_bucket__c> pointsBuckets = new List<points_bucket__c>();
      pointsBuckets.add(new Points_bucket__c(Current_Balance__c = bucketBalance,
                          Title__c = bucketName,
                          owner__c = UserInfo.getUserId()));
      insert pointsBuckets;
      return pointsBuckets;
    }
    
    
    // Award a batch Test method to test awarding a badge  
    public static void awardBadgeDirectly(Badge__c badge){
        List<Awarded_Badge__c> awards = new List<Awarded_Badge__c>();
        awards.add(new Awarded_badge__c(badge__c = badge.Id, 
                                            user__c = userInfo.getUserId()));
      insert awards;
    }
    
    
    
    // Create a test Badge 
    public static List<badge__c> createTestBadges(String badgeName){
        List<badge__c> badges = new List<badge__c>();
      badges.add(new Badge__c(Title__c = badgeName, 
                                    Active__c = true,
                                    image_url__c = 'https://test/servlet/servlet.FileDownload?file=00P5000000FKIB1EAP'));
      insert badges;
      return badges; 
    } 
    
    
    
    // Create Test challenges records to add test points
    public static List<Challenge__c> CreateChallenge(Integer numOfChallenges, 
                                                     Integer reward, 
                                                     badge__c badge,
                                                     points_Bucket__c pointsBucket){ 
      // 1. Insert test challenge records
      Integer maxRewards = 1;
      String challengeTitle;
      List<Challenge__c> challenges = new List<Challenge__c>();
      
      for(integer i=1; i<= numOfChallenges ; i++){
        challengeTitle = 'TestChallenge'+ i;
        challenges.add(new challenge__c(
                           title__c = challengeTitle, 
                           reward_points__c = reward,
                           Start_date__c = Date.today(),
                           End_date__c = Date.today().addDays(150),
                           Max_Number_of_Achievements_Per_User__c = maxRewards,
                           Active__c = true)) ;
                           // removed since Glenn is taking this field out
                           //points_Bucket__c = pointsBucket.Id )) ;
        // Testing purpose make every other challege can be awarded only once
        // and other challenges only twice. This is to test challenges that can
        // be awarded only once.
            if(maxRewards == 1)
                maxRewards = 2;
            else
                maxRewards = 1;                             
        }
        insert challenges;
        
        // 2. Associate Test Badge with Test challenges
        List<Badge_challenge__c> badgeChallenges = new List<Badge_challenge__c>(); 
        for (challenge__c challenge : challenges){
            badgeChallenges.add(new Badge_Challenge__c(badge__c = badge.Id, 
                                            challenge__c = challenge.id));
        }
        insert badgeChallenges;
        
        // 3. Associate Challenge with Points Buckets
        List<Challenge_Points_Bucket__c> challengePointsBuckets = 
                                                                    new List<Challenge_Points_Bucket__c>();
        for (challenge__c challenge : challenges){
            challengePointsBuckets.add(new Challenge_Points_Bucket__c(
                                                                            challenge__c = challenge.Id,
                                                                            points_Bucket__c = pointsBucket.Id ));
        }
        
        insert challengePointsBuckets;
        return challenges;
     }
     
     
     
     // Award points only once for each challenge but award the points at
     // different times 
     public static void createPoints(List<Challenge__c> challenges){
        //List<Challenge__c> challenges = CreateChallenge();
        
        List<Points__c> points = new List<Points__c>();
        Date awardDate  = date.today();
        Integer firstHalfChallenges = challenges.size()/2;
        
        for(integer i = 0 ; i < challenges.size() ; i++){
            
          // award first half this month
          if(i <= challenges.size()/2)
            points.add(new points__c(Amount__c = challenges[i].Reward_Points__c, 
                                    challenge__c = challenges[i].id, 
                                    Date__c = awardDate, 
                                    User__c = userInfo.getUserId(),
                                    Source__c = 'Challenge Completed'));
          else // award second half to this quarter
            points.add(new points__c(Amount__c = challenges[i].Reward_Points__c, 
                                    challenge__c = challenges[i].id, 
                                    Date__c = awardDate.addDays(-100) ,
                                    User__c = userInfo.getUserId(),
                                    Source__c = 'Challenge Completed'));                           
                                     
        }
        insert points;
     }
     
}