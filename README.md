This repository contains a script for converting an export of an Arma 3 configuration to a MySQL table. There is also a SQL script that contains the table definitions and stored procedures for reading attributes as they would be read in Arma 3.

For people developing web applications for their groups, this is a way to create applications using the same information they'd see in game. 

The script requires `pymysql`. 

To dump the arma 3 configuration you'll need this extension: https://github.com/pennyworth12345/ConfigDumpFileIO

Tables:

* `classes`: any class
  * `name`: Name of the class (e.g. `SOLDIER_F`)
  * `id`: ID assigned to this class
  * `parent`: If this class is under another class (e.g. `CfgUnit >> Soldier_F`)
  * `pid`: Parent ID (class names are not always unique)
  * `inherit`: If this class takes properties from another class

* `attributes`: properties of classes
  * `classname`: Name of class
  * `classid`: ID of class
  * `attribute`: name of attribute
  * `value`: value of attribute

Procedures:

* `find_all_attributes`: returns all attributes, including ones that have been overwriten.  
* `find_children`: returns all the classes that fall under a given name and id
* `find_classpath`: returns the path to the class back to root
* `find_inherited_attributes`: returns all attributes, not including overwriten values (shows them as they are)
* `find_parents`: returns the parent classes of this class

