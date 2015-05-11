trigger afterUpdateIdea on Idea (after update) {


  
  IdeaTriggerHandler ageHandler = new IdeaTriggerHandler(Trigger.isExecuting);

  if(Trigger.isUpdate && Trigger.isAfter){
    ageHandler.OnAfterUpdate(Trigger.newMap);
  }

}