-- Active: 1683886358872@@127.0.0.1@3306@acs
DROP TABLE IF EXISTS Doors;
DROP TABLE IF EXISTS RoleGroups;
DROP TABLE IF EXISTS Users;
DROP TABLE IF EXISTS Logs;
CREATE Table Doors(
    doorID INT PRIMARY KEY AUTO_INCREMENT,
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
    doorID INT NOT NULL,
    userID INT NOT NULL,
    accessGranted BOOLEAN DEFAULT 1,
    logTime DATETIME,
    Foreign Key (doorID) REFERENCES Doors(doorID) 
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

DROP Procedure IF EXISTS addDoor;
DELIMITER $$
CREATE PROCEDURE addDoor(IN gIDs JSON)
BEGIN
INSERT INTO Doors VALUES(NULL,gIDs,NULL);
/* SELECT * FROM Doors ORDER BY `DoorID` DESC LIMIT 1; */
END $$
DELIMITER ;

DROP Procedure IF EXISTS insertLog;
DELIMITER $$
CREATE PROCEDURE insertLog(IN rID INT,IN uID INT,IN granted BOOLEAN)
BEGIN
INSERT INTO logs VALUES(NULL,rID,uID,granted,NULL);
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
    SET ret = (SELECT (gID MEMBER OF((SELECT `accessGroups` FROM Doors WHERE `DoorID` = rID))));
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
    SET ret = (SELECT (uID MEMBER OF((SELECT `accessUsers` FROM Doors WHERE `DoorID` = rID))));
    RETURN ret;
END $$
DELIMITER ;
--CALL addDoor((SELECT JSON_ARRAY(1,2,3,4)));

SELECT * FROM doors;
SELECT * FROM users;
SELECT * FROM rolegroups;

SELECT * FROM doors INNER JOIN users ON users.`groupIDs` MEMBER OF(doors.`accessGroups`);

DROP PROCEDURE IF EXISTS showUserGroups;
DELIMITER $$
CREATE PROCEDURE showUserGroups(IN uID INT)
BEGIN
    SET @tmp = 0;
    Set @ID = (SELECT JSON_EXTRACT(`groupIDs`,CONCAT('$[',@tmp,']')) FROM users WHERE `userID` = uID);
    DROP TEMPORARY TABLE IF EXISTS tmpGroup;
    CREATE TEMPORARY TABLE tmpGroup(groupID INT);
    WHILE @ID IS NOT NULL DO
        IF @ID IS NOT NULL THEN INSERT INTO tmpGroup VALUES(@ID);
        SET @tmp = @tmp+1;
        Set @ID = (SELECT JSON_EXTRACT(`groupIDs`,CONCAT('$[',@tmp,']')) FROM users WHERE `userID` = uID);
        END IF;
    END WHILE;
    SELECT * FROM tmpGroup;
    DROP TEMPORARY TABLE tmpGroup;
END $$
DELIMITER ;

DROP PROCEDURE IF EXISTS showUserGroupsWithPermission;
DELIMITER $$
CREATE PROCEDURE showUserGroupsWithPermission(IN uID INT,IN dID INT)
BEGIN
    SET @tmp = 0;
    Set @ID = (SELECT JSON_EXTRACT(`groupIDs`,CONCAT('$[',@tmp,']')) FROM users WHERE `userID` = uID);
    DROP TEMPORARY TABLE IF EXISTS tmpGroup;
    CREATE TEMPORARY TABLE tmpGroup(groupID INT,access BOOLEAN);
    WHILE @ID IS NOT NULL DO
        IF @ID IS NOT NULL THEN INSERT INTO tmpGroup (SELECT JSON_EXTRACT(`groupIDs`,CONCAT('$[',@tmp,']')),tb.* FROM users INNER JOIN
            (SELECT COUNT(*) FROM doors WHERE (SELECT JSON_EXTRACT(`groupIDs`,CONCAT('$[',@tmp,']')) FROM users WHERE `userID` = uID) MEMBER OF 
            ((SELECT `accessGroups` FROM doors WHERE `doorID` = dID)) and `doorID` = dID) AS tb WHERE `userID` = uID);
        SET @tmp = @tmp+1;
        Set @ID = (SELECT JSON_EXTRACT(`groupIDs`,CONCAT('$[',@tmp,']')) FROM users WHERE `userID` = uID);
        END IF;
    END WHILE;
    SELECT * FROM tmpGroup;
    DROP TEMPORARY TABLE tmpGroup;
END $$
DELIMITER ;
CALL `showUserGroups`(1);
SELECT * FROM users;
SELECT * FROM tmpGroup;
SELECT * FROM doors;
SELECT `accessGroups` FROM doors WHERE `doorID` = 1;
CALL showUserGroupsWithPermission(1,2);
SELECT JSON_EXTRACT(`groupIDs`,CONCAT('$[0]')),tmp.* FROM users INNER JOIN
(SELECT COUNT(*) FROM doors WHERE (SELECT JSON_EXTRACT(`groupIDs`,CONCAT('$[0]')) FROM users WHERE `userID` = 1) MEMBER OF ((SELECT `accessGroups` FROM doors WHERE `doorID` = 1)) and `doorID` = 1) AS tmp;

CALL insertLog(1,3,1);
SELECT logs.*,rolegroups.`groupName`,users.`userName` FROM logs 
INNER JOIN users ON users.`userID` = logs.`userID`
INNER JOIN rolegroups ON rolegroups.`groupID` = 3 AND 3 MEMBER OF((SELECT `groupIDs` FROM users WHERE `userID` = logs.`userID`));
SELECT * FROM users;