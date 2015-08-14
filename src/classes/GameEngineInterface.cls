public interface GameEngineInterface {

  // 
  // (c) Appirio
  //
  // Public API for the Appirio Game Engine (AGE)
  //
  // 2013-09-02     Glenn Weinstein     Original
  // 2013-10-20     Glenn Weinstein     Add bulkified methods (that take lists of challenges)
  // 2014-04-26     Glenn Weinstein     Add ability to pass in Target Name and Target Link
  // 2014-04-29     Glenn Weinstein     Added new method signature to award Challenge that takes an AwardChallenge record 
  //
  
  // 
  // The first method in this interface takes a structure called AwardedChallenge as a parameter.  This structure
  // (an Apex class) contains all necessary fields for awarding a challenge to a user.
  //
  // Note that Apex methods that take complex records cannot be used as external web services.  Therefore, the 
  // other methods in this interface all take simple strings or lists of strings as parameters; they are suitable
  // for exposure as web services.
  //
  
  //
  // Here is the signature of the AwardedChallenge class; you'll need to pass in an instance of this class
  // in order to call awardChallenge(AwardedChallenge) -
  //
  //   class AwardedChallenge {
  //     String challengeName;
  //     String awardedToUserId;
  //     String awardedFromUserId ;
  //     String notes;
  //     Date effectiveDate;
  //     String tag;
  //     String targetRecordId;
  //   }
  //
    
  /**
   * Award a challenge to a user
   *
   * @param  awardChallenge          Structure that contains all necessary fields for awarding a challenge to a user
   */
  // 
  // commented out for now because Apex doesn't allow inner classes in interfaces... but you can still implement
  // and call this method!
  //
  // void awardChallenge(AwardedChallenge awardChallenge);

  /**
   * Award a challenge to a user, passing in parameters as strings
   *
   * @param  challengeName           Challenge Name, e.g. "C-0038"
   * @param  awardeeUserorContactId  User or contact who is being awarded the challenge, e.g. "00550000000vgY4"
   * @param  notes                   Audit notes on how or why the challenge is being awarded
   * @param  effectiveDate           (optional) Effective date of the granted points, e.g. "2013-09-02"
   */ 
  void awardChallenge(String challengeName, 
                      Id     awardeeUserOrContactId,
                      String notes,
                      String effectiveDate);
  void awardChallenge(String challengeName, 
                      Id     awardeeUserOrContactId,
                      String notes);

  /**
   * Award a challenge to a user, and include a tag representing any arbitrary attribute of the award
   *
   * @param  challengeName           Challenge Name, e.g. "C-0038"
   * @param  awardeeUserorContactId  User or contact who is being awarded the challenge, e.g. "00550000000vgY4"
   * @param  tag                     Arbitrary string characterizing the award, e.g. "DEV-501" for a certification
   * @param  notes                   Audit notes on how or why the challenge is being awarded
   * @param  effectiveDate           (optional) Effective date of the granted points, e.g. "2013-09-02"
   */ 
  void awardChallengeWithTag(String challengeName, 
                             Id     awardeeUserOrContactId,
                             String tag,
                             String notes,
                             String effectiveDate);
  void awardChallengeWithTag(String challengeName, 
                             Id     awardeeUserOrContactId,
                             String tag,
                             String notes);

  /**
   * Award a challenge to a user, and include a target name & target link representing why/how the challenge was awarded
   *
   * @param  challengeName           Challenge Name, e.g. "C-0038"
   * @param  awardeeUserorContactId  User or contact who is being awarded the challenge, e.g. "00550000000vgY4"
   * @param  targetName              Name of record representing why/how challenge was awarded, e.g. "SOQL Query Tool Asset"
   * @param  targetLink              URL of targetName, e.g. "https://appirio.my.salesforce.com/01p50000000RySY"
   * @param  notes                   Audit notes on how or why the challenge is being awarded
   * @param  effectiveDate           (optional) Effective date of the granted points, e.g. "2013-09-02"
   */ 
  void awardChallengeWithTarget(String challengeName, 
                                Id     awardeeUserOrContactId,
                                String targetName,
                                String targetLink,
                                String notes,
                                String effectiveDate);
  void awardChallengeWithTarget(String challengeName, 
                                Id     awardeeUserOrContactId,
                                String targetName,
                                String targetLink,
                                String notes);

  /**
   * Award a list of challenges to users
   *
   * @param  challengeNames           Ordered list of Challenge Names, e.g. "C-0038"
   * @param  awardeeUserorContactIds  Ordered list of users or contacts who are being awarded the challenges, e.g. "00550000000vgY4"
   * @param  notes                    Ordered list of audit notes on how or why the challenges are being awarded
   * @param  effectiveDates           (optional) Ordered list of effective dates of the granted points, e.g. "2013-09-02"
   */ 
   void awardChallenges(List<String> challengeNames,
                        List<Id>     awardeeUserOrContactIds,
                        List<String> notes,
                        List<String> effectiveDates); 
   void awardChallenges(List<String> challengeNames,
                        List<Id>     awardeeUserOrContactIds,
                        List<String> notes); 
                        
  /**
   * Award a list of challenges to users, with tags
   *
   * @param  challengeNames           Ordered list of Challenge Names, e.g. "C-0038"
   * @param  awardeeUserorContactIds  Ordered list of users or contacts who are being awarded the challenges, e.g. "00550000000vgY4"
   * @param  tags                     Ordered list of arbitrary strings characterizing the awards, e.g. "DEV-501" for a certification
   * @param  notes                    Ordered list of audit notes on how or why the challenges are being awarded
   * @param  effectiveDates           (optional) Ordered list of effective dates of the granted points, e.g. "2013-09-02"
   */ 
   void awardChallengesWithTags(List<String> challengeNames,
                                List<Id>     awardeeUserOrContactIds,
                                List<String> tags,
                                List<String> notes,
                                List<String> effectiveDates); 
   void awardChallengesWithTags(List<String> challengeNames,
                                List<Id>     awardeeUserOrContactIds,
                                List<String> tags,
                                List<String> notes); 

  /**
   * Award a list of challenges to users, with target names & links
   *
   * @param  challengeNames           Ordered list of Challenge Names, e.g. "C-0038"
   * @param  awardeeUserorContactIds  Ordered list of users or contacts who are being awarded the challenges, e.g. "00550000000vgY4"
   * @param  targetName              Name of record representing why/how challenge was awarded, e.g. "SOQL Query Tool Asset"
   * @param  targetLink              URL of targetName, e.g. "https://appirio.my.salesforce.com/01p50000000RySY"
   * @param  notes                    Ordered list of audit notes on how or why the challenges are being awarded
   * @param  effectiveDates           (optional) Ordered list of effective dates of the granted points, e.g. "2013-09-02"
   */ 
   void awardChallengesWithTargets(List<String> challengeNames,
                                   List<Id>     awardeeUserOrContactIds,
                                   List<String> targetNames,
                                   List<String> targetLinks,
                                   List<String> notes,
                                   List<String> effectiveDates); 
   void awardChallengesWithTargets(List<String> challengeNames,
                                   List<Id>     awardeeUserOrContactIds,
                                   List<String> targetNames,
                                   List<String> targetLinks,
                                   List<String> notes); 
   
}