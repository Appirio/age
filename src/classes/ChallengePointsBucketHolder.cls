public with sharing class ChallengePointsBucketHolder {

  public Challenge__c challenge;
  private List<Challenge_Points_Bucket__c> cpb = new List<Challenge_Points_Bucket__c>();
  

  public ChallengePointsBucketHolder (Challenge__c ch) {
    challenge = ch;
  }
  
  public void addChallengePointsBucket(Challenge_Points_Bucket__c challengePB) {
    cpb.add(challengePB);
  }

  public Boolean deactivateChallenge() {
    
    for (Challenge_Points_Bucket__c c : cpb) {
      System.debug('FROM CPBH C: ' + c);
      System.debug('FROM CPBH CHALLENGE: ' + challenge);      
    
      if (c.Points_Bucket__r.Current_Balance__c >= challenge.Reward_Points__c) {
        return false;
      }
    }
    return true;
  }


}