

--
-- create database
--

-- drop database if exists waveright;
-- create database waveright;

--
-- create database user
--

-- grant all on waveright.* to waverightuser@localhost identified by 'An5u7y$T!p@$$w0rd';

--
-- use database
--

-- use waveright;

--
-- enable backwards compat for 0000-00-00 default value
--

SET sql_mode = '';

--
-- Table structure for table `sessions`
--

CREATE TABLE `sessions` (
  id           CHAR(72) PRIMARY KEY,
  session_data TEXT,
  expires      INTEGER
) ENGINE=InnoDB  DEFAULT CHARSET=utf8mb4 ;

--
-- Table structure for table `log`
--

CREATE TABLE `log` (
  `id`      bigint unsigned NOT NULL auto_increment,
  `time`    datetime NOT NULL,
  `level`   varchar(15) NOT NULL,
  `class`   varchar(127) NOT NULL,
  `file`    varchar(255) NOT NULL,
  `line`    varchar(7) NOT NULL,
  sessionid CHAR(72) NOT NULL,
  guid      varchar(127) NOT NULL, -- request id
  message   TEXT,
  PRIMARY KEY (`id`),
  FULLTEXT(message)
)
  ENGINE=MyISAM DEFAULT
  CHARSET=utf8mb4
;

--
-- Table structure for table `locations`
--

CREATE TABLE IF NOT EXISTS `locations` (
  `id`          int unsigned NOT NULL auto_increment,
  `create_date` timestamp NOT NULL default '0000-00-00 00:00:00',
  `update_date` timestamp NULL ON UPDATE CURRENT_TIMESTAMP,
  `name`        varchar(15) default NULL,
  `pobox`       varchar(15) default NULL,
  `address`     varchar(63) default NULL,
  `street`      varchar(127) default NULL,
  `city`        varchar(63) default NULL,
  `state`       varchar(31) default NULL,
  `zip`         varchar(15) default NULL,
  `country`     char(2) default NULL,
  `longitude`   float default NULL,
  `latitude`    float default NULL,
  PRIMARY KEY (`id`)
)
  ENGINE=InnoDB DEFAULT
  CHARSET=utf8mb4
  AUTO_INCREMENT = 10000
;

--
-- Table structure for table `phones`
--

CREATE TABLE IF NOT EXISTS `phones` (
  `id`           int unsigned NOT NULL auto_increment,
  `create_date`  timestamp NOT NULL default '0000-00-00 00:00:00',
  `update_date`  timestamp NULL ON UPDATE CURRENT_TIMESTAMP,
  `name`         varchar(15) default NULL,
  `country_code` varchar(3) NOT NULL default 1,
  `area_code`    varchar(15) NOT NULL,
  `number`       varchar(15) NOT NULL,
  `extension`    varchar(7) DEFAULT NULL,
  PRIMARY KEY (`id`)
)
  ENGINE=InnoDB DEFAULT
  CHARSET=utf8mb4
  AUTO_INCREMENT = 10000
;

--
-- Table structure for table `groups`
--

DROP TABLE IF EXISTS `groups`;
CREATE TABLE `groups` (
  `id`          int unsigned NOT NULL auto_increment,
  `create_date` timestamp NOT NULL default '0000-00-00 00:00:00',
  `update_date` timestamp NULL ON UPDATE CURRENT_TIMESTAMP,
  `group`       int unsigned default NULL,
  `location`    int unsigned default NULL,
  `phone`       int unsigned default NULL,
  `name`        varchar(255) default NULL,
  `order`       tinyint unsigned default NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `groups_group`    FOREIGN KEY (`group`)    REFERENCES `groups`    (`id`),
  CONSTRAINT `groups_location` FOREIGN KEY (`location`) REFERENCES `locations` (`id`),
  CONSTRAINT `groups_phone`    FOREIGN KEY (`phone`)    REFERENCES `phones`    (`id`)
)
  ENGINE=InnoDB DEFAULT
  CHARSET=utf8mb4
  AUTO_INCREMENT = 50000
;

INSERT INTO `groups` (id, create_date, `group`, name) VALUES (1,NULL,NULL,'WAVERIGHT');

INSERT INTO `groups` (id, create_date, `group`, name) VALUES (10,NULL,1, 'ACL');
INSERT INTO `groups` (id, create_date, `group`, name) VALUES (11,NULL,10,'Administrators');
INSERT INTO `groups` (id, create_date, `group`, name) VALUES (12,NULL,10,'Managers');
INSERT INTO `groups` (id, create_date, `group`, name) VALUES (13,NULL,10,'Customers');

--
-- Table structure for table `persons`
--

DROP TABLE IF EXISTS `persons`;
CREATE TABLE `persons` (
  `id`             int unsigned NOT NULL auto_increment,
  `create_date`    timestamp NOT NULL default '0000-00-00 00:00:00',
  `update_date`    timestamp NULL ON UPDATE CURRENT_TIMESTAMP,
  `location`       int unsigned default NULL,
  `phone`          int unsigned default NULL,
  `name`           varchar(255) default NULL,
  `email`          varchar(63) default NULL,
  `ticket`         varchar(7) default NULL,
  `logins`         mediumint unsigned NOT NULL default 0,
  `pass_salt`      varchar(7) default NULL,
  `pass`           varchar(63) default NULL,
  `pass_hint`      varchar(255) default NULL,
  `verified`       tinyint NOT NULL default 0,
  PRIMARY KEY (`id`),
  CONSTRAINT `persons_location` FOREIGN KEY (`location`) REFERENCES `locations` (`id`),
  CONSTRAINT `persons_phone` FOREIGN KEY (`phone`) REFERENCES `phones` (`id`),
  UNIQUE (`email`)
)
  ENGINE=InnoDB DEFAULT
  CHARSET=utf8mb4
  AUTO_INCREMENT = 10000
;

INSERT INTO persons (id, create_date, name, email, pass_salt, pass) VALUES (10,  NULL, 'Todd Wade',       'waveright@gmail.com',                      '...', '...');
INSERT INTO persons (id, create_date, name, email, pass_salt, pass) VALUES (900,  NULL, 'WaveRight User', 'waveright+waveright.systemuser@gmail.com', '...', '...');
INSERT INTO persons (id, create_date, name, email, pass_salt, pass) VALUES (901,  NULL, 'Random User',    'waveright+randomuser@gmail.com',           '...', '...');

--
-- Table structure for table `members`
--

DROP TABLE IF EXISTS `members`;
CREATE TABLE `members` (
  `id`          int unsigned NOT NULL auto_increment,
  `create_date` timestamp NOT NULL default '0000-00-00 00:00:00',
  `update_date` timestamp NULL ON UPDATE CURRENT_TIMESTAMP,
  `person`      int unsigned NOT NULL,
  `group`       int unsigned NOT NULL,
  PRIMARY KEY (`id`),
  KEY `member` (`person`, `group`),
  CONSTRAINT `members_person` FOREIGN KEY (`person`) REFERENCES `persons` (`id`),
  CONSTRAINT `members_group`  FOREIGN KEY (`group`)  REFERENCES `groups`  (`id`)
)
  ENGINE=InnoDB DEFAULT
  CHARSET=utf8mb4
  AUTO_INCREMENT = 10000
;

INSERT INTO members (create_date, person, `group`) VALUES (NULL, 10,  11);
INSERT INTO members (create_date, person, `group`) VALUES (NULL, 900, 12);
INSERT INTO members (create_date, person, `group`) VALUES (NULL, 901, 13);

--
-- Table structure for table `persons_phones`
--

