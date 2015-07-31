public class PointsSummaryController {

//
// (c) Appirio
//
// 2013-07-11     Glenn Weinstein     Original
// 2013-10-02     Glenn Weinstein     Can only remove other users' points if you have that security permission
// 2013-10-13     Guna                Made thisQuarter() method public
// 2013-10-18     Glenn Weinstein     Add Badge Summary
// 2013-10-24     Glenn Weinstein     Add "Entered in Company Store" field on Points
// 2014-07-20     Kym Le                  Added changes for transferring points



  public Points__c proxyPoints {get; set;}   // a temporary "Points" object used solely for its User__c field, which we'll
                                             // bind to the "Appirian" lookup on the page (i.e. the selected user)
  
  public List<Points__c> points;
  public List<Awarded_Badge__c> badges;

  public String selectedPointsId {get; set;}
  public String selectedBadgeId {get; set;}
  public Boolean canRemovePoints {get; set;}

  public Decimal pointsEarnedTotal {get; set;}
  public Decimal pointsTransferredToCompanyStoreTotal {get; set;}
  public Decimal pointsTransferredToPointsBucketsTotal {get; set;}
  public Decimal pointsEarnedThisQuarter {get; set;}
  public Boolean showNewPointsBucketName {get; set;}
  public Decimal pointsBalance {get; set;}
  public Decimal transferAmount {get; set;}
  public String newPointsBucketName {get; set;}
  public List<SelectOption> transferFromList;
  public List<SelectOption> transferToList;
  public String transferFromSelection {get; set;}  
  public String transferToSelection {get; set;}    
 
  String transferredPointsRecordTypeId = Game_Settings__c.getInstance().Transferred_Points_RecordTypeId__c;
  String earnedPointsRecordTypeId = Game_Settings__c.getInstance().Earned_Points_RecordTypeId__c;
  String companyStoreId = Game_Settings__c.getInstance().Company_Store_TargetRecordId__c;
  
  public PointsSummaryController() { 

    proxyPoints = new Points__c();

    // URL parameter may specify a particular user for the "Appirian" lookup
    proxyPoints.User__c = ApexPages.CurrentPage().getParameters().get('userId');
  
    // otherwise, lookup should default to the current user
    if (proxyPoints.User__c == null) proxyPoints.User__c = UserInfo.getUserId();
    
    // if showing the current user's points, or if the user as the right security permission, show the "Remove" button
    if (proxyPoints.User__c == UserInfo.getUserId() || Game_Security__c.getInstance().Remove_Points__c == true) {
      canRemovePoints = true;
    } else {
      canRemovePoints = false;
    } 
    
    User selectedUser = [SELECT Id, 
                                Name, 
                                Direct_Deposit_Points_Into_Company_Store__c 
                         FROM   User 
                         WHERE  Id = :proxyPoints.User__c];
       
    //set the initial values for the transfer points section
    //call the method that builds the values for the 'from' drop down
    populateTransferFromList();
    
    //populate the 'to' drop down with the preliminary options
    transferToList = new List<SelectOption>();
    transferToList.add(new SelectOption('-1', '--SELECT--'));
    
    //set the 'create new points bucket' option field to hidden
    showNewPointsBucketName = false;   
    
    //set the new Points Bucket name
    newPointsBucketName = selectedUser.Name + ' - Shareable Points'; 
    
    //set the transfer amount to 0
    transferAmount = 0;
    
    
  }
  
  
  public String getDirectDepositPointsIntoCompanyStore() {
  
    //set the checkbox for the auto transfer
    //directDepositPointsIntoCompanyStore = 'Automatically every month';
    
    String result = 'Automatically every month';
    
    User selectedUser = [SELECT Id, Direct_Deposit_Points_Into_Company_Store__c from User WHERE Id = :proxyPoints.User__c];
    
    //determine if the Direct Deposit into Company Store needs to be displayed as switched off
    if (!selectedUser.Direct_Deposit_Points_Into_Company_Store__c) {
      //directDepositPointsIntoCompanyStore = 'Manual';
      result = 'Manual';
    }
  
    return result;
  }
  
  public String userDetailLink() {
  
    return URL.getSalesforceBaseUrl().toExternalForm() + '/' + UserInfo.getUserId() +  '?noredirect=1';
  
  }
  
  //get all the points buckets that the user can transfer points to/from
  //user can only transfer points to/from Points Bucket that has been created by that user
  public List<Points_Bucket__c> getPointsBuckets() {
    List<Points_Bucket__c> pointsBucket = [SELECT Id,
                                                  Name,
                                                  Title__c,
                                                  Current_Balance__c
                                           FROM   Points_Bucket__c
                                           WHERE  Owner__c = :proxyPoints.User__c
                                           AND    CreatedById = :proxyPoints.User__c];
  
    return pointsBucket;
  }
  
  
  //creates the drop down list for the transfer 'from' option
  
  public List<SelectOption> getTransferFromList() {
  
    populateTransferFromList();
    return transferFromList;
  
  }
  
  public void populateTransferFromList() {
  
    List<Points_Bucket__c> pointsBucket = getPointsBuckets();
                                           
    transferFromList = new List<SelectOption>();
    
    transferFromList.add(new SelectOption('-1', '--SELECT--'));
    transferFromList.add(new SelectOption('earnedPoints', 'Earned Points'));
            
    for(Points_Bucket__c pb : pointsBucket)
    {
      transferFromList.add(new SelectOption(pb.Name, 'Points Bucket - ' + pb.Title__c + ' (' + pb.Current_Balance__c + ' balance)'));
    }                                         
  }
  
  
  public List<SelectOption> getTransferToList() {
  
    populateTransferToList();
    return transferToList;
  
  }
  
  //creates the drop down list for the transfer 'to' option based on user's
  //selection of the transfer 'from' drop down
  public void populateTransferToList() {
    
    transferToList = new List<SelectOption>();
    List<Points_Bucket__c> pointsBucket = getPointsBuckets();
    
    system.debug('points bucket from list: ' + transferFromList);
    
    transferToList.add(new SelectOption('-1', '--SELECT--'));
    
    if (transferFromSelection != null && transferFromSelection.subString(0,2) != 'PB') {
      transferToList.add(new SelectOption('companyStore', 'Company Store'));
    }
  
    for(SelectOption so : transferFromList) {
      if (so.getValue() != transferFromSelection && so.getValue() != '-1') {
        transferToList.add(so);
      } 
    }
        
    if (pointsBucket.size() == 0) {
      transferToList.add(new SelectOption('-2', '--------------------------'));
      transferToList.add(new SelectOption('new', 'Points Bucket - Create New'));
    }
  }
  
  
  public void displayCreatePointsBucketTextField() {
  
    if (transferToSelection == 'new') {
      showNewPointsBucketName = true;
    }else {
      showNewPointsBucketName = false;
    }
  }
  
  
  private List<Challenge__c> getChallengesForNewPointsBucket() {
  
    String challengeNames = Game_Settings__c.getInstance().Chatter_Challenges_For_Points_Bucket__c.remove(' ');
    
    List<String> challengeNameParts = challengeNames.split(',');
  
    List<Challenge__c> chatterChallenges = [SELECT Id 
                                            FROM   Challenge__c 
                                            WHERE  Name in :challengeNameParts];
                                            
    system.debug('chatter challenges: ' + chatterChallenges);
    
    return chatterChallenges;
  }
  
  public List<AgeUserPointsSummary> getPoints() {
  
    system.debug('setting points');
    
    List<AgeUserPointsSummary> uiPoints = new List<AgeUserPointsSummary>();
    
    List<Points__c> points = [SELECT   Id,
                                       Name,
                                       Challenge__r.Title__c,
                                       Challenge__r.Name,
                                       Amount__c,
                                       Date__c,
                                       Source__c,
                                       Tag__c,
                                       Notes__c,
                                       RecordTypeId,
                                       Entered_In_Company_Store__c,
                                       Status__c,
                                       CreatedDate,
                                       Target_Record_Id__c
                              FROM     Points__c
                              WHERE    User__r.Id = :proxyPoints.User__c
                              ORDER BY CreatedDate DESC];
                  
    pointsEarnedTotal = 0;
    pointsTransferredToCompanyStoreTotal = 0;
    pointsTransferredToPointsBucketsTotal = 0;    
    pointsEarnedThisQuarter = 0;
    pointsBalance = 0;
    
    for (Points__c p : points) {
    
      AgeUserPointsSummary newUiPoint = new AgeUserPointsSummary(CanRemovePoints);
      newUiPoint.Id = p.Id;
      newUiPoint.Name = p.Name;
      newUiPoint.ChallengeTitle = p.Challenge__r.Title__c;
      newUiPoint.Amount = p.Amount__c;
      newUiPoint.ChallengeDate = p.Date__c;
      newUiPoint.CreatedDate = p.CreatedDate;
      newUiPoint.Notes = p.Notes__c;
      newUiPoint.Tag = p.Tag__c;
      newUiPoint.Status = p.Status__c;
      newUiPoint.RecordTypeId = p.RecordTypeId;
                                             
      uiPoints.add(newUiPoint);                                       
    

    
      //add up all earned points record type    
      if (p.Amount__c > 0 && p.RecordTypeId == earnedPointsRecordTypeId) {
        pointsEarnedTotal += p.Amount__c;
      }
      
      //figure out how many company store transfer points to subtract from total available points
      if (p.Amount__c > 0 && p.RecordTypeId == transferredPointsRecordTypeId && p.Target_Record_Id__c == companyStoreId) {
        pointsTransferredToCompanyStoreTotal -= p.Amount__c;
      }
      
      //figure out how many points bucket transfer points to subtract from total available points
      if (p.Amount__c > 0 && p.RecordTypeId == transferredPointsRecordTypeId && p.Target_Record_Id__c.substring(0,2) == 'PB') {
        pointsTransferredToPointsBucketsTotal -= p.Amount__c;
      }      
      
      //figure out how many points were transferred back into earned points from points buckets
      //when a transfer point record has a target record id of earned points, we know that the user transferred points from
      //his/her points bucket into earned points
      if (p.Amount__c > 0 && p.RecordTypeId == transferredPointsRecordTypeId && p.Target_Record_Id__c == earnedPointsRecordTypeId) {
        pointsTransferredToPointsBucketsTotal += p.Amount__c;
      
      }
      if (p.Amount__c > 0 && thisQuarter(p.Date__c) && p.RecordTypeId == earnedPointsRecordTypeId) {
        pointsEarnedThisQuarter += p.Amount__c;
      }
     
    }
    
    
    pointsBalance = pointsEarnedTotal + pointsTransferredToCompanyStoreTotal + pointsTransferredToPointsBucketsTotal;
    
    system.debug('pointsBalance: ' + pointsBalance);
    
    // refresh canRemovePoints, since we may be showing a different user now
    if (proxyPoints.User__c == UserInfo.getUserId() || Game_Security__c.getInstance().Remove_Points__c == true) {
      canRemovePoints = true;
    } else {
      canRemovePoints = false;
    }
    
                                  
    return uiPoints;                              
  }
  
  public class PointsSummaryException extends Exception {}
  
  public PageReference transferPoints() {
  
    System.debug('transferring points');
    
    List<Points_Bucket__c> pointsBucketsToUpdate = new List<Points_Bucket__c>();
    List<Points__c> pointsToInsert = new List<Points__c>();
    Points__c point = new Points__c();
    
    try {
    
      system.debug('transferFromSelection ' + transferFromSelection.subString(0,2));
      system.debug('transferFromSelection ' + transferFromSelection);      
      system.debug('transferToSelection ' + transferToSelection.subString(0,2));
      system.debug('transferToSelection ' + transferToSelection);      
      
      
      //figure out transfer logic if the user's from selection is earned points
      if (transferFromSelection == 'earnedPoints') {
        
        //make sure user has enough points to complete the transfer
        if (pointsBalance < transferAmount) {
          throw new PointsSummaryException('Not enough earned points to transfer');
        }
      
        String notesText = 'Transferred from Earned Points to ';
        
        system.debug('transfer from earned points');
        
        //create a transfer point record
        point.Amount__c = transferAmount;
        point.RecordTypeId = transferredPointsRecordTypeId;
        point.Source__c = 'Points Transfer';
        point.User__c = proxyPoints.User__c;  
        
        if (transferToSelection == 'companyStore') {
          notesText += 'Company Store';
          point.Target_Record_Id__c = companyStoreId;
          point.Status__c = 'Pending';
          
        }else if (transferToSelection.subString(0,2) == 'PB') {
          
          Points_Bucket__c transferTo = [SELECT Id, 
                                                Name,
                                                Current_Balance__c 
                                         FROM   Points_Bucket__c 
                                         WHERE  Name = :transferToSelection];
                                         
          notesText += 'Points Bucket ' + transferTo.Name;
          point.Target_Record_Id__c = transferTo.Name;                                         
                                         
          transferTo.Current_Balance__c = transferTo.Current_Balance__c + transferAmount;
          pointsBucketsToUpdate.add(transferTo); 
          
        }else if (transferToSelection == 'new') {
          Points_Bucket__c newPointsBucket = new Points_Bucket__c(Title__c = newPointsBucketName, 
                                                                  Current_Balance__c = transferAmount,
                                                                  Owner__c = proxyPoints.User__c);                                                            
                                                           
          try{                                                        
            insert newPointsBucket;
          }catch (Exception e){
            insert new Log_Message__c(Message__c = e.getMessage(), Type__c = 'Points Summary Controller');  
          }
          
          Points_Bucket__c justCreatedPB = [SELECT Id, 
                                                   Name 
                                            FROM   Points_Bucket__c 
                                            WHERE  Title__c = :newPointsBucketName
                                            AND    Owner__c = :proxyPoints.User__c];
                                            
          
          List<Challenge__c> chatterChallenges = getChallengesForNewPointsBucket();
          
          List<Challenge_Points_Bucket__c> challengePointsBucketsList = new List<Challenge_Points_Bucket__c>();
          
          for(Challenge__c c : chatterChallenges) {
            
            Challenge_Points_Bucket__c cpb = new Challenge_Points_Bucket__c();
            cpb.Challenge__c = c.Id;
            cpb.Points_Bucket__c = justCreatedPB.Id;
            
            challengePointsBucketsList.add(cpb);
            
          }
          
          insert challengePointsBucketsList;
          
          notesText += 'Shareable Points ' + justCreatedPB.Name;
          point.Target_Record_Id__c = justCreatedPB.Name;
        }
        
        point.Notes__c = notesText;     
          
        system.debug('points object: ' + point);
        
        pointsToInsert.add(point);      
      }


      //figure out transfer logic if the user's from selection is a points bucket
      if (transferFromSelection.subString(0,2) == 'PB') {
        System.debug('transferring from points bucket');
        
        Points_Bucket__c transferFrom = [SELECT Id, 
                                                Current_Balance__c 
                                         FROM   Points_Bucket__c 
                                         WHERE  Name = :transferFromSelection];
        
        //make sure the user's points bucket has enough points to complete the transfer                                 
        if (transferFrom.Current_Balance__c < transferAmount) {
          throw new PointsSummaryException('Not enough points in Points Bucket to transfer');
        }                                         
                                         
        transferFrom.Current_Balance__c = transferFrom.Current_Balance__c - transferAmount;
        
        System.debug('Transfer Points Buckets From: ' + transferFrom);
        pointsBucketsToUpdate.add(transferFrom);  

        //figure out the 'to' selection logic
        if (transferToSelection.subString(0,2) == 'PB') {
          System.debug('transferring to points bucket');
        
          Points_Bucket__c transferTo = [SELECT Id, 
                                                Current_Balance__c 
                                         FROM   Points_Bucket__c 
                                         WHERE  Name = :transferToSelection];
                                         
          transferTo.Current_Balance__c = transferTo.Current_Balance__c + transferAmount;
          pointsBucketsToUpdate.add(transferTo);  
        
        }else if(transferToSelection == 'earnedPoints') {
          system.debug('transfer to earned points');
          
          point.Amount__c = transferAmount;
          point.RecordTypeId = transferredPointsRecordTypeId;
          point.Notes__c = 'Transferred from Points Bucket ' + transferFromSelection.subString(0,7) + ' to Earned Points';
          point.User__c = proxyPoints.User__c;
          point.Target_Record_Id__c = earnedPointsRecordTypeId;
          point.Source__c = 'Points Transfer';
          
          system.debug('points object: ' + point);
        
          pointsToInsert.add(point);      
        }
      } 
      
      system.debug('points bucket to update: ' + pointsBucketsToUpdate); 
      System.debug('points bucket update list: ' + pointsBucketsToUpdate);
      System.debug('points to insert: ' + pointsToInsert);
      
      if (pointsBucketsToUpdate.size() > 0) {
        system.debug('calling dml update for points buckets');
        update pointsBucketsToUpdate;
      }  
      
      if (pointsToInsert.size() > 0) {
        system.debug('calling dml update for points');
        insert pointsToInsert;
        system.debug('done inserting points');
      }      
      
      System.debug('calling filter to redo the drop downs');
      ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Transfer successful!'));
      populateTransferFromList();
      populateTransferToList();
      showNewPointsBucketName = false;
      transferAmount = 0;
    
    } catch (Exception e) {
      ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));    
    }
  
    return null;
  }
  
  public List<Awarded_Badge__c> getBadges() {
  
  system.debug('====>proxypoints=' + proxyPoints);
  
    List<Awarded_Badge__c> badges = [SELECT   Id,
                                              Name,
                                              Badge__c,
                                              Badge_Title__c,
                                              Effective_Date__c,
                                              CreatedDate
                                     FROM     Awarded_Badge__c
                                     WHERE    User__r.Id = :proxyPoints.User__c
                                     ORDER BY CreatedDate DESC];
    return badges;
  }
  
  public PageReference removePoints() {
  
    try {

      // get Points record name, for display after deletion
      String pointsName = [SELECT Name 
                           FROM   Points__c 
                           WHERE  Id = :selectedPointsId][0].Name;

      delete [SELECT Id
              FROM   Points__c
              WHERE  Id = :selectedPointsId];
              
      ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Points record ' + pointsName + ' removed.'));

    } catch (Exception e) {
      ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
    }
          
    // simply refresh page, so list updates itself, and user sees Apex Message  
    return null;
  }

  public PageReference removeBadge() {
  
    try {

      // get Points record name, for display after deletion
      String badgeName = [SELECT Name 
                          FROM   Awarded_Badge__c 
                          WHERE  Id = :selectedBadgeId][0].Name;

      delete [SELECT Id
              FROM   Awarded_Badge__c
              WHERE  Id = :selectedBadgeId];
              
      ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Badge record ' + badgeName + ' removed.'));

    } catch (Exception e) {
      ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
    }
          
    // simply refresh page, so list updates itself, and user sees Apex Message  
    return null;
  }
  
  public boolean thisQuarter(Date d) {
  
    if (d == null) return false;
    if (d.year() != Date.today().year()) return false;
    
    Integer thisMonth = Date.today().month();
    Integer targetMonth = d.month();
    
    if (thisMonth >= 1 && thisMonth <= 3) {
      if (targetMonth >= 1 && targetMonth <= 3) {
        return true;
      } else {
        return false;
      }  
    }
 
     if (thisMonth >= 4 && thisMonth <= 6) {
      if (targetMonth >= 4 && targetMonth <= 6) {
        return true;
      } else {
        return false;
      }  
    }

    if (thisMonth >= 7 && thisMonth <= 9) {
      if (targetMonth >= 7 && targetMonth <= 9) {
        return true;
      } else {
        return false;
      }  
    }

    if (thisMonth >= 10 && thisMonth <= 12) {
      if (targetMonth >= 10 && targetMonth <= 12) {
        return true;
      } else {
        return false;
      }  
    }
  
    // it should be impossible to get this far, but I'll still return a value now, to avoid
    // a compile-time warning about "Non-void method might not return a value"
    return false;
   
  }
  
  public PageReference refresh() {
    return null;
  }
  
  public class AgeUserPointsSummary{
  
    public String Id {get; set;}
    public String Name {get; set;}
    public String ChallengeTitle {get; set;}
    public String ChallengeName {get; set;}
    public Decimal Amount {get; set;}
    public Date ChallengeDate {get; set;}
    public String Tag {get; set;}
    public String Notes {get; set;}
    public Boolean EnteredInCompanyStore {get; set;}
    public String Status {get; set;}
    public DateTime CreatedDate {get; set;}
    public String Target_Record_Id {get; set;}
    public String RecordTypeId {get; set;}
    public Boolean CanRemovePoints {get; set;}
    
    String transferredPointsRecordTypeId = Game_Settings__c.getInstance().Transferred_Points_RecordTypeId__c;
  
    
    public AgeUserPointsSummary(Boolean userCanRemovePoints){
      CanRemovePoints = userCanRemovePoints;
    }
    
    public String getSource(){
    
      if (ChallengeTitle != null) {
        return 'Challenge Awarded: ' + ChallengeTitle;
      }else {
        return 'Points Transfer';
      }
    }
    
    public Boolean getShowRemoveButton() {
    
      Boolean canRemove = false;
      
      //transfer records that are pending can be removed.  All other transfers can not be removed
      if (RecordTypeId == transferredPointsRecordTypeId && Status == 'Pending' && CanRemovePoints) {
        canRemove = true;
      //all earned points can be removed  
      }else if(RecordTypeId != transferredPointsRecordTypeId && CanRemovePoints) {
        canRemove = true;
      }
      
      return canRemove;
    
    }

  }
}