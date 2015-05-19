# age
Appirio Gamification Engine, copyright Appirio Inc.

## Using Smart-anonymizer
Smart Anonymizer is a tool written in NodeJS that uses a regular expression mapping file to substitute keywords in source files.
**Usage**
 1. You must have node installed on your machine
 2. goto the smart-anonymizer dir and run npm install
 3. Move back to the root folder and   ``` smart-anonymizer/bin/smart-anonymizer -h``` to see the help, also you can look at the readme for more details.  
 4. A sample mapping file is included in the smart-anonymizier dir
 5. create a destinination directory ```mkdir smart-output``` you will deploy from this directory
 6. Run the tool  ```smart-anonymizer/bin/smart-anonymizer ageKL age-smartoutput smart-anonymizer/mapping.json``` the syntax is ```srcDir destDir mappingFile```
