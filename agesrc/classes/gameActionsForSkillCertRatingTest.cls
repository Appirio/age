//
// (c) Appirio 2013
//
// This is test class for gameActionsForSkillCertificationRating Trigger
//  
// 10/05/2013     Guna Sevugapperumal    Original
// 10/10/2013     Glenn Weinstein        Removed hard-coded Parent Practice ID
//
@isTest
private class gameActionsForSkillCertRatingTest {
    
    static  Map<String, String> GetContactSeedData() {
      // Create Test Practice record
      List<pse__Practice__c> practices = new List<pse__Practice__c>{};
      practices.add(new pse__Practice__c(name = 'Game Test SFDC Consuntants')); 
      insert practices;
      Map<String, String> seedData = new Map<String, String>{};
      system.debug('Practice Id : ' + practices[0].name); 
      seedData.put('Practice', practices[0].Id);
      
      // Create Test Group Record
      List<pse__Grp__c> grps = new List<pse__Grp__c>{};
      grps.add(new pse__Grp__c(name = 'Test Group'));
      insert grps;
      system.debug('Group Id  : ' + grps[0].name); 
      seedData.put('Group', grps[0].Id);
      
      // Create Test Region Record
       
      List<pse__Region__c> regions = new List<pse__Region__c>{};
      regions.add(new pse__Region__c(name = 'Test Region'));
      insert regions;
      system.debug('Region Id  : ' + regions[0].name); 
      seedData.put('Region', regions[0].Id);
      
      
      return seedData;
    }

    static testMethod void gameActionsForSkillCertRatingTest() {
       // 1. Prepare the test data
      User u = AGETestUtility.createTestUser();

      // Create test Accounts
      List<Account> accounts = new List<Account>{};       
      for(Integer i = 0; i <= 1; i++){
        Account a = new Account(Name = 'Game Test Account ' + i);
        accounts.add(a);
        
      }
      insert accounts;

      // Get the Contact & skill Record Type id
      Id conRecordTypeId = [SELECT id FROM recordtype WHERE name = 'Resource'].Id;
       
      Id skillRecordTypeId = [SELECT id FROM recordtype WHERE name = 'Certification'].Id;
      
      
      // Create Test Practice, Group and Regions
      Map<String, String> seedData = GetContactSeedData();
      
      // Create Test Contact
      List<Contact> contacts = new List<Contact>{}; 
      integer i = 1;      
      for(Account acct : accounts){
         Contact cont = new contact(Firstname = 'GameFirst '+i , 
                                    lastname='GameLast '+i , 
                                    Accountid = acct.id,
                                    pse__Is_Resource_Active__c = true,
                                    pse__Is_Resource__c = true,
                                    RecordTypeId = conRecordTypeId,
                                    pse__Practice__c = seedData.get('Practice'),
                                    pse__Group__c = seedData.get('Group'),
                                    pse__Region__c = seedData.get('Region'));
        contacts.add(cont);
        system.debug('Test Account Info' + '    ' + acct.name + '    '+ acct.id);
        i++;
      }
      insert contacts;

      for (contact contact : contacts){
        system.debug('Test Contact Info' + '    ' + contact.FirstName + '    '+ contact.LastName);
      }
      
      // Create Test Skill record
      List<pse__Skill__c> skills = new List<pse__Skill__c>{};
      skills.add(new pse__skill__c(name = 'Test Salesforce Skill',
                                   pse__unique_name__c = 'Test Salesforce Skill',
                                   pse__Type__c = 'Salesforce.com',
                                   pse__skill_or_certification__C = 'Certification',
                                   RecordTypeId = skillRecordTypeId));
                                   
      skills.add(new pse__skill__c(name = 'Test Salesforce Advanced Skill',
                                   pse__unique_name__c = 'Test Salesforce Advanced Skill',
                                   pse__Type__c = 'Salesforce.com',
                                   pse__skill_or_certification__C = 'Non Certification',
                                   RecordTypeId = skillRecordTypeId));
      insert skills;
      for (pse__Skill__c skill : skills){
        system.debug('Test Skill Info' + '    ' + skill.Name);
      }
      // Create Test Skill Certification Records 
       // 2. Run the test
       system.runAs(u) {
         
         // Run Positive Test
         Test.startTest();
         // Create Skill Certification Rating record
         List<pse__skill_certification_rating__c> skillCertRatings = new 
                                    List<pse__skill_certification_rating__c>{};
         for(contact cont : contacts){
             skillCertRatings.add(new pse__skill_certification_rating__c(
                           pse__skill_certification__c = skills[0].id,
                           pse__Expiration_Date__c = date.today().addDays(5),
                           pse__Evaluation_Date__c = date.today(),
                           pse__rating__c = '5 - Expert',
                           pse__Resource__c = cont.id));
         }
         insert skillCertRatings;
        
         
         // Negative Test 1
         for(contact cont : contacts){
           skillCertRatings.add(new pse__skill_certification_rating__c(
                         pse__skill_certification__c = skills[0].id,
                         pse__Expiration_Date__c = date.today(),
                         pse__Evaluation_Date__c = date.today(),
                         pse__rating__c = '5 - Expert',
                         pse__Resource__c = cont.id));
         } 
         
         // Negative Test 2
         for(contact cont : contacts){
           skillCertRatings.add(new pse__skill_certification_rating__c(
                         pse__skill_certification__c = skills[1].id,
                         pse__Expiration_Date__c = date.today().addDays(5),
                         pse__Evaluation_Date__c = date.today(),
                         pse__rating__c = '5 - Expert',
                         pse__Resource__c = cont.id));
         }
          Test.stopTest(); 
         
       }
       
    }
}