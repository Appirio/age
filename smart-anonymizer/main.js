//'use strict';
exports.execute = function(argv){
	var pjson = require('./package.json');

	var VERSION = pjson.version;

	var fs = require('fs');
	var walk = require('walk');
	var U = require('./utils');
	var mkdirp = require('mkdirp');//recursive creation of folders


	var help =  'usage: smart-anonymizer [sourceDir] [destinationDir] [mappingFilePath] (options)\n'
				+ '\tOptions:\n'
				+ '\t\t -r : reverse mapping (default off)\n'
				+ '\t\t -i : case insensitive (default off)\n'
				+ '\n\n'
				+ '-h, [--help] # Show this help message and quit \n\n'
				+ '-v, [--version] # Show current version \n';


	var tasks = {};
	tasks.help = function(){  
		console.log(help);
	};
	tasks.version = function(){
		console.log('Smart Anonymizer v.'+VERSION);
	}


	if(argv[0] == '--help' || argv[0] == '-h') {  
		return tasks.help(); 
	}


	if(argv[0] == '--version' || argv[0] == '-v') {  

		return tasks.version(); 
	}

	//invalid arguments
	if(argv.length < 3){
		console.error('Invalid arguments.');
		return tasks.help();
	}

	//source directory
	var source = argv[0];
	//destination directory
	var destination = argv[1];
	//mapping file
	var mappingFile = argv[2];
	//is reverse mapping?
	var isReverse = false;
	//case insensitive
	var isCaseInsensitive = false;

	//scans options
	for(var i = 3; i < argv.length; i++){
		if(argv[i] === '-r') isReverse = true;
		else if(argv[i] === '-i') isCaseInsensitive = true;
	}

	U.debug('Is reverse: '+isReverse);
	U.debug('Is case insensitive: '+isCaseInsensitive);

	if(!fs.existsSync(source)){
		return console.error('Source directory "'+source+'" not found.');
	}
	if(!fs.lstatSync(source).isDirectory()){
		return console.error('Source directory "'+source+'" is not a valid directory.');
	}
	if(!fs.existsSync(destination)){
		return console.error('Source directory "'+destination+'" not found.');
	}
	if(!fs.lstatSync(destination).isDirectory()){
		return console.error('Source directory "'+destination+'" is not a valid directory.');
	}
	if(!fs.existsSync(mappingFile)){
		return console.error('Mapping file "'+mappingFile+'" not found.');
	}
	if(!fs.lstatSync(mappingFile).isFile()){
		return console.error('Mapping file "'+mappingFile+'" is not a valid file.');
	}

	//read the mapping file
	U.debug('Files and folders are ok.');

	var mappingFileData = fs.readFileSync(mappingFile);
	var mappingJSON = null;
	try{
		mappingJSON = mappingFileData.toString('utf-8');
		mappingJSON = JSON.parse(mappingJSON);

	}catch(e){
		mappingJSON = null;
		return console.error('Mapping file "'+mappingFile+'" has not a valid JSON format.');
	}

	U.debug('Mapping JSON:');
	U.debug(mappingJSON);

	U.debug('Validating Mapping JSON...');
	try{
		U.validateMappingSync(mappingJSON);
	}catch(e){
		return console.error('Mapping file "'+mappingFile+'" not in a valid format: '+e);
	}
	U.debug('Validation OK.');

	U.debug('Walking on folders...');
	var options = {
	    listeners: {
	      names: function (root, nodeNamesArray) {
	        nodeNamesArray.sort(function (a, b) {
	          if (a > b) return 1;
	          if (a < b) return -1;
	          return 0;
	        });
	      }
	    , directories: function (root, dirStatsArray, next) {
	        next();
	      }
	    , file: function (root, fileStats, next) {
	    	try{
		    	var filePath = root+'/'+fileStats.name;
		    	var reg = new RegExp('^'+source);
		    	//calculates the "relative" file path
		    	var relativeFilePath = root.replace(reg, '');

		    	console.log('\tReading source file '+filePath);

		    	//gets the file body
		    	var sourceBody = fs.readFileSync(filePath);
		    	sourceBody = sourceBody.toString('utf8');

		    	//applies rules
		        var replacedBody = U.replaceOnMappingSync(mappingJSON, relativeFilePath, fileStats.name, sourceBody, isReverse, isCaseInsensitive);

		        //destination files path
			    var destinationFilePath = destination+'/'+relativeFilePath+'/'+fileStats.name;
			    //creates recursively the destination folders
			    mkdirp.sync(destination+'/'+relativeFilePath);

		    	console.log('\tWriting destination file '+destinationFilePath);
		    	//writes file to destination
		    	fs.writeFileSync(destinationFilePath, new Buffer(replacedBody));
		    }catch(e){
		    	console.error(e);
		    }
	    	next();
	        
	      }
	    , errors: function (root, nodeStatsArray, next) {
	        next();
	      }
	    }
	  };

	var walker = walk.walkSync(source, options);
	console.log('Replacing rule application completed. See files in '+destination);
};