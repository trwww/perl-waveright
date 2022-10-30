

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
  `time`    datetime        NOT NULL,
  `level`   varchar(15)     NOT NULL,
  `class`   varchar(127)    NOT NULL,
  `file`    varchar(255)    NOT NULL,
  `line`    varchar(7)      NOT NULL,
  sessionid CHAR(72)        NOT NULL,
  guid      varchar(127)    NOT NULL, -- request id
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
  `id`          int unsigned     NOT NULL              auto_increment,
  `create_date` DATETIME     DEFAULT CURRENT_TIMESTAMP,
  `update_date` DATETIME     DEFAULT NULL              ON UPDATE CURRENT_TIMESTAMP,
  `name`        varchar(15)  default NULL,
  `pobox`       varchar(15)  default NULL,
  `address`     varchar(63)  default NULL,
  `street`      varchar(127) default NULL,
  `city`        varchar(63)  default NULL,
  `state`       varchar(31)  default NULL,
  `zip`         varchar(15)  default NULL,
  `country`     char(2)      default NULL,
  `longitude`   float        default NULL,
  `latitude`    float        default NULL,
  PRIMARY KEY (`id`)
)
  ENGINE=InnoDB DEFAULT
  CHARSET=utf8mb4
  AUTO_INCREMENT = 1000
;

--
-- Table structure for table `phones`
--

CREATE TABLE IF NOT EXISTS `phones` (
  `id`           int unsigned    NOT NULL              auto_increment,
  `create_date`  DATETIME    DEFAULT CURRENT_TIMESTAMP,
  `update_date`  DATETIME    DEFAULT NULL              ON UPDATE CURRENT_TIMESTAMP,
  `name`         varchar(15) default NULL,
  `country_code` varchar(3)      NOT NULL              default 1,
  `area_code`    varchar(15)     NOT NULL,
  `number`       varchar(15)     NOT NULL,
  `extension`    varchar(7)  DEFAULT NULL,
  PRIMARY KEY (`id`)
)
  ENGINE=InnoDB DEFAULT
  CHARSET=utf8mb4
  AUTO_INCREMENT = 10
;

--
-- Table structure for table `groups`
--

DROP TABLE IF EXISTS `groups`;
CREATE TABLE `groups` (
  `id`          int unsigned         NOT NULL              auto_increment,
  `create_date` DATETIME         DEFAULT CURRENT_TIMESTAMP,
  `update_date` DATETIME         DEFAULT NULL              ON UPDATE CURRENT_TIMESTAMP,
  `group`       int unsigned         NOT NULL,
  `location`    int unsigned     default NULL,
  `phone`       int unsigned     default NULL,
  `name`        varchar(255)     default NULL,
  `order`       tinyint unsigned default NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `groups_group`    FOREIGN KEY (`group`)    REFERENCES `groups`    (`id`),
  CONSTRAINT `groups_location` FOREIGN KEY (`location`) REFERENCES `locations` (`id`),
  CONSTRAINT `groups_phone`    FOREIGN KEY (`phone`)    REFERENCES `phones`    (`id`)
)
  ENGINE=InnoDB DEFAULT
  CHARSET=utf8mb4
  AUTO_INCREMENT = 5000
;

-- see app sql/init.sql for group init data

--
-- Table structure for table `persons`
--

DROP TABLE IF EXISTS `persons`;
CREATE TABLE `persons` (
  `id`             int unsigned           NOT NULL              auto_increment,
  `create_date`    DATETIME           DEFAULT CURRENT_TIMESTAMP,
  `update_date`    DATETIME           DEFAULT NULL              ON UPDATE CURRENT_TIMESTAMP,
  `location`       int unsigned       default NULL,
  `phone`          int unsigned       default NULL,
  `name`           varchar(255)       default NULL,
  `email`          varchar(63)        default NULL,
  `ticket`         varchar(7)         default NULL,
  `logins`         mediumint unsigned     NOT NULL              default 0,
  `pass_salt`      varchar(7)         default NULL,
  `pass`           varchar(63)        default NULL,
  `pass_hint`      varchar(255)       default NULL,
  `verified`       tinyint                NOT NULL              default 0,
  PRIMARY KEY (`id`),
  CONSTRAINT `persons_location` FOREIGN KEY (`location`) REFERENCES `locations` (`id`),
  CONSTRAINT `persons_phone`    FOREIGN KEY (`phone`)    REFERENCES `phones`    (`id`),
  UNIQUE (`email`)
)
  ENGINE=InnoDB DEFAULT
  CHARSET=utf8mb4
  AUTO_INCREMENT = 1000
;


-- see app sql/init.sql for person init data

--
-- Table structure for table `members`
--

DROP TABLE IF EXISTS `members`;
CREATE TABLE `members` (
  `id`          int unsigned     NOT NULL              auto_increment,
  `create_date` DATETIME     DEFAULT CURRENT_TIMESTAMP,
  `update_date` DATETIME     DEFAULT NULL              ON UPDATE CURRENT_TIMESTAMP,
  `person`      int unsigned     NOT NULL,
  `group`       int unsigned     NOT NULL,
  PRIMARY KEY (`id`),
  KEY `member` (`person`, `group`),
  CONSTRAINT `members_person` FOREIGN KEY (`person`) REFERENCES `persons` (`id`),
  CONSTRAINT `members_group`  FOREIGN KEY (`group`)  REFERENCES `groups`  (`id`)
)
  ENGINE=InnoDB DEFAULT
  CHARSET=utf8mb4
  AUTO_INCREMENT = 10