DROP TABLE IF EXISTS `persons_phones`;
CREATE TABLE `persons_phones` (
  `id`          int unsigned NOT NULL auto_increment,
  `create_date` timestamp NOT NULL default '0000-00-00 00:00:00',
  `update_date` timestamp NULL ON UPDATE CURRENT_TIMESTAMP,
  `person`      int unsigned NOT NULL,
  `phone`       int unsigned NOT NULL,
  PRIMARY KEY (`id`),
  KEY `person_group` (`person`, `phone`),
  CONSTRAINT `persons_phones_person` FOREIGN KEY (`person`) REFERENCES `persons` (`id`),
  CONSTRAINT `persons_phones_phone`  FOREIGN KEY (`phone`)  REFERENCES `phones`  (`id`)
)
  ENGINE=InnoDB DEFAULT
  CHARSET=utf8mb4
  AUTO_INCREMENT = 10000
;

--
-- Table structure for table `persons_locations`
--

DROP TABLE IF EXISTS `persons_locations`;
CREATE TABLE `persons_locations` (
  `id`          int unsigned NOT NULL auto_increment,
  `create_date` timestamp NOT NULL default '0000-00-00 00:00:00',
  `update_date` timestamp NULL ON UPDATE CURRENT_TIMESTAMP,
  `person`      int unsigned NOT NULL,
  `location`    int unsigned NOT NULL,
  PRIMARY KEY (`id`),
  KEY `person_group` (`person`, `location`),
  CONSTRAINT `persons_locations_person`   FOREIGN KEY (`person`)   REFERENCES `persons`   (`id`),
  CONSTRAINT `persons_locations_location` FOREIGN KEY (`location`) REFERENCES `locations` (`id`)
)
  ENGINE=InnoDB DEFAULT
  CHARSET=utf8mb4
  AUTO_INCREMENT = 10000
;

--
-- Table structure for table `groups_phones`
--

DROP TABLE IF EXISTS `groups_phones`;
CREATE TABLE `groups_phones` (
  `id`          int unsigned NOT NULL auto_increment,
  `create_date` timestamp NOT NULL default '0000-00-00 00:00:00',
  `update_date` timestamp NULL ON UPDATE CURRENT_TIMESTAMP,
  `group`       int unsigned NOT NULL,
  `phone`       int unsigned NOT NULL,
  PRIMARY KEY (`id`),
  KEY `group_group` (`group`, `phone`),
  CONSTRAINT `groups_phones_group` FOREIGN KEY (`group`) REFERENCES `groups` (`id`),
  CONSTRAINT `groups_phones_phone` FOREIGN KEY (`phone`) REFERENCES `phones` (`id`)
)
  ENGINE=InnoDB DEFAULT
  CHARSET=utf8mb4
  AUTO_INCREMENT = 10000
;

--
-- Table structure for table `groups_locations`
--

DROP TABLE IF EXISTS `groups_locations`;
CREATE TABLE `groups_locations` (
  `id`          int unsigned NOT NULL auto_increment,
  `create_date` timestamp NOT NULL default '0000-00-00 00:00:00',
  `update_date` timestamp NULL ON UPDATE CURRENT_TIMESTAMP,
  `group`       int unsigned NOT NULL,
  `location`    int unsigned NOT NULL,
  PRIMARY KEY (`id`),
  KEY `group_group` (`group`, `location`),
  CONSTRAINT `groups_locations_group`    FOREIGN KEY (`group`)    REFERENCES `groups`    (`id`),
  CONSTRAINT `groups_locations_location` FOREIGN KEY (`location`) REFERENCES `locations` (`id`)
)
  ENGINE=InnoDB DEFAULT
  CHARSET=utf8mb4
  AUTO_INCREMENT = 10000
;

DROP TABLE IF EXISTS `verification_guids`;
CREATE TABLE `verification_guids` (
  `id`          int unsigned NOT NULL auto_increment,
  `create_date` timestamp NOT NULL default '0000-00-00 00:00:00',
  `update_date` timestamp NULL ON UPDATE CURRENT_TIMESTAMP,
  `person`      int unsigned NOT NULL,
  `type`        varchar(20) NOT NULL,
  `count`       tinyint unsigned NOT NULL default 0,
  `guid`        varchar(36) NOT NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `verification_guids_person` FOREIGN KEY (`person`) REFERENCES `persons` (`id`) ON DELETE CASCADE 
)
  ENGINE=InnoDB DEFAULT
  CHARSET=utf8mb4
;
