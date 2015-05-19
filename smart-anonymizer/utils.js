var _debug = false;

/*
	Debugs a message (used to develop)
*/
exports.debug = function(msg){
	if(_debug) {
		if( typeof msg === 'string') console.log('DEBUG ['+(new Date()).toJSON()+']$ '+msg);
	}
};

/*
	Parses a mapping file
	@json - the mapping file

	@return void
*/
exports.validateMappingSync = function(json){
	if(!json) throw 'No json provided';

	if(!Array.isArray(json)) throw 'Mapping json should be an array. See docs for more details.';
	
	if(!json.length) throw 'Mapping json have not replacement rule. See docs for more details.';

	for(var i = 0; i < json.length; i++){
		var rule = json[i];
		if(!Array.isArray(rule)) throw 'Rule #'+i+' of mapping file should be an array. See docs for more details.';
		if(rule.length <3) throw 'Rule #'+i+' of mapping file must have 3 elements. See docs for more details.';
	}
};

/*
	Replaces based on mapping ad returns the replaced body
	@mapping - json mapping
	@relativeFilePath - relative filepath
	@filename - filename
	@sourceBody - source file text
	@isReverse - reverse mapping
	@isCaseInsensitive - case insensitive

	@return replaced source text
*/
exports.replaceOnMappingSync = function(mappingJson, relativeFilePath, filename, sourceBody, isReverse, isCaseInsensitive){

	for(var i = 0; i < mappingJson.length; i++){

		var rule = mappingJson[i];
		sourceBody = applyRule(sourceBody, rule, relativeFilePath, filename, isReverse, isCaseInsensitive);

	}

	return sourceBody;
	
}

/*
	Applies a rule
	@filebody - file body text
	@rule - json array ([wildcard, from, to])
	@relativeFilePath - relative filepath
	@isReverse - reverse mapping
	@isCaseInsensitive - case insensitive

	@return replaced file text
*/
function applyRule(fileBody, rule, relativeFilePath, filename, isReverse, isCaseInsensitive){
	var pathArray = relativeFilePath.split('/');
	var rulePathArray = rule[0].split('/');

	var i = 0,
		j = -1;
	for(i; i < rulePathArray.length; i++){
		var r = rulePathArray[i];
		//this is a void "split" char, avoided
		if(!r && i < rulePathArray.length-1) continue;
		//the "*" wildcard makes all ok!
		if(r === '*') break;

		var found = false;
		for(j; j < pathArray.length; j++){
			var p = pathArray[j];
			if(!p && j < pathArray.length-1) continue;
	
			//no rule to apply
			if(p !== r) return fileBody;
			
			found = true;
			j+=1;
			break;
		}
		if(!found) return fileBody;

	}
	var from = (isReverse)?rule[2]:rule[1];
	var to = (isReverse)?rule[1]:rule[2];
	var replaceOpts = (isCaseInsensitive)?'gi':'g';
	var reg = new RegExp(from, replaceOpts);
	return fileBody.replace(reg, to);
}

exports.applyRule = applyRule;