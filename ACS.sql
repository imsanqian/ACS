-- Active: 1683886358872@@127.0.0.1@3306@acs
DROP TABLE IF EXISTS Readers;
DROP TABLE IF EXISTS RoleGroups;
DROP TABLE IF EXISTS Users;
DROP TABLE IF EXISTS Logs;
CREATE Table Readers(
    readerID INT PRIMARY KEY AUTO_INCREMENT,
    accessGroups JSON,
    accessUsers JSON COMMENT 'Special case'
);
CREATE TABLE RoleGroups(
    groupID INT PRIMARY KEY AUTO_INCREMENT,
    groupName VARCHAR(64)
);

CREATE TABLE Users(
    userID INT PRIMARY KEY AUTO_INCREMENT,
    userName VARCHAR(255) NOT NULL,
    regDate DATETIME,
    groupIDs JSON
);

CREATE Table Logs(
    logID INT PRIMARY KEY AUTO_INCREMENT,
    readerID INT NOT NULL,
    accessGranted BOOLEAN DEFAULT 1,
    logTime DATETIME,
    Foreign Key (readerID) REFERENCES Readers(readerID) 
    ON UPDATE CASCADE
    ON DELETE CASCADE
);
-- ##############################################################
-- The trigger for insert a log, it will automatically set the logtime to current date time
DROP TRIGGER IF EXISTS trig_ins_log;
DELIMITER $$
CREATE TRIGGER trig_ins_log
BEFORE INSERT ON `Logs`
FOR EACH ROW
BEGIN
SET NEW.logTime = (SELECT NOW());
END $$
DELIMITER ;
-- ##############################################################
-- The trigger for insert a user, it will automatically set the regtime to current date time
DROP TRIGGER IF EXISTS trig_ins_user;
DELIMITER $$
CREATE TRIGGER trig_ins_user
BEFORE INSERT ON `Users`
FOR EACH ROW
BEGIN
SET NEW.regDate = (SELECT NOW());
END $$
DELIMITER ;

DROP Procedure IF EXISTS addUser;
DELIMITER $$
CREATE PROCEDURE addUser(IN uName VARCHAR(255), IN gIDs JSON)
BEGIN
INSERT INTO users VALUES(NULL,uName,NULL,gIDs);
END $$
DELIMITER ;

DROP Procedure IF EXISTS addRole;
DELIMITER $$
CREATE PROCEDURE addRole(IN rName VARCHAR(64))
BEGIN
INSERT INTO rolegroups VALUES(NULL,rName);
END $$
DELIMITER ;

DROP Procedure IF EXISTS addReader;
DELIMITER $$
CREATE PROCEDURE addReader(IN gIDs JSON)
BEGIN
INSERT INTO Readers VALUES(NULL,gIDs,NULL);
/* SELECT * FROM readers ORDER BY `readerID` DESC LIMIT 1; */
END $$
DELIMITER ;

DROP Procedure IF EXISTS insertLog;
DELIMITER $$
CREATE PROCEDURE insertLog(IN rID INT,IN granted BOOLEAN)
BEGIN
INSERT INTO logs VALUES(NULL,rID,granted);
END $$
DELIMITER ;

DROP FUNCTION IF EXISTS userAssignedGroups;
DELIMITER $$
CREATE FUNCTION userAssignedGroups(uID INT)
RETURNS JSON
DETERMINISTIC
BEGIN
    DECLARE ret JSON;
    SET ret = (SELECT `groupIDs` FROM users WHERE `userID` = uID);
    RETURN ret;
END $$
DELIMITER ;

DROP FUNCTION IF EXISTS groupHasAccess;
DELIMITER $$
CREATE FUNCTION groupHasAccess(rID INT, gID INT)
RETURNS BOOLEAN
DETERMINISTIC
BEGIN
    DECLARE ret BOOLEAN;
    SET ret = (SELECT (gID MEMBER OF((SELECT `accessGroups` FROM readers WHERE `readerID` = rID))));
    RETURN ret;
END $$
DELIMITER ;
DROP FUNCTION IF EXISTS userHasSpecialAccess;
DELIMITER $$
CREATE FUNCTION userHasSpecialAccess(uID INT, gID INT)
RETURNS BOOLEAN
DETERMINISTIC
BEGIN
    DECLARE ret BOOLEAN;
    SET ret = (SELECT (uID MEMBER OF((SELECT `accessUsers` FROM readers WHERE `readerID` = rID))));
    RETURN ret;
END $$
DELIMITER ;
CALL addReader((SELECT JSON_ARRAY(1,2,3,4)));
