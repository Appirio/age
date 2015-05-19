Smart Anonymizer 0.1.0
By ForceLogic

Use: 
	./bin/smart-anonymizer "./test-folder/source" "./test-folder/destination" "./test-folder/mapping/mapping.json" -i -r

Where:
	-i : case insensitive (default false)
		- insensitive match
	-r : reverse (default false)
		- swaps the rules definition

Use:
	./bin/smart-anonymizer -h OR --help
		For help
	./bin/smart-anonymizer -v OR --version
		For version number (taken from the package.json)

Mapping JSON structure:

[
	["rule1/path", "from-replace", "to-replace"],
	["rule2/path", "from-replace", "to-replace"],
	...
]

Where the paths could be anything like:
	- /
	- /*
	- *
	- folder1/*
	- folder1/folder2
	- folder1/*
	- . . .

Libs:
	- walk (walking through folders)
	- mkdirp (makes folders recursivly)