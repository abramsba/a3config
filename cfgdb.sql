/*
Navicat MySQL Data Transfer

Source Server         : newdbarma
Source Server Version : 50717
Source Host           : 192.168.178.16:3306
Source Database       : cfgdb

Target Server Type    : MYSQL
Target Server Version : 50717
File Encoding         : 65001

Date: 2017-05-23 10:34:56
*/

SET FOREIGN_KEY_CHECKS=0;

-- ----------------------------
-- Table structure for attributes
-- ----------------------------
DROP TABLE IF EXISTS `attributes`;
CREATE TABLE `attributes` (
  `classname` varchar(255) NOT NULL,
  `classid` int(11) NOT NULL,
  `attribute` varchar(255) NOT NULL,
  `value` text,
  PRIMARY KEY (`classname`,`attribute`,`classid`),
  KEY `fk_class_attribute` (`classname`,`classid`),
  CONSTRAINT `fk_class_attribute` FOREIGN KEY (`classname`, `classid`) REFERENCES `classes` (`name`, `id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for classes
-- ----------------------------
DROP TABLE IF EXISTS `classes`;
CREATE TABLE `classes` (
  `name` varchar(255) NOT NULL,
  `id` int(11) NOT NULL,
  `parent` varchar(255) DEFAULT NULL,
  `pid` int(11) DEFAULT NULL,
  `inherit` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`name`,`id`),
  KEY `pid_and_parent` (`parent`,`pid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Procedure structure for find_all_attributes
-- ----------------------------
DROP PROCEDURE IF EXISTS `find_all_attributes`;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `find_all_attributes`(IN `in_id` int,IN `in_name` varchar(255))
BEGIN

	call tmp_parents( in_id, in_name );
	
	drop table if exists tmp_res1;
	create temporary table tmp_res1 as select * from temp_parent_table;
	select
			classname,
			classid,
			attribute, 
			value
		from attributes where 
		classname in (select pname from temp_parent_table) and 
    classid in (select pid from tmp_res1)
   order by attribute, classid desc;

END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for find_children
-- ----------------------------
DROP PROCEDURE IF EXISTS `find_children`;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `find_children`(`in_id` int,`in_name` varchar(255))
BEGIN
	#Routine body goes here...

END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for find_classpath
-- ----------------------------
DROP PROCEDURE IF EXISTS `find_classpath`;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `find_classpath`(IN `in_id` int,IN `in_name` varchar(255))
BEGIN
  declare o_parent_name varchar(255);
	declare o_parent_id int;
	declare i_parent_name varchar(255);
	declare i_parent_id int;
	drop table if exists temp_table;
  create temporary table temp_table ( class_id int, class_name varchar(255), child_id int, child_name varchar(255) );
  select parent, pid into @o_parent_name, @o_parent_id from classes where name = in_name and id = in_id;
  if @o_parent_id <> -1 then
		insert into temp_table values ( @o_parent_id, @o_parent_name, -1, "" );
		findf: while ( @o_parent_id > -1 ) do
			select parent, pid into @i_parent_name, @i_parent_id from classes where name = @o_parent_name and id = @o_parent_id;
      if @i_parent_id = -1 then leave findf; end if;
			insert into temp_table values ( @i_parent_id, @i_parent_name, @o_parent_id, @o_parent_name );
			set @o_parent_name = @i_parent_name;
			set @o_parent_id = @i_parent_id;
		end while;
  end if;
  select * from temp_table order by class_id asc;
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for find_inherited_attributes
-- ----------------------------
DROP PROCEDURE IF EXISTS `find_inherited_attributes`;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `find_inherited_attributes`(IN `in_id` int,IN `in_name` varchar(255))
BEGIN
	call tmp_parents( in_id, in_name );
	drop table if exists tmp_res1;
	create temporary table tmp_res1 as select * from temp_parent_table;
		select * from
		(select
			classname,
			classid,
			attribute, 
			value
		from attributes where 
		classname in (select pname from temp_parent_table) and 
    classid in (select pid from tmp_res1)
   order by attribute, classid desc) x group by (attribute);
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for find_parents
-- ----------------------------
DROP PROCEDURE IF EXISTS `find_parents`;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `find_parents`(IN `in_id` int,IN `in_name` varchar(64))
BEGIN	
	declare parent_class varchar(255);
  declare class_level int;
	declare i_cname varchar(255);
  declare i_inh varchar(255);
  declare i_id int;
	drop table if exists temp_parent_table;
  create temporary table temp_parent_table ( pid int, pname varchar(255) );
	select id, inherit into @class_level, @parent_class from classes where name = in_name and id = in_id;
	#insert into temp_parent_table values ( in_id, in_name );
  findp: while ( @parent_class <> '' ) do 
		select max(id), name, inherit into @i_id, @i_cname, @i_inh from classes where name = @parent_class and id < @class_level;
		insert into temp_parent_table values ( @i_id, @i_cname );
    set @parent_class = @i_inh;
    set @class_level = @i_id;
  end while;
  select * from temp_parent_table;
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for tmp_classpath
-- ----------------------------
DROP PROCEDURE IF EXISTS `tmp_classpath`;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `tmp_classpath`(IN `in_id` int,IN `in_name` varchar(255))
BEGIN
  declare o_parent_name varchar(255);
	declare o_parent_id int;
	declare i_parent_name varchar(255);
	declare i_parent_id int;
	drop table if exists temp_table;
  create temporary table temp_table ( pid int, pname varchar(255) );
  select parent, pid into @o_parent_name, @o_parent_id from classes where name = in_name and id = in_id;
	if @o_parent_id = -1 then 
		insert into temp_table values ( in_id, in_name );
  else 
		insert into temp_table values ( @o_parent_id, @o_parent_name );
		findf: while ( @o_parent_id > -1 ) do
			select parent, pid into @i_parent_name, @i_parent_id from classes where name = @o_parent_name and id = @o_parent_id;
			if @i_parent_id = -1 then leave findf; end if;
			insert into temp_table values ( @i_parent_id, @i_parent_name );
			set @o_parent_name = @i_parent_name;
			set @o_parent_id = @i_parent_id;
		end while;
  end if;
  #select * from temp_table;
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for tmp_parents
-- ----------------------------
DROP PROCEDURE IF EXISTS `tmp_parents`;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `tmp_parents`(IN `in_id` int,IN `in_name` varchar(64))
BEGIN	
	declare parent_class varchar(255);
  declare class_level int;
	declare i_cname varchar(255);
  declare i_inh varchar(255);
  declare i_id int;
	drop table if exists temp_parent_table;
  create temporary table temp_parent_table ( pid int, pname varchar(255) );
	select id, inherit into @class_level, @parent_class from classes where name = in_name and id = in_id;
	insert into temp_parent_table values ( in_id, in_name );
  findp: while ( @parent_class <> '' ) do 
		select max(id), name, inherit into @i_id, @i_cname, @i_inh from classes where name = @parent_class and id < @class_level;
		insert into temp_parent_table values ( @i_id, @i_cname );
    set @parent_class = @i_inh;
    set @class_level = @i_id;
  end while;
  #select * from temp_parent_table;
END
;;
DELIMITER ;