;

--
-- Table structure for table `persons_phones`
--

DROP TABLE IF EXISTS `persons_phones`;
CREATE TABLE `persons_phones` (
  `id`          int unsigned     NOT NULL              auto_increment,
  `create_date` DATETIME     DEFAULT CURRENT_TIMESTAMP,
  `update_date` DATETIME     DEFAULT NULL              ON UPDATE CURRENT_TIMESTAMP,
  `person`      int unsigned     NOT NULL,
  `phone`       int unsigned     NOT NULL,
  PRIMARY KEY (`id`),
  KEY `person_group` (`person`, `phone`),
  CONSTRAINT `persons_phones_person` FOREIGN KEY (`person`) REFERENCES `persons` (`id`),
  CONSTRAINT `persons_phones_phone`  FOREIGN KEY (`phone`)  REFERENCES `phones`  (`id`)
)
  ENGINE=InnoDB DEFAULT
  CHARSET=utf8mb4
  AUTO_INCREMENT = 10
;

--
-- Table structure for table `persons_locations`
--

DROP TABLE IF EXISTS `persons_locations`;
CREATE TABLE `persons_locations` (
  `id`          int unsigned     NOT NULL              auto_increment,
  `create_date` DATETIME     DEFAULT CURRENT_TIMESTAMP,
  `update_date` DATETIME     DEFAULT NULL              ON UPDATE CURRENT_TIMESTAMP,
  `person`      int unsigned     NOT NULL,
  `location`    int unsigned     NOT NULL,
  PRIMARY KEY (`id`),
  KEY `person_group` (`person`, `location`),
  CONSTRAINT `persons_locations_person`   FOREIGN KEY (`person`)   REFERENCES `persons`   (`id`),
  CONSTRAINT `persons_locations_location` FOREIGN KEY (`location`) REFERENCES `locations` (`id`)
)
  ENGINE=InnoDB DEFAULT
  CHARSET=utf8mb4
  AUTO_INCREMENT = 10
;

--
-- Table structure for table `groups_phones`
--

DROP TABLE IF EXISTS `groups_phones`;
CREATE TABLE `groups_phones` (
  `id`          int unsigned     NOT NULL              auto_increment,
  `create_date` DATETIME     DEFAULT CURRENT_TIMESTAMP,
  `update_date` DATETIME     DEFAULT NULL              ON UPDATE CURRENT_TIMESTAMP,
  `group`       int unsigned     NOT NULL,
  `phone`       int unsigned     NOT NULL,
  PRIMARY KEY (`id`),
  KEY `group_group` (`group`, `phone`),
  CONSTRAINT `groups_phones_group` FOREIGN KEY (`group`) REFERENCES `groups` (`id`),
  CONSTRAINT `groups_phones_phone` FOREIGN KEY (`phone`) REFERENCES `phones` (`id`)
)
  ENGINE=InnoDB DEFAULT
  CHARSET=utf8mb4
  AUTO_INCREMENT = 10
;

--
-- Table structure for table `groups_locations`
--

DROP TABLE IF EXISTS `groups_locations`;
CREATE TABLE `groups_locations` (
  `id`          int unsigned     NOT NULL              auto_increment,
  `create_date` DATETIME     DEFAULT CURRENT_TIMESTAMP,
  `update_date` DATETIME     DEFAULT NULL              ON UPDATE CURRENT_TIMESTAMP,
  `group`       int unsigned     NOT NULL,
  `location`    int unsigned     NOT NULL,
  PRIMARY KEY (`id`),
  KEY `group_group` (`group`, `location`),
  CONSTRAINT `groups_locations_group`    FOREIGN KEY (`group`)    REFERENCES `groups`    (`id`),
  CONSTRAINT `groups_locations_location` FOREIGN KEY (`location`) REFERENCES `locations` (`id`)
)
  ENGINE=InnoDB DEFAULT
  CHARSET=utf8mb4
  AUTO_INCREMENT = 10
;

DROP TABLE IF EXISTS `verification_guids`;
CREATE TABLE `verification_guids` (
  `id`          int unsigned     NOT NULL              auto_increment,
  `create_date` DATETIME     DEFAULT CURRENT_TIMESTAMP,
  `update_date` DATETIME     DEFAULT NULL              ON UPDATE CURRENT_TIMESTAMP,
  `person`      int unsigned     NOT NULL,
  `type`        varchar(20)      NOT NULL,
  `count`       tinyint unsigned NOT NULL              default 0,
  `guid`        varchar(36)      NOT NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `verification_guids_person` FOREIGN KEY (`person`) REFERENCES `persons` (`id`) ON DELETE CASCADE 
)
  ENGINE=InnoDB DEFAULT
  CHARSET=utf8mb4
;
