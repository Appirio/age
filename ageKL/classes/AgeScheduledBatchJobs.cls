global class AgeScheduledBatchJobs implements Schedulable { 

// (c) Appirio 2014
//
// A series of batch jobs for automating awarding in AGE
//
// 03/10/2014     Kym Le     Original
// 03/14/2014     Kym Le     Added AwardMillionBiller
// 03/25/2014     Kym Le     Removed AwardMillionBiller - this 
//                           will be a scheduled job and not a batch.
//

  global void execute(SchedulableContext sc) {
    Database.executeBatch(new AwardEmployeeAnniversary());
  }
}