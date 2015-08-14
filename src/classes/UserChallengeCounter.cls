public class UserChallengeCounter{

  public Challenge__c challenge { get; set; }
  public Integer count { get; set; }
  public Date lastAwardedDate { get; set; }
  public Boolean maxNumberReached { get; set; }

  public UserChallengeCounter(Challenge__c c){
    maxNumberReached = false;
    challenge = c;
    count = 0;
  }

  public void inspectChallenge(Date challengeDateAwarded){
  
    count++;
    if(lastAwardedDate == null){
      lastAwardedDate = challengeDateAwarded;
    }else if(challengeDateAwarded > lastAwardedDate){
      lastAwardedDate = challengeDateAwarded;
    }
    
    if(count >= challenge.Max_Number_of_Achievements_Per_User__c){
      maxNumberReached = true;
    }
  }
 
}