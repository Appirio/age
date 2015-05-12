trigger cmc_GameActionsForAssetUsage on CMC_Asset_Usage__c (after insert) {

  //
  // (c) Appirio
  //
  // Handles game-related actions for CMC Asset Usage, such as awarding a challenge to the asset user.
  //
  // 2013-09-08     Glenn Weinstein     Original
  // 2013-10-20     Glenn Weinstein     Call bulkified GameEngine method, to avoid "too many future calls" errors
  // 2013-12-26     Michael Press       Switch to Usage_Type__c field on Asset Usages to determine proposed vs. actual usage
  // 2014-02-28     Saurabh Gupta       Made changes to award reward points to Asset Reuse (Proposed) on Opportunity and Story.
  // 2014-03-03     Saurabh Gupta       To exclude Asset Usages created from Cloning a Story.
  // 2014-03-26     Kym Le              Changed "old" GameEngine AwardChallenge method to use "new" AwardChallenge method
  //                                    that uses custom object.
  // 2014-03-27     Saurabh Gupta       Removed commented code.
  // 2014-03-27     Saurabh Gupta       Changes related to I-101441.
  // 2014-04-23     Saurabh Gupta       Changes for S-212081
  // 2014-04-24     Saurabh Gupta       S-212304 : To AGE Points irrespective of Active Assignments. Only Resource must be an Appirio Employee
  // 2014-05-01		Saurabh Gupta		S-212752 : To display Asset Link on Asset Royalty Chatter Feeds
  // 2014-05-02		Saurabh Gupta       S-212969 & S-212970 : To display Asset Link on Asset Proposed and Reused Chatter Feeds
  // 2014-05-07     Saurabh Gupta       S-213274 : Award AGE Points to Opportunity Owner and Presales users for Asset Propose on Opportunity
  // 2014-05-18     Saurabh Gupta       S-214211 : To display Asset Name and Asset Link for First Timer Active Asset
  // 2014-05-18     Saurabh Gupta       S-214755 : To display Asset Name and Asset Link for Propsing an Asset (Opportunity Owner and Presales Owner) 
  // 2014-05-19     Saurabh Gupta       S-214110 : Award AGE Points based once per Product when Field: 'Allow Reuse only once per project' is True
  // 2014-06-06     Saurabh Gupta       I-117439 : To remove SOQL errors and pass List of Awardees rather than single at a time for Presales Users
  // 2014-09-10     Saurabh Gupta       S-259138 : Add User Feedback for Primary Contributors of Asset on Challenge Earned Email for Asset Royalty.
  // 2014-09-19     Saurabh Gupta       I-130899 : Add space on Notes for being Primary Contributors of Asset
  // 2014-09-30     Saurabh Gupta       I-132363 : Add space on Notes for Asset Usages (Propose and Reuse Assets)

  // PART 0 - PRELIMINARY STUFF
  
  // set up variables for GameEngine
  String note = '';
  GameEngine.AwardedChallenge challengeToAward;
  List<GameEngine.AwardedChallenge> awardedChallenges = new List<GameEngine.AwardedChallenge>();
  
  // set up lists to store details of the challenges we plan to award (they'll all be sent to GameEngine at the end)
  List<String> challengeNames = new List<String>();
  List<Id> contactIds = new List<Id>();
  List<String> notesList = new List<String>();
  
  List <CMC_Asset_Usage__c> validAssetOppUsages = new List<CMC_Asset_Usage__c>();
  List <Id> assetReuseCreatorIdList = new List<Id>();
  Map <Id, List <Id>> assetReuseCreatorIdOppMap = new Map <Id, List <Id>>();
  List <CMC_Asset_Usage__c> allValidAssets = new List <CMC_Asset_Usage__c>();
  
  // narrow down Trigger.new to only those Asset Usages where Asset Use Type (Usage_Type__c) = "Asset Used"
  List<cmc_Asset_Usage__c> validAssetUsages = new List<cmc_Asset_Usage__c>();
  
  Map <String, Set <Id>> productAssetListMap = new Map <String, Set <Id>>();
  Set <Id> assetIDSet = new Set <Id>();
  List <CMC_Asset_Usage__c> assetUsageList = new List <CMC_Asset_Usage__c>();
  
  for (CMC_Asset_Usage__c au : [Select Id, Created_By_Cloning__c, Asset_Used_By__c, Opportunity__c, Story__c,  
  								Project_Id__c, Asset__c, Asset__r.Allow_Reuse_Only_Once_Per_Project__c, Product_Name__c, Story__r.Product_Id__c, 
  								Usage_Type__c, Asset__r.Name, Notes__c,
  								ProjectLookup__c,ProjectLookup__r.Name  
  								From CMC_Asset_Usage__c Where Id IN: Trigger.newMap.keySet()]) {//Added for S-259138
  	assetUsageList.add(au);
  	assetIDSet.add(au.Asset__c);
  	
  	if (productAssetListMap.get(au.Story__r.Product_Id__c) == null) {  		
  		productAssetListMap.put(au.Story__r.Product_Id__c, new Set <Id>());
  	}
  	productAssetListMap.get(au.Story__r.Product_Id__c).add(au.Asset__c);
  }
  
  Map <String, Set <Id>> productUsedAssetMap = new Map <String, Set <Id>>();
  Map <String, Set <Id>> productProposedAssetMap = new Map <String, Set <Id>>();
  for (CMC_Asset_Usage__c au : [Select Id, Story__r.Product_Id__c, Asset__c, ProjectLookup__c,ProjectLookup__r.Name, Usage_Type__c From CMC_Asset_Usage__c 
  								Where Id Not IN: Trigger.newMap.keySet() AND Asset__c IN: assetIDSet 
  								AND Story__r.Product_Id__c IN: productAssetListMap.keySet()]) {
  	if (CMC_Constants.ASSET_USAGE_TYPE_USED.equals(au.Usage_Type__c)) {
	  	if (productUsedAssetMap.get(au.Story__r.Product_Id__c) == null) {
	  		productUsedAssetMap.put(au.Story__r.Product_Id__c, new Set <Id>());
	  	}
	  	productUsedAssetMap.get(au.Story__r.Product_Id__c).add(au.Asset__c);
  	} else if (CMC_Constants.ASSET_USAGE_TYPE_PROPOSED.equals(au.Usage_Type__c)) {
  		if (productProposedAssetMap.get(au.Story__r.Product_Id__c) == null) {
	  		productProposedAssetMap.put(au.Story__r.Product_Id__c, new Set <Id>());
	  	}
	  	productProposedAssetMap.get(au.Story__r.Product_Id__c).add(au.Asset__c);
  	}
  }
  
  for (CMC_Asset_Usage__c au : assetUsageList) {
    if (au.Usage_Type__c != null) {
      if (au.Story__c != null && !au.Created_By_Cloning__c) {
      	  	if (au.Asset__r.Allow_Reuse_Only_Once_Per_Project__c) {
      	  		if (CMC_Constants.ASSET_USAGE_TYPE_USED.equals(au.Usage_Type__c) && productUsedAssetMap.containsKey(au.Story__r.Product_Id__c)) {
      	  			if (!productUsedAssetMap.get(au.Story__r.Product_Id__c).contains(au.Asset__c)) {
	      	  			validAssetUsages.add(au);
	      	  			assetReuseCreatorIdList.add(au.Asset_Used_By__c);
      	  			}
      	  		} else if (CMC_Constants.ASSET_USAGE_TYPE_PROPOSED.equals(au.Usage_Type__c) && productProposedAssetMap.containsKey(au.Story__r.Product_Id__c)) {
      	  			if (!productProposedAssetMap.get(au.Story__r.Product_Id__c).contains(au.Asset__c)) {
	      	  			validAssetUsages.add(au);
	      	  			assetReuseCreatorIdList.add(au.Asset_Used_By__c);
      	  			}
      	  		} else {
      	  			validAssetUsages.add(au);
      	  			assetReuseCreatorIdList.add(au.Asset_Used_By__c);
      	  		}
      	  	} else {
      	  		validAssetUsages.add(au);
      	  		assetReuseCreatorIdList.add(au.Asset_Used_By__c);
      	  	}
      }
      else if(au.ProjectLookup__c != null && !au.Created_By_Cloning__c){
        validAssetUsages.add(au);
        assetReuseCreatorIdList.add(au.Asset_Used_By__c);
      }
      else if (au.Opportunity__c != null) {
        validAssetOppUsages.add(au);
        if (!assetReuseCreatorIdOppMap.containsKey(au.Opportunity__c)) {
            assetReuseCreatorIdOppMap.put(au.Opportunity__c, new List <Id>());
        }
        assetReuseCreatorIdOppMap.get(au.Opportunity__c).add(au.Asset_Used_By__c);//Use map
      }
    }    
  }
  
  // collect up the Ids of the related assets, projects, and opportunities
  Set<Id> assetIds = new Set<Id>();
  Set<Id> projectIds = new Set<Id>();
  Set<Id> opportunityIds = new Set<Id>();
  Set <Id> StoryIds = new Set <Id>();
  
  allValidAssets.addAll(validAssetOppUsages);
  allValidAssets.addAll(validAssetUsages);
  for (cmc_Asset_Usage__c au : allValidAssets) {
    assetIds.add(au.Asset__c);
    projectIds.add(au.Project_Id__c);
    opportunityIds.add(au.Opportunity__c);
    
    storyIds.add(au.Story__c);
  }
  
  // grab the primary contributors to the related assets
  List<cmc_Asset_Contributor__c> contributors = [SELECT Id,
                                                        Asset__c,
                                                        Asset__r.Name,
                                                        Contact__c
                                                 FROM   cmc_Asset_Contributor__c
                                                 WHERE  Primary_Contact__c = true
                                                 AND    Asset__c IN :assetIds];
  
  // gather up names of related assets, projects, and opportunities
  List<cmc_Asset__c> relatedAssets = [SELECT Id,
                                             Name
                                      FROM   cmc_Asset__c
                                      WHERE  Id IN :assetIds];
  List<Opportunity> relatedOpportunities = [SELECT Id,
                                                   Name
                                            FROM   Opportunity
                                            WHERE  Id IN :opportunityIds];
  List<pse__Proj__c> relatedProjects = [SELECT Id,
                                               Name
                                        FROM   pse__Proj__c
                                        WHERE  Id IN :projectIds];
  
  Set <Id> productIds = new Set <Id>();
  for (CMC_Story__c story : [Select Id, Product_Id__c From CMC_Story__c Where Id IN: storyIds]) {
  	productIds.add(story.Product_Id__c);
  }
  
  List <CMC_Product__c> relatedProducts = [Select Id, Name From CMC_Product__c Where Id IN: productIds];

  // PART 1 - award "Asset Royalty" challenge to the assets' primary contributors
  for (cmc_Asset_Contributor__c ac : contributors) {  
    // grab related opportunity or project name
    String relatedRecordName = '';
    String assetUsageNotes = null;//Added for S-259138
    for (cmc_Asset_Usage__c au : allValidAssets) {
      if (au.Asset__c == ac.Asset__c) {
        for (Opportunity opp : relatedOpportunities) {
          if (opp.Id == au.Opportunity__c) {
            relatedRecordName = 'opportunity "' + opp.Name + '"';
          }
        }
        for (pse__Proj__c p : relatedProjects) {
          if (p.Id == au.Project_Id__c) {
            relatedRecordName = 'project "' + p.Name + '"';
          }
        }        
        //Changes for S-259138 Starts
        if (CMC_Constants.ASSET_USAGE_TYPE_USED.equals(au.Usage_Type__c)) {
        	assetUsageNotes = au.Notes__c;
        }
        //Changes for S-259138 Ends
      }
    }
    
    if (relatedRecordName != '') {
    	note = '&nbsp;' + 'For being the primary contributor on Asset "' + ac.Asset__r.Name + 
              '", which just got used on ' + relatedRecordName + '.';
    } else {
    	note = '&nbsp;' + 'For being the primary contributor on Asset "' + ac.Asset__r.Name + 
              '", which just got used.';
    }
    //Changes for S-259138 Starts
    if (assetUsageNotes != null) {
    	note += ' <br> <br> Asset Usage Feedback: ' +  assetUsageNotes;
    }
    //Changes for S-259138 Ends
    populateAndAwardChallenge(cmc_GameSettings__c.getInstance().Challenge_Asset_Royalties__c, ac.Contact__c, ac.Asset__r.Name, ac.Asset__c, note);
  }
  
  // PART 2 - award "Use Asset on Project" challenge to active Asset Reuse Resource  
  // gather up active assigned resources with at least 6 billable hours on projects  
  List <Contact> contactList = [Select Id From Contact Where pse__Is_Resource__c = true and Id IN: assetReuseCreatorIdList];
    
  if (!contactList.isEmpty()) {
      for (Id resourceId: assetReuseCreatorIdList) {  
        // grab related project and asset names
        boolean isValidReuse = false;
        
        String productName = '';
        String assetID = '';
        String assetName = '';
        String assetUsageType = ''; 
        for (cmc_Asset_Usage__c au : validAssetUsages) {
          for (CMC_Product__c prod : relatedProducts) {
          	if (prod.Id == au.Story__r.Product_Id__c) {
          		productName = prod.Name;
          	}
          }
          
          for (cmc_Asset__c asset : relatedAssets) {
          	if (asset.Id == au.Asset__c) {
            	assetName = asset.Name;
            	assetID = asset.Id;//Changes For S-212752
            	assetUsageType = au.Usage_Type__c;
            	isValidReuse = true; //Code Fix changes for for S-170919
          	}
          }
        }        
        note = '&nbsp;' + 'For using asset "' + assetName + '" on Product "' + productName + '".';
        
        if (assetUsageType == CMC_Constants.ASSET_USAGE_TYPE_PROPOSED) {
          populateAndAwardChallenge(cmc_GameSettings__c.getInstance().Challenge_Propose_Asset_on_Project__c, resourceId, assetName, assetId, note);          
        } else if (assetUsageType == CMC_Constants.ASSET_USAGE_TYPE_USED) {
          populateAndAwardChallenge(cmc_GameSettings__c.getInstance().Challenge_Use_Asset_on_Project__c, resourceId, assetName, assetId, note);
        }        
      }
  }
  
  // PART 3 - award "Reuse on Opportunity" challenge to active Asset Reuse Resource and Presales request users
  // gather up the PSRs for the wins  
  List <Presales_Request__c> psrs = [SELECT Id, OwnerId, Opportunity__c
                                    FROM   Presales_Request__c
                                    WHERE  Opportunity__c IN : assetReuseCreatorIdOppMap.keySet()];
  
  Map <Id, CMC_Asset_Usage__c> oppAssetUsageMap = new Map <Id, CMC_Asset_Usage__c>();
  List <CMC_Asset_Usage__c> oppAssetUsages = new List <CMC_Asset_Usage__c>();
  
  for (Opportunity opp : [Select Id, OwnerId, Name From Opportunity Where Id IN: assetReuseCreatorIdOppMap.keySet()]) {
      //Awarding Point to Asset Reuser on Opportunity     
      for (cmc_Asset_Usage__c au : validAssetOppUsages) {
          if (au.Opportunity__c == opp.Id) {
            if (assetReuseCreatorIdOppMap.containsKey(opp.Id)) {
                for (Id resId : assetReuseCreatorIdOppMap.get(opp.Id)) {                    
                    note = 'For proposing an asset on a Opportunity, "' + opp.Name + '".';
                    oppAssetUsageMap.put(opp.Id, au);                   
                    populateAndAwardChallenge(cmc_GameSettings__c.getInstance().Challenge_Propose_Asset_on_Opportunity__c, resId, au.Asset__r.Name, au.Asset__c, note);
                }
            }
          }
      }
    
      // award the challenge to the opportunity owner
      challengeNames.add(cmc_GameSettings__c.getInstance().Challenge_Propose_Asset_on_Opportunity__c);
      contactIds.add(opp.OwnerId);
      notesList.add('For being owner of a Opportunity, "' + opp.Name + '".');//Change For S-212081
      
      if (oppAssetUsageMap.containsKey(opp.Id)) {
      	oppAssetUsages.add(oppAssetUsageMap.get(opp.Id));
      }
      
      // find all the PSR owners for this opp, and award them the challenge, too      
      Set <Id> psrOwners = new Set <Id>();
      for (Presales_Request__c psr : psrs) {
        if (psr.Opportunity__c == opp.Id) {
          psrOwners.add(psr.OwnerId);
        }
      }
      for (Id psrOwnerId : psrOwners) {
        challengeNames.add(cmc_GameSettings__c.getInstance().Challenge_Propose_Asset_on_Opportunity__c);
        contactIds.add(psrOwnerId);
        notesList.add('For being the Presales Request owner for at least one PSR ' +
                  'on a opportunity where an asset was proposed, "' + opp.Name + '".');//Change For S-212081
        if (oppAssetUsageMap.containsKey(opp.Id)) {
      		oppAssetUsages.add(oppAssetUsageMap.get(opp.Id));
      	}
      }
  }
  
  //Award Rewards points to Opportunity Owners and PreSales Owner
  if (!challengeNames.isEmpty()) {
  	populateAndAwardChallengeList(challengeNames, contactIds, oppAssetUsages, notesList);
  }
  
  // all done.  Now let's send our final list of challenges to award, to the GameEngine.
  System.debug('cmc_GameActionsForAssetUsage sending ' + awardedChallenges.size() + ' awards to GameEngine');
  GameEngine.awardChallenge(awardedChallenges);
  
  private void populateAndAwardChallenge(String challengeName, Id awardUser, String AssetName, String assetId, String notes){
  	GameEngine.AwardedChallenge aChallenge = populateChallenge(challengeName, awardUser, AssetName, assetId, notes);
    GameEngine.awardChallenge(aChallenge);
  }
  
  private void populateAndAwardChallengeList(List <String> challengeNameList, List <Id> awardUserList, List <CMC_Asset_Usage__c> oppAssetUsageList, 
  										     List <String> noteContentList){
  	List <GameEngine.AwardedChallenge> aChallengeList = new List <GameEngine.AwardedChallenge>();
  	for (integer counter = 0; counter < challengeNameList.size(); counter++) {
  		String assetId = oppAssetUsageList[counter].Asset__c;
  		GameEngine.AwardedChallenge aChallenge = populateChallenge(challengeNameList[counter], awardUserList[counter],  
  																   oppAssetUsageList[counter].Asset__r.Name, oppAssetUsageList[counter].Asset__c, 
  																   noteContentList[counter]);  		
	    aChallengeList.add(aChallenge);
  	}    
    GameEngine.awardChallenge(aChallengeList);
  }
  
  private GameEngine.AwardedChallenge populateChallenge(String challengeName, Id awardUser, String AssetName, String assetId, String notes) {
  	GameEngine.AwardedChallenge aChallenge = new GameEngine.AwardedChallenge();
    aChallenge.challengeName = challengeName;
    aChallenge.awardedToUserId = awardUser;
    aChallenge.targetName = AssetName;
    aChallenge.targetLink = URL.getSalesforceBaseUrl().toExternalForm() + '/' + assetId;
    aChallenge.notes = notes;
    aChallenge.effectiveDate = System.today();
    
    return aChallenge;
  }
}