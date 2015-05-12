trigger cmc_GameActionsForAsset on CMC_Asset__c (after update) { 

  //
  // (c) Appirio
  //
  // Handles game-related actions for CMC Assets, such as awarding a challenge to an Asset's primary contributor.
  //
  // 2013-09-02     Glenn Weinstein     Original
  // 2013-09-08     Glenn Weinstein     Add "asset first timer" award
  // 2014-03-03     Saurabh Gupta       Awarding Active Asset Points based on Asset Type : Document or Code
  // 2014-03-26     Kym Le              Changed all references of "old" AwardChallenge in GameEngine class
  //                                    to "new" AwardChallenge that has custom AwardedChallenge object.
  // 2014-04-02     Saurabh Gupta       Added condition to avoid code execution if Active Asset List is empty.
  // 2014-04-23     Saurabh Gupta       Added condition to award AGE Points for Active Asset Creation when Active Date is set for S-212077.
  // 2014-05-14     Saurabh Gupta       For S-213431 : Add Asset Link to Active Asset Chatter Post
  // 2014-05-14     Saurabh Gupta       For S-214211 : Add Asset Link to Asset First Timer Chatter Post
  
  
  // PART 0 - PRELIMINARY STUFF
  
  GameEngine.AwardedChallenge challengeToAward;
  String note = '';
  List<GameEngine.AwardedChallenge> awardedChallenges = new List<GameEngine.AwardedChallenge>();

  // narrow down Trigger.new to only those Assets that just got marked "Active"
  List<cmc_Asset__c> activatedAssets = new List<cmc_Asset__c>();
  //Code Changes for S-212077 Starts
  for (cmc_Asset__c a : Trigger.new) {
    if ((a.Release_Stage__c == 'Active' && Trigger.oldMap.get(a.Id).Release_Stage__c != 'Active')  && 
    	(a.Active_Date__c != null && Trigger.oldMap.get(a.Id).Active_Date__c == null)) {
      activatedAssets.add(a);
    }
  }
  //Code Changes for S-212077 Ends

  if (!activatedAssets.isEmpty()) { //Code changes for I-110413 Starts
  // gather up primary contributors to the newly activated assets
  List<cmc_Asset_Contributor__c> contributors = [SELECT Id,
                                                        Asset__c,
                                                        Contact__c
                                                 FROM   cmc_Asset_Contributor__c
                                                 WHERE  Primary_Contact__c = true
                                                 AND    Asset__c IN :activatedAssets];
  
  //Put all Primary Contributors of an asset into Set
  Map<Id,Set<Id>> mpAllPrimaryContributors = new Map<ID,Set<Id>>();
  Set<Id> primaryContributors = new Set<Id>();
  
  for (cmc_Asset_Contributor__c ac : contributors) {
    if(!mpAllPrimaryContributors.containsKey(ac.Asset__c)) {
      mpAllPrimaryContributors.put(ac.Asset__c,new Set<Id>());
    }
    mpAllPrimaryContributors.get(ac.Asset__c).add(ac.Contact__c);
    primaryContributors.add(ac.Contact__c);
  }
  
  
  // PART 1 - AWARD "NEW ASSET" CHALLENGE TO PRIMARY CONTRIBUTOR

  // award "Create an Asset" challenge to the primary contributor for each newly activated asset  
  awardPrimaryContributors(activatedAssets,mpAllPrimaryContributors);

  // PART 2 - AWARD "ASSET FIRST TIMER" CHALLENGE IF THIS IS THE PRIMARY CONTRIBUTOR'S FIRST ACTIVE ASSET
   
  // gather up # of active assets for each primary contributor, and find first-timers
  //Changes for S-214211 Starts
  Map <Id, CMC_Asset_Contributor__c> contributorMap = new Map <Id, CMC_Asset_Contributor__c>();
  for (CMC_Asset_Contributor__c contributor : [Select Contact__c, Asset__r.Name, Asset__c From CMC_Asset_Contributor__c 
  											   Where Primary_Contact__c = true AND (Asset__r.Release_Stage__c = 'Active'
                                               OR Asset__r.Id IN :activatedAssets) AND Contact__c IN :primaryContributors]) {
  	contributorMap.put(contributor.Contact__c, contributor);                                 	
  }
  
  List<AggregateResult> assetCountsPerContributor = [SELECT   Contact__c 
                                                     FROM     cmc_Asset_Contributor__c 
                                                     WHERE    Primary_Contact__c = true 
                                                     AND      (Asset__r.Release_Stage__c = 'Active'
                                                     OR        Asset__r.Id IN :activatedAssets)
                                                     AND      Contact__c IN :primaryContributors
                                                     GROUP BY Contact__c
                                                     HAVING   COUNT(Id) = 1];
                                                       
  // award "Asset First Timer" to all first-time contributors
     for (AggregateResult ar : assetCountsPerContributor) {                      
       note = 'For being primary contributor on a newly activated asset for the first time.';                          
       //challengeToAward = new GameEngine.AwardedChallenge(cmc_GameSettings__c.getInstance().Challenge_Asset_First_Timer__c, (Id)ar.get('Contact__c'), UserInfo.getUserId(), Date.Today(), note);          
       //awardedChallenges.add(challengeToAward);
       Id contactId = (Id)ar.get('Contact__c');
       populateAndAwardChallenge(cmc_GameSettings__c.getInstance().Challenge_Asset_First_Timer__c, contactId, contributorMap.get(contactId).Asset__r.Name, contributorMap.get(contactId).Asset__c, note);                            
  }
  
    //Game Engine please award our contact points as per the challenge
    if (awardedChallenges.size() > 0) {
      GameEngine.awardChallenge(awardedChallenges);
    }  
  	//Changes for S-214211 Ends
  }//Code changes for I-110413 Ends
  
  //========================================================================================================//
  //Award primary Contributor challenge reward
  //========================================================================================================//
  private void awardPrimaryContributors(List<CMC_Asset__c> lstCMCAsset,Map<Id,Set<Id>> mpPrimaryContributors){
    
    for(CMC_Asset__c cmcAsset :lstCMCAsset) {
      Set<Id> setPrimaryContributor = mpPrimaryContributors.get(cmcAsset.ID);

      if(setPrimaryContributor == null) {
        continue;
      }
           
      for(Id contactID :setPrimaryContributor){
        note = 'For being primary contributor on a newly activated asset "' + cmcAsset.Name + '".';                          
      
        //Changes For S-170919 Starts
        if (cmcAsset.Asset_Type__c == 'Document') {
          //Changes for S-213431 Starts
           //challengeToAward = new GameEngine.AwardedChallenge(cmc_GameSettings__c.getInstance().Challenge_New_Document_Asset__c, contactID, UserInfo.getUserId(), Date.Today(), note);
           populateAndAwardChallenge(cmc_GameSettings__c.getInstance().Challenge_New_Document_Asset__c, contactID, cmcAsset.Name, cmcAsset.Id, note);
           //Changes for S-213431 Ends            
        } else {
          //Changes for S-213431 Starts
          	//challengeToAward = new GameEngine.AwardedChallenge(cmc_GameSettings__c.getInstance().Challenge_New_Asset__c, contactID, UserInfo.getUserId(), Date.Today(), note);
          	populateAndAwardChallenge(cmc_GameSettings__c.getInstance().Challenge_New_Asset__c, contactID, cmcAsset.Name, cmcAsset.Id, note);
          	//Changes for S-213431 Ends              
        }
        //Changes For S-170919 Ends
        //lstAwardeeContactIds.add(contactID);        
        //awardedChallenges.add(challengeToAward);//Changes For S-213431 
      }
    } //end of for loop
  } // end of function
  
  //Changes for S-213431 Starts
  private void populateAndAwardChallenge(String challengeName, Id awardUser, String AssetName, String assetId, String notes){
  	GameEngine.AwardedChallenge aChallenge = new GameEngine.AwardedChallenge();
  	aChallenge = new GameEngine.AwardedChallenge();
    aChallenge.challengeName = challengeName;
    aChallenge.awardedToUserId = awardUser;
    aChallenge.targetName = AssetName;
    aChallenge.targetLink = URL.getSalesforceBaseUrl().toExternalForm() + '/' + assetId;
    aChallenge.notes = notes;
    aChallenge.effectiveDate = System.today();
    
    GameEngine.awardChallenge(aChallenge);
  }
  //Changes for S-213431 Ends
}