trigger AfterWin on Opportunity (after insert, after update) {

//
// 11/25/2008   Glenn Weinstein     Original
// 1/12/2012    Glenn Weinstein     If for certain products, add original lead to nurturing campaign
// 2/12/2013    Glenn Weinstein     Don't try to add deleted contacts to nurturing campaigns
// 5/4/2013     Glenn Weinstein     Update Purchased Products field on related Account
// 9/9/2013     Glenn Weinstein     Award game challenge points if a Cloud Asset Library asset was used
// 10/16/2013   Glenn Weinstein     Create Subscription record when a subscription product is sold; only fire trigger
//                                  actions on newly won opps (not on already-won opps that are merely being edited)
// 11/4/2013    Glenn Weinstein     Also copy over the Engagement Manager from the OLI to the Subscription
// 12/27/2013   Glenn Weinstein     Add up total bookings for the account
// 1/2/2014     Glenn Weinstein     Only count wins when computing an account's total bookings; don't count legacy
//                                  bookings for "Services Commits" (e.g. Cornerstone)
// 1/4/2014     Glenn Weinstein     Check Disable Rules ("kill switch") custom setting before executing
// 03/03/2014   Saurabh Gupta		Changes for S-170919. Challenge award for Opportunity are now awarded in cmc_GameActionsForAssetUsage
//

//
// After an opportunity closes as won:
//   * Check the related Account.  If its Type = Prospect, update it to Customer.
//   * Refresh the list of Purchased Products on the related Account.
//   * Refresh the "Total Bookings" field on the related Account.
//   * If it's for a certain product, and the opp came from a lead, add the converted Contact to a nurturing campaign.
//   * Award the "Use Asset on Won Opportunity" challenge to owner and PSR owners
//   * Create a Subscription record for any subscription product that's sold
//

Disable_Rules__c dr = Disable_Rules__c.getInstance() != null ? 
  Disable_Rules__c.getInstance() : new Disable_Rules__c();

if (!dr.Skip_Opportunity_Triggers__c) {

  // ---------------------------------------------------------------------------------------------
  // -- PART 1:  UPDATE ACCOUNT TYPE, BUILD PURCHASED PRODUCTS LIST, AND UPDATE TOTAL BOOKINGS --
  // ---------------------------------------------------------------------------------------------

  // gather up the account id's for each opportunity that's being newly closed-won
  List<Id> accountIds = new List<Id>();
  for (Opportunity opp : Trigger.new) {
    if (opp.isWon && !Trigger.oldMap.get(opp.Id).isWon) { 
      accountIds.add(opp.AccountId);
    }
  }

  // get the accounts for the won opps
  List<Account> accounts = [SELECT Id, 
                                   Type
                            FROM   Account 
                            WHERE  Id IN :accountIds];
                            
  // get the related opportunity products for all won opps for each account in our list
  List<OpportunityLineItem> wonOLIs = [SELECT Id,
                                              Opportunity.Account.Id,
                                              PricebookEntry.Product2.Name
                                       FROM   OpportunityLineItem
                                       WHERE  Opportunity.IsWon = true
                                       AND    Opportunity.Account.Id in :accountIds]; 
  
  // get the related opportunities for all won opps for each account in our list
  List<Opportunity> wonOpps = [SELECT Id,
                                      Account.Id,
                                      Amount_USD__c
                               FROM   Opportunity
                               WHERE  Opportunity.Account.id in :accountIds
                               AND    IsWon = true
                               AND    (NOT Legacy_System__c LIKE '%Commit%')];
    
  List<Account> accountsToUpdate = new List<Account>();
  
  for (Account a : accounts) {
        
    // update the account Type
    
    if (a.Type == 'Prospect' || a.Type == null) {
      a.Type = 'Customer';  
    }
    
    // update the Purchased Products list
    
    Set<String> purchasedProductNameSet = new Set<String>();
    
    for (OpportunityLineItem oli : wonOLIs) {
      if (oli.Opportunity.Account.Id == a.Id) {
        purchasedProductNameSet.add(oli.PricebookEntry.Product2.Name);
      }
    }
    String purchasedProductNameString = '';
    for(String s : purchasedProductNameSet) {
      purchasedProductNameString += (purchasedProductNameString == '' ? '' : ';') + s;
    }  
    a.Purchased_Products__c = purchasedProductNameString;
    
    // update the Total Bookings
    a.Total_Bookings_USD__c = 0;
    for (Opportunity opp : wonOpps) {
      if (opp.Account.Id == a.Id) {
        a.Total_Bookings_USD__c += (opp.Amount_USD__c != null ? opp.Amount_USD__c : 0);
      }
    }
    
    
    accountsToUpdate.add(a);
  }
  
  update accountsToUpdate;

  // ----------------------------------------
  // -- PART 2:  ADD TO NURTURING CAMPAIGN --
  // ----------------------------------------
  
  // for certain products, add the related lead-converted contact (if any) to nurturing campaign
  
  // get the list of products with nurturing campaigns
  
  List<Nurturing_Campaign__c> nurturingCampaigns = [SELECT Product_Name__c,
                                                           Campaign_Id__c
                                                    FROM   Nurturing_Campaign__c];
  
  // get all line items for won opportunities being closed/won now
  
  List<Id> newlyWonOppIds = new List<Id>();
  for (Opportunity opp : Trigger.new) {
    if (opp.IsWon && !Trigger.oldMap.get(opp.Id).isWon) {
      newlyWonOppIds.add(opp.Id);
    }
  }
  
  List<OpportunityLineItem> lineItems = [SELECT Id,
                                                OpportunityId,
                                                Opportunity.Name,
                                                Opportunity.CloseDate,
                                                Opportunity.AccountId,
                                                Opportunity.Sales_Geography__c,
                                                Opportunity.Engagement_Manager__c,
                                                PriceBookEntry.Name,
                                                PriceBookEntry.Product2.Id,
                                                Product_Or_Services_Type__c,
                                                Number_of_Seats__c,
                                                Quantity,
                                                TotalPrice,
                                                Annual_Price_Per_Seat__c,
                                                Sub_Product__c,
                                                CurrencyIsoCode
                                         FROM   OpportunityLineItem
                                         WHERE  OpportunityId IN :newlyWonOppIds];
  
  // figure out which opportunities have line items for products with a matching nurturing campaign 
  
  List<Id> oppsWithProducts = new List<Id>();                                  
  for (OpportunityLineItem oli : lineItems) {
    for (Nurturing_Campaign__c nc : nurturingCampaigns) {
      if (oli.PriceBookEntry.Name == nc.Product_Name__c) {
        oppsWithProducts.add(oli.OpportunityId);
      }
    }
  }
                                              
  // get the converted contacts related to the leads that those opportunities came from
  
  List<Lead> convertedLeadsForProductWins = [SELECT ConvertedContactId,
                                                    ConvertedOpportunityId
                                             FROM   Lead
                                             WHERE  ConvertedOpportunityId IN :oppsWithProducts];
  
  // find out if any contacts have been deleted (if they have, trying to create a CampaignMember for them will result in a 
  // INSUFFICIENT_ACCESS_ON_CROSS_REFERENCE_ENTITY exception)
  
  List<Id> convertedContactIds = new List<Id>();
  for (Lead l : convertedLeadsForProductWins) {
    convertedContactIds.add(l.ConvertedContactId);
  }
  
  List<Contact> convertedContactsThatAreDeleted = [SELECT Id
                                                   FROM   Contact
                                                   WHERE  Id in :convertedContactIds
                                                   AND    IsDeleted = true
                                                   ALL ROWS];
  
  Set<Id> deletedContactIds = new Set<Id>();
  for (Contact c : convertedContactsThatAreDeleted) {
    deletedContactIds.add(c.Id);
  }
  
  // add the converted contacts to the right nurturing campaigns
  
  List<CampaignMember> campaignMembers = new List<CampaignMember>();
  for (Lead convertedLead : convertedLeadsForProductWins) {
    if (!deletedContactIds.contains(convertedLead.ConvertedContactId)) {
      for (OpportunityLineItem oli : lineItems) {
        if (oli.OpportunityId == convertedLead.ConvertedOpportunityId) {
          for (Nurturing_Campaign__c nc : nurturingCampaigns) {
            if (oli.PriceBookEntry.Name == nc.Product_Name__c) {
              CampaignMember cm = new CampaignMember();
              cm.ContactId = convertedLead.ConvertedContactId;
              cm.CampaignId = nc.Campaign_Id__c;
              campaignMembers.add(cm);
            }
          }
        }
      }
    }
  }
  
  insert campaignMembers;
  
  /*
  Commented code for S-170919. Challenge award for Opportunity are now awarded in cmc_GameActionsForAssetUsage
  // ----------------------------------------------------------
  // -- PART 3:  AWARD CHALLENGE TO OWNERS IF ASSET WAS USED --
  // ----------------------------------------------------------
  
  // gather up just the newly WON opportunities
  
  List<Opportunity> wonOpportunities = new List<Opportunity>();
  for (Opportunity opp : Trigger.new) {
    if (opp.isWon && !Trigger.oldMap.get(opp.Id).isWon) {
      wonOpportunities.add(opp);
    }
  }
  
  // gather up the PSRs for the wins
  List<Presales_Request__c> psrs = [SELECT Id,
                                           OwnerId,
                                           Opportunity__c
                                    FROM   Presales_Request__c
                                    WHERE  Opportunity__c IN :wonOpportunities];
  
  // gather up all the Asset Usages for the wins
  
  List<cmc_Asset_Usage__c> assetUsages = [SELECT Id,
                                                 Opportunity__c
                                          FROM   cmc_Asset_Usage__c
                                          WHERE  Opportunity__c IN :wonOpportunities];
  
  for (Opportunity opp : wonOpportunities) {
    Boolean usedAsset = false;
    for (cmc_Asset_Usage__c au : assetUsages) {
      if (au.Opportunity__c == opp.Id) {
        usedAsset = true;
      }
    }
    if (usedAsset) {
    
      // award the challenge to the opportunity owner
      
      GameEngine.awardChallenge(Game_Settings__c.getInstance().Challenge_Use_Asset_on_Won_Opportunity__c, 
                                opp.OwnerId,
                                'For using an asset on a won opportunity, "' + opp.Name + '".');
      
      // find all the PSR owners for this opp, and award them the challenge, too
      
      Set<Id> psrOwners = new Set<Id>();
      for (Presales_Request__c psr : psrs) {
        if (psr.Opportunity__c == opp.Id) {
          psrOwners.add(psr.OwnerId);
        }
      }
    
      for (Id psrOwnerId : psrOwners) {
        GameEngine.awardChallenge(Game_Settings__c.getInstance().Challenge_Use_Asset_on_Won_Opportunity__c, 
                                  psrOwnerId,
                                  'For being the Presales Request owner for at least one PSR ' +
                                  'on a won opportunity where an asset was used, "' + opp.Name + '".');
      
      }
    
    }
  } */   
  
  // ---------------------------------------------------------------------------------------
  // -- PART 4:  CREATE SUBSCRIPTION RECORDS FOR ANY SUBSCRIPTION PRODUCTS THAT WERE SOLD --
  // --          (EXCEPT CLOUD SYNC, SINCE THOSE SUBSCRIPTIONS ARE ALREADY AUTO-CREATED)  --
  // ---------------------------------------------------------------------------------------

  List<Subscription__c> subList = new List<Subscription__c>();

  for (OpportunityLineItem oli : lineItems) {
    if (oli.Product_Or_Services_Type__c == 'Subscription Product' && oli.PriceBookEntry.Name != 'Cloud Sync') {
      Subscription__c sub = new Subscription__c();
      sub.Name = oli.Opportunity.Name + (oli.Sub_Product__c != null ? ' (' + oli.Sub_Product__c + ')' : '');
      sub.CurrencyIsoCode = oli.CurrencyIsoCode;
      sub.Account__c = oli.Opportunity.AccountId;
      sub.Opportunity__c = oli.Opportunity.Id;
      sub.Product__c = oli.PriceBookEntry.Product2.Id;
      sub.Maximum_Users__c = oli.Number_of_Seats__c;
      sub.Number_Of_Months__c = oli.Quantity;
      sub.Annual_Price_Per_Seat__c = oli.Annual_Price_Per_Seat__c;
      sub.Start_Date__c = oli.Opportunity.CloseDate;
      sub.Geo__c = oli.Opportunity.Sales_Geography__c;
      sub.Community_Success_Manager__c = oli.Opportunity.Engagement_Manager__c;
      sub.Status__c = 'Active';
      subList.add(sub);
    }
  }
  
  insert subList;                                   
 
}

}