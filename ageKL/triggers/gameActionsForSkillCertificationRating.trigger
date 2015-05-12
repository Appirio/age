trigger gameActionsForSkillCertificationRating on pse__Skill_Certification_Rating__c (after insert) {

  //
  // (c) Appirio
  //
  // 2013-09-11     Glenn Weinstein     Original
  // 2014-03-01     Kym Le              Changed awarding of Points to call new GameEngine.AwardChallenge
  
  
  List<GameEngine.AwardedChallenge> awardedChallenges = new List<GameEngine.AwardedChallenge>();
  
  for (pse__Skill_Certification_Rating__c scr : Trigger.new) {
    if (scr.Skill_Or_Certification__c == 'Certification' && scr.Status__c == 'Active') {
    
    
      
      //GameEngine.awardChallengeWithTag(Game_Settings__c.getInstance().Challenge_Certification__c,
      //                                 scr.pse__Resource__c,
      //                                 scr.Skill_Certification_Name__c,
      //                                 'For achieving the "' + scr.Skill_Certification_Name__c + '" certification.');
                                       
                                       
      String note = 'For achieving the "' + scr.Skill_Certification_Name__c + '" certification.';
      GameEngine.AwardedChallenge challengeToAward = new GameEngine.AwardedChallenge(Game_Settings__c.getInstance().Challenge_Certification__c, scr.pse__Resource__c, UserInfo.getUserId(), Date.Today(), note);          
      awardedChallenges.add(challengeToAward);                                        
    }
  }
  
  if (awardedChallenges.size() > 0) {
    GameEngine.awardChallenge(awardedChallenges);
  }  

}