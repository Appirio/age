public with sharing class IdeaTriggerHandler {

  private boolean m_isExecuting = false;
  
  public IdeaTriggerHandler(boolean isExecuting){
    m_isExecuting = isExecuting;
  }

  
  public void OnAfterUpdate(Map<Id, Idea> newIdea){
  
    Set<Id> userIds = new Set<Id>();
    List<GameEngine.AwardedChallenge> awardedChallengesList = new List<GameEngine.AwardedChallenge>();
    Map<Id, List<Points__c>> userIdAndPointsMap = new Map<Id, List<Points__c>>();
  
    //get the challenge for Ideas get Implemented 
    String challenge = Game_Settings__c.getInstance().Challenge_Idea_Gets_Implemented__c;
    System.debug('Game Setting Challenge: ' + challenge);
  
    //if there's no challenge, exit out
    if(challenge == '') {
      return;
    }      
  
    //get all the ideas that have a status of implemented
    Map<Id, Idea> ideasToProcess = new Map<Id, Idea>([SELECT Id, 
                                                             Title,
                                                             CreatedById
                                                      FROM   Idea 
                                                      WHERE  Status = 'Implemented!'
                                                      AND    Id IN :newIdea.keySet()]);
                                                      
    System.debug('Ideas: ' + ideasToProcess);                                                      
                                       
    if (ideasToProcess.isEmpty() == false) {
      
      //get all the users that have implemented ideas
      for (Idea i : ideasToProcess.values()) {
        userIds.add(i.CreatedById);
      }
  
     
      userIdAndPointsMap = PointsValidator.getAllUsersAndPointsForTargetRecordId(userIds);
  
  
      for(Idea i : ideasToProcess.values()) {
        System.debug('process the idea');
    
        if (!PointsValidator.userHasAlreadyBeenAwardedTargetId(userIdAndPointsMap.get(i.CreatedById), i.Id)) {
                   
          GameEngine.AwardedChallenge awardedChallenge = new GameEngine.AwardedChallenge(challenge, i.createdById, Date.Today(), 'For idea that was implemented', i.Title, i.Id);
          awardedChallengesList.add(awardedChallenge);
          
          System.debug('awarded challenge: ' + awardedChallenge);
            
        }
      }
      
      
      System.debug('awarded challenge list: ' + awardedchallengesList);
      if (awardedChallengesList.size() > 0) {
      
        GameEngine.AwardChallenge(awardedChallengesList);
      }
    }
  }

}