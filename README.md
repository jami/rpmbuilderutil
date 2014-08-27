rpmbuilderutil
==============

A tool to create RPM repositories on the fly. 

Installation
-----------

Under redhat, suse etc (yumland)

	rpm -i rpmbuilderutil-1.0.0-1.x86_64.rpm

Under debian

	alien -i rpmbuilderutil-1.0.0-1.x86_64.rpm

Usage
-----

	rpmbuilderutil --verbose --config build.json --rpmout /rpm/output/path/ --basepath /path/to/your/file/base/ --target development --help


| argument |  | default
|-----------|--------|----
| | | 
|help | shows a help dialog | 
|config | define the configuration file | build.json
|rpmout | output directory for generated rpm | current working dir
|basepath | base directory of your project |  current working dir
|target | placeholder for special purpose | ""
