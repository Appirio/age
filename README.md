# age
Appirio Gamification Engine, copyright Appirio Inc.

## Building

### Prerequisites

1. Install [ant and the salesforce ant libraries]( https://resources.docs.salesforce.com/sfdc/pdf/salesforce_migration_guide.pdf)

2. Sign up for a [Salesforce Developer Org](https://developer.salesforce.com/signup)

### Deploying

To deploy AGE to your own Salesforce dev org:

1. [Identify a Default Workflow User](https://help.salesforce.com/apex/HTViewHelpDoc?id=workflow_defaultuser.htm&language=en_US) in your dev org

2. Deploy the AGE package via ant:
 ```
 ant deployAge2dev
 ```

3. Copy the contents from ```postdeploy.apex``` into an [Anonymous Apex](https://help.salesforce.com/apex/HTViewHelpDoc?id=code_dev_console_execute_anonymous.htm&language=en) window to create the required Chatter Group and populate related Custom Settings.

AGE should now be available in your dev org!

## Admins

### smart-anonymizer and cleaner.sh

smart-anonymizer is a tool written in Node.js that uses a regular expression mapping file (```mapping.json```) to substitute keywords in source files.  smart-anonymizer is called from the ant ```build.xml``` script to prepare the AGE metadata for crowdsourced development by removing dependencies on other applications.  To remove other files that smart-anonymizer cannot handle, ```sh cleaner.sh``` is called after smart-anonymizer.

If you don't already have Node.js installed on your machine:

```
run npm install
```

from the ```smart-anonymizer``` directory.

Next, make cleaner.sh executable:

```
chmod a+x cleaner.sh
```

See smart-anonymizer/readme or help for more details:

```
smart-anonymizer/bin/smart-anonymizer -h
```

To run the tool manually, the syntax is:

```
smart-anonymizer/bin/smart-anonymizer srcDir destDir mappingFile
```

For example:

```
smart-anonymizer/bin/smart-anonymizer src-original src smart-anonymizer/mapping.json
```

### Retrieving current version of AGE

To retrieve the current version of AGE and remove dependencies for inclusion in github:

```
ant fetchAgeAndClean
```

### One-time retrieval of stub objects

To retrieve the 2 stub objects for inclusion in github:

```
ant fetchAgePredeploy
```
