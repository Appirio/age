trigger beforeInsertAndAfterDeletePoints on Points__c (before insert, after insert, after delete) {

//
// (c) Appirio 2013
//
// When an AGE user completes a Challenge, the points associated to the Challenge is entered into the Points object.
// Some Challenges will have a Points Bucket that holds the current available balance of points; once the balance 
// reaches 0, the Challenges is then inactive.  
//
// This trigger handles the actions within the Points object.  There are two uses cases in which we are handling:
//
// 1. An AGE user is awarded Points and the trigger will need to decrement the reward points to the associated
// Points Bucket balance for the Challenge.
//
// 2. An AGE user's Points has been reomoved and the trigger will add the reward points back to the associated
// Points Bucket balance for the Challenge.
//
// 
// 08/22/2013     Kym Le    Original
// 08/25/2013     Kym Le    Added Delete logic
// 09/10/2013     Kym Le    Moved logic to Trigger Class - PointsTriggerHandler
// 03/01/2014     Kyn Le    Changed insert trigger from after to before


  PointsTriggerHandler handler = new PointsTriggerHandler(Trigger.isExecuting);

  if (Trigger.isInsert && Trigger.isBefore) {
      System.debug('handler before insert called');    
      handler.OnBeforeInsert(Trigger.new);
  } else if (Trigger.isInsert && Trigger.isAfter) {
      System.debug('handler after insert called');
      handler.OnAfterInsert(Trigger.new);
  } else if (Trigger.isDelete && Trigger.isAfter) {

    handler.OnAfterDelete(Trigger.old);
  }
  

}