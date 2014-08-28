rpmbuilderutil
==============

A tool to create RPM repositories on the fly. 


Requires
-----------

+ rpmbuild
+ perl


Installation
-----------

Under redhat, suse etc (yumland)

	rpm -i rpmbuilderutil-1.0.0-1.x86_64.rpm

Under debian

	alien -i rpmbuilderutil-1.0.0-1.x86_64.rpm

Usage
-----

	rpmbuilderutil --verbose --config build.json --rpmout /rpm/output/path/ --basepath /path/to/your/file/base/ --target development --help


| **argument** | **function** | **default**
|-----------|--------|----
| | | 
|**help** | shows a help dialog | 
|**config** | define the configuration file | build.json
|**rpmout** | output directory for generated rpm | current working dir
|**basepath** | base directory of your project |  current working dir
|**target** | placeholder for special purpose | ""

Configuration file
-------------------

The configuration file contains either a json object or a json array of objects.
So you can create different rpm for different server targets at once for example.

```json
[
	{
		"rpm"         : "myprogram-{VERSION}-{RELEASE}.{ARCH}",
		"name"        : "myprogram",
		"version"     : "1.0.0",	
		"target"      : "development",
		"description" : "myprogram does a lot of stuff"
	},
	{
		"rpm"         : "myprogram-{VERSION}-{RELEASE}.{ARCH}",
		"name"        : "myprogram",
		"version"     : "1.0.0",	
		"target"      : "production",
		"description" : "myprogram does a lot of stuff"
	}
]
```

## Object elements

All elements on the first level will be available for substitutions.

```json
{
	"element1" : "{ELEMENT2}.bar",
	"element2" : "foo"
}
```

will be resolved to 


```json
{
	"element1" : "foo.bar",
	"element2" : "foo"
}
```

### Files

The element files is an array of file objects.
Those object requires a type, source, destination and mode.

* **type** available types are file or directory
* **source** source file path relative to your basepath
* **destination** destination file path absolute to the new system (prefix /)
* **mode** mode of the file or directory

```json
{
	"rpm"         : "myprogram-{VERSION}-{RELEASE}.{ARCH}",
	"name"        : "myprogram",
	"version"     : "1.0.0",	
	"target"      : "development",
	"description" : "myprogram does a lot of stuff",
	"files"       : [
		{
			"type"        : "file",
			"source"      : "/path/to/file",
			"destination" : "/usr/local/share/myprogram/file",
			"mode"        : "0644"
		}
	]
}
```

You can install a file that depends on an object element. Use **target** for this purpose. You can pass it as external argument too.

```json
{
	"target"      : "development",
	"files"       : [
		{
			"type"        : "file",
			"source"      : "myprogram/configuration/myprogram.{TARGET}.conf",
			"destination" : "/etc/myprogram.conf",
			"mode"        : "0644"
		}
	]
}
```

This will install */basepath/myproject/configuration/myprogram.development.conf* to */etc/myprogram.conf* with owner(rw), group(r), other(r) rights.
You can also do runtime text substitutions on the files. This will edit the destination file and not the source file.

```json
{
	"files"       : [
		{
			"type"         : "file",
			"source"       : "myprogram/script/initd.sh",
			"destination"  : "/etc/init.d/myprogram",
			"mode"         : "0755",
			"substitution" : {
				"MYBINPATH" : "/usr/local/bin/myprogram",
				"MYCONFIG"  : "/etc/myprogram.conf",
				"MYLOGFILE" : "/var/log/myprogram.log"
			}
		}
	]
}
```

This will edit basepath/myprogram/script/initd.sh and install the result


#### Directories

```json
{
	"target"      : "development",
	"files"       : [
		{
			"type"           : "directory",
			"source"         : "myproject/data/{TARGET}",
			"destination"    : "/usr/share/myproject/data",
			"mode"           : "0644"
		}
	]
}
```

Installs all files from */basepath/myproject/data/development/* to */usr/share/myproject/data/* with owner(rw), group(r), other(r)

Use **include** to filter a subset of the files.

```json
{
	"target"      : "development",
	"files"       : [
		{
			"type"           : "directory",
			"source"         : "myproject/data/{TARGET}",
			"destination"    : "/usr/share/myproject/data",
			"mode"           : "0644",
			"include"        : [
				".xml",
				".foo",
				"/images/"
			]
		}
	]
}
```

If the include string matches the filepath then the file pass the include filter

### Events

There are 4 events that could be handled

* **preinstall** Before the installation starts
* **postinstall** After the installation is done
* **preuninstall** Before the uninstall
* **postuninstall** After the uninstall

You can either put shell commands to the handler or you use build in macros

```json
{
	"preinstall": [
		"echo 'preinstall'"
	],
	"postinstall" : [
		"echo 'postinstall'",
		"macro::touchfile('/var/log/myprogram.log', 'myuser', 'mygroup', '0664')"
	],
	"preuninstall" : [
		"echo 'preuninstall'"
	],
	"postuninstall" : [
		"echo 'postuninstall'"
	]
}
```
#### Build-in macros

* **macro::checkfile(path)** If *path* is not a regular file exit with 10
* **macro::checkfolder(path)** If *path* is not a folder exit with 11
* **macro::execute(cmd)** Execute a shell command. If command failed exit with 12
* **macro::execute(delete)**
* **macro::touchfile(path[,owner][,group][,mode])** Creates a file with user, group and file permissions

### Require

The element require is a map of requirements. 

**application**:**version**

Version can have different six comparators.

1. **>** application version must be greater than **version**
2. **>=** application version must be greater than or equal to **version**
3. **=** application version must be equal to **version**
4. **<=** application version must be less than **version**
5. **<** application version must be less than **version**
6. ***** don't care about the application version

```json
{
	"require"     : {	
		"php"    : ">=5.3.3",
		"apache" : "*",
		"perl"   : "*"
	}
}
```


Examples
--------

## Deploy this program

This program is a simple perl script that wraps around rpmbuild. It requires rpmbuild and perl. Final exe should be stored under */usr/local/bin/rpmbuilderutil*
So we have *rpmbuilderutil/rpmbuilderutil.pl* and we want to deploy this as executable program on other machines.
The *build.json* for this task looks very simple:

```json
{
	"rpm"         : "rpmbuilderutil-{VERSION}-{RELEASE}.{ARCH}",
	"name"        : "rpmbuilderutil",
	"version"     : "1.0.0",	
	"description" : "Utility tool to create rpm packages on the fly",
	"require"     : {	
		"rpmbuild": "*",
		"perl"    : "*"
	},
	"files"       : [
		{
			"type"        : "file",
			"source"      : "rpmbuilderutil.pl",
			"destination" : "/usr/local/bin/rpmbuilderutil",
			"mode"        : "0755"
		}
	]
}
```
The rpm key defines the rpm output. rpmbuilderutil-{VERSION}-{RELEASE}.{ARCH} will be transformed into something like
*rpmbuilderutil-1.0.0-1.x86_64(.rpm)*


