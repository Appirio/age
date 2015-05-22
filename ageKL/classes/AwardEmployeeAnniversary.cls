global class AwardEmployeeAnniversary implements Database.Batchable<SObject> {


  global Database.QueryLocator start(Database.BatchableContext c) {
    String query = '';
    query += 'SELECT Id, ';
    query += '       Name, ';
    query += '       Continuous_Service_Date__c ';
    query += 'FROM   User ';
    query += 'WHERE  UserType = \'Standard\' ';
    query += 'AND    isActive = true ';
    return Database.getQueryLocator(query);
  }

  global void execute(Database.BatchableContext c, List<Sobject> objects) {
  
    execute((List<User>)objects); 

  }

  public static void execute(List<User> usersList){

    Integer backDays = (Integer)Game_Settings__c.getInstance().Award_Anniversary_Back_Days__c;
    Date rollBackDate = Date.Today().addDays(-backDays); 

    Integer rollBackMonth = rollBackDate.month();        
    Integer rollBackDay = rollBackDate.day();

    Integer todayMonth = Date.Today().month();
    Integer todayDay = Date.Today().day();
    Integer todayYear = Date.Today().year();
    
    System.debug('roll back date ' + rollBackDate);
    
    String x1YearAnniversary = Game_Settings__c.getInstance().Employee_1_Year_Anniversary__c;
    String x2YearAnniversary = Game_Settings__c.getInstance().Employee_2_Year_Anniversary__c;    
    String x3YearAnniversary = Game_Settings__c.getInstance().Employee_3_Year_Anniversary__c;  
    String x4YearAnniversary = Game_Settings__c.getInstance().Employee_4_Year_Anniversary__c;  
    String x5YearAnniversary = Game_Settings__c.getInstance().Employee_5_Year_Anniversary__c;  
    String x6YearAnniversary = Game_Settings__c.getInstance().Employee_6_Year_Anniversary__c;  
    String x7YearAnniversary = Game_Settings__c.getInstance().Employee_7_Year_Anniversary__c;  
    String x8YearAnniversary = Game_Settings__c.getInstance().Employee_8_Year_Anniversary__c;  
    String x9YearAnniversary = Game_Settings__c.getInstance().Employee_9_Year_Anniversary__c;  
    String x10YearAnniversary = Game_Settings__c.getInstance().Employee_10_Year_Anniversary__c;  
    String x11YearAnniversary = Game_Settings__c.getInstance().Employee_11_Year_Anniversary__c;  
    String x12YearAnniversary = Game_Settings__c.getInstance().Employee_12_Year_Anniversary__c;  
    String x13YearAnniversary = Game_Settings__c.getInstance().Employee_13_Year_Anniversary__c;  
    String x14YearAnniversary = Game_Settings__c.getInstance().Employee_14_Year_Anniversary__c;  
    String x15YearAnniversary = Game_Settings__c.getInstance().Employee_15_Year_Anniversary__c;  
    String x16YearAnniversary = Game_Settings__c.getInstance().Employee_16_Year_Anniversary__c;  
    String x17YearAnniversary = Game_Settings__c.getInstance().Employee_17_Year_Anniversary__c;  
    String x18YearAnniversary = Game_Settings__c.getInstance().Employee_18_Year_Anniversary__c;  
    String x19YearAnniversary = Game_Settings__c.getInstance().Employee_19_Year_Anniversary__c;  
    String x20YearAnniversary = Game_Settings__c.getInstance().Employee_20_Year_Anniversary__c;                                  
                                         
  
    Map<Id, User> usersMap = new Map<Id, User>();
    Map<Id, List<Points__c>> userIdAndPointsMap = new Map<Id, List<Points__c>>();    
    GameEngine.AwardedChallenge awardedChallenge;
    List<GameEngine.AwardedChallenge> awardedChallengesList = new List<GameEngine.AwardedChallenge>();
        
        
    for (User u : usersList) {
      if (u.Continuous_Service_Date__c != null) {
        usersMap.put(u.Id, u);
      }
    }  
    
    userIdAndPointsMap = PointsValidator.getAllUsersAndPointsForTargetRecordId(usersMap.keySet());      
    
    System.debug('About to process : ' + usersMap);

    for (User u : usersMap.values()) {
    
      Integer userStartMonth = u.Continuous_Service_Date__c.Month();      
      Integer userStartDay = u.Continuous_Service_Date__c.Day();
      Integer userStartYear = u.Continuous_Service_Date__c.Year();

      // See if the start day and month are within the range and then check the years
      Date userStartDate = Date.newInstance(todayYear, userStartMonth, userStartDay);
  
      if(userStartDate >= rollBackDate && userStartDate <= Date.Today()){
        
        System.debug('Checking Anniversary years');

        Integer anniversaryNumber = todayYear - userStartYear;

        System.debug('anniversaryNumber : ' + anniversaryNumber);
          
        if (anniversaryNumber == 1 && !PointsValidator.userHasAlreadyBeenAwardedTargetId(userIdAndPointsMap.get(u.Id), x1YearAnniversary)) {
          
          awardedChallenge = new GameEngine.AwardedChallenge(x1YearAnniversary, u.Id, Date.Today(), 'Employee Anniversary!', '1 Year', x1YearAnniversary);
          awardedChallengesList.add(awardedChallenge);
                        
        } else if (anniversaryNumber == 2 && !PointsValidator.userHasAlreadyBeenAwardedTargetId(userIdAndPointsMap.get(u.Id), x2YearAnniversary)) {
          awardedChallenge = new GameEngine.AwardedChallenge(x2YearAnniversary, u.Id, Date.Today(), 'Employee Anniversary!', '2 Year', x2YearAnniversary);          
          awardedChallengesList.add(awardedChallenge);
                      
        } else if (anniversaryNumber == 3 && !PointsValidator.userHasAlreadyBeenAwardedTargetId(userIdAndPointsMap.get(u.Id), x3YearAnniversary)) {
          awardedChallenge = new GameEngine.AwardedChallenge(x3YearAnniversary, u.Id, Date.Today(), 'Employee Anniversary!', '3 Year', x3YearAnniversary);          
          awardedChallengesList.add(awardedChallenge);
                      
        } else if (anniversaryNumber == 4 && !PointsValidator.userHasAlreadyBeenAwardedTargetId(userIdAndPointsMap.get(u.Id), x4YearAnniversary)) {
          awardedChallenge = new GameEngine.AwardedChallenge(x4YearAnniversary, u.Id, Date.Today(), 'Employee Anniversary!', '4 Year', x4YearAnniversary);          
          awardedChallengesList.add(awardedChallenge);
                      
        } else if (anniversaryNumber == 5 && !PointsValidator.userHasAlreadyBeenAwardedTargetId(userIdAndPointsMap.get(u.Id), x5YearAnniversary)) {
          awardedChallenge = new GameEngine.AwardedChallenge(x5YearAnniversary, u.Id, Date.Today(), 'Employee Anniversary!', '5 Year', x5YearAnniversary);          
          awardedChallengesList.add(awardedChallenge);
                      
        } else if (anniversaryNumber == 6 && !PointsValidator.userHasAlreadyBeenAwardedTargetId(userIdAndPointsMap.get(u.Id), x6YearAnniversary)) {
          awardedChallenge = new GameEngine.AwardedChallenge(x6YearAnniversary, u.Id, Date.Today(), 'Employee Anniversary!', '6 Year', x6YearAnniversary);          
          awardedChallengesList.add(awardedChallenge);
                      
        } else if (anniversaryNumber == 7 && !PointsValidator.userHasAlreadyBeenAwardedTargetId(userIdAndPointsMap.get(u.Id), x7YearAnniversary)) {
          awardedChallenge = new GameEngine.AwardedChallenge(x7YearAnniversary, u.Id, Date.Today(), 'Employee Anniversary!', '7 Year', x7YearAnniversary);          
          awardedChallengesList.add(awardedChallenge);
                      
        } else if (anniversaryNumber == 8 && !PointsValidator.userHasAlreadyBeenAwardedTargetId(userIdAndPointsMap.get(u.Id), x8YearAnniversary)) {
          awardedChallenge = new GameEngine.AwardedChallenge(x8YearAnniversary, u.Id, Date.Today(), 'Employee Anniversary!', '8 Year', x8YearAnniversary);          
          awardedChallengesList.add(awardedChallenge);
                      
        } else if (anniversaryNumber == 9 && !PointsValidator.userHasAlreadyBeenAwardedTargetId(userIdAndPointsMap.get(u.Id), x9YearAnniversary)) {
          awardedChallenge = new GameEngine.AwardedChallenge(x9YearAnniversary, u.Id, Date.Today(), 'Employee Anniversary!', '9 Year', x9YearAnniversary);          
          awardedChallengesList.add(awardedChallenge);
                      
        } else if (anniversaryNumber == 10 && !PointsValidator.userHasAlreadyBeenAwardedTargetId(userIdAndPointsMap.get(u.Id), x10YearAnniversary)) {
          awardedChallenge = new GameEngine.AwardedChallenge(x10YearAnniversary, u.Id, Date.Today(), 'Employee Anniversary!', '10 Year', x10YearAnniversary);          
          awardedChallengesList.add(awardedChallenge);
                      
        } else if (anniversaryNumber == 11 && !PointsValidator.userHasAlreadyBeenAwardedTargetId(userIdAndPointsMap.get(u.Id), x11YearAnniversary)) {
          awardedChallenge = new GameEngine.AwardedChallenge(x11YearAnniversary, u.Id, Date.Today(), 'Employee Anniversary!', '11 Year', x11YearAnniversary);          
          awardedChallengesList.add(awardedChallenge);
                      
        } else if (anniversaryNumber == 12 && !PointsValidator.userHasAlreadyBeenAwardedTargetId(userIdAndPointsMap.get(u.Id), x12YearAnniversary)) {
          awardedChallenge = new GameEngine.AwardedChallenge(x12YearAnniversary, u.Id, Date.Today(), 'Employee Anniversary!', '12 Year', x12YearAnniversary);          
          awardedChallengesList.add(awardedChallenge);
                      
        } else if (anniversaryNumber == 13 && !PointsValidator.userHasAlreadyBeenAwardedTargetId(userIdAndPointsMap.get(u.Id), x13YearAnniversary)) {
          awardedChallenge = new GameEngine.AwardedChallenge(x13YearAnniversary, u.Id, Date.Today(), 'Employee Anniversary!', '13 Year', x13YearAnniversary);          
          awardedChallengesList.add(awardedChallenge);
                      
        } else if (anniversaryNumber == 14 && !PointsValidator.userHasAlreadyBeenAwardedTargetId(userIdAndPointsMap.get(u.Id), x14YearAnniversary)) {
          awardedChallenge = new GameEngine.AwardedChallenge(x14YearAnniversary, u.Id, Date.Today(), 'Employee Anniversary!', '14 Year', x14YearAnniversary);          
          awardedChallengesList.add(awardedChallenge);
                      
        } else if (anniversaryNumber == 15 && !PointsValidator.userHasAlreadyBeenAwardedTargetId(userIdAndPointsMap.get(u.Id), x15YearAnniversary)) {
          awardedChallenge = new GameEngine.AwardedChallenge(x15YearAnniversary, u.Id, Date.Today(), 'Employee Anniversary!', '15 Year', x15YearAnniversary);          
          awardedChallengesList.add(awardedChallenge);
                      
        } else if (anniversaryNumber == 16 && !PointsValidator.userHasAlreadyBeenAwardedTargetId(userIdAndPointsMap.get(u.Id), x16YearAnniversary)) {
          awardedChallenge = new GameEngine.AwardedChallenge(x16YearAnniversary, u.Id, Date.Today(), 'Employee Anniversary!', '16 Year', x16YearAnniversary);          
          awardedChallengesList.add(awardedChallenge);
                      
        } else if (anniversaryNumber == 17 && !PointsValidator.userHasAlreadyBeenAwardedTargetId(userIdAndPointsMap.get(u.Id), x17YearAnniversary)) {
          awardedChallenge = new GameEngine.AwardedChallenge(x17YearAnniversary, u.Id, Date.Today(), 'Employee Anniversary!', '17 Year', x17YearAnniversary);          
          awardedChallengesList.add(awardedChallenge);
                      
        } else if (anniversaryNumber == 18 && !PointsValidator.userHasAlreadyBeenAwardedTargetId(userIdAndPointsMap.get(u.Id), x18YearAnniversary)) {
          awardedChallenge = new GameEngine.AwardedChallenge(x18YearAnniversary, u.Id, Date.Today(), 'Employee Anniversary!', '18 Year', x18YearAnniversary);          
          awardedChallengesList.add(awardedChallenge);
                      
        } else if (anniversaryNumber == 19 && !PointsValidator.userHasAlreadyBeenAwardedTargetId(userIdAndPointsMap.get(u.Id), x19YearAnniversary)) {
          awardedChallenge = new GameEngine.AwardedChallenge(x19YearAnniversary, u.Id, Date.Today(), 'Employee Anniversary!', '19 Year', x19YearAnniversary);          
          awardedChallengesList.add(awardedChallenge);
                      
        } else if (anniversaryNumber == 20 && !PointsValidator.userHasAlreadyBeenAwardedTargetId(userIdAndPointsMap.get(u.Id), x20YearAnniversary)) {
          awardedChallenge = new GameEngine.AwardedChallenge(x20YearAnniversary, u.Id, Date.Today(), 'Employee Anniversary!', '20 Year', x20YearAnniversary);          
          awardedChallengesList.add(awardedChallenge);
                      
        } 
      } else {
        System.debug('Not within an Anniversary : ' + userStartDate + ' not within : ' + rollBackDate + ' -- ' + Date.Today());
      }
    }
    
    System.debug('awardedChallengesList : ' + awardedChallengesList);
    if (awardedChallengesList.size() > 0) {
      GameEngine.AwardChallenge(awardedChallengesList);
    } 
  }

  global void finish(Database.BatchableContext c) { }

}