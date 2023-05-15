import json
import mysql.connector

C_WHITE = "\033[37m"
C_PURPLE = "\033[95m"
C_RED = "\033[91m"

def connectDB():
    try:
        global acsDB 
        acsDB= mysql.connector.connect(
            host="localhost",
            user="root",
            password="root",
        )
        print("Connected to the database.")
    except:
        raise Exception("Failed to connect the database")
    global acscursor
    acscursor = acsDB.cursor()
    acscursor.execute('CREATE DATABASE IF NOT EXISTS acs')
    acscursor.execute('USE acs')
    acscursor.execute('SHOW TABLES')
    result = acscursor.fetchall()
    if(acscursor.rowcount<4): #The database should contains 4 tables
        print("The database is broken, please recreate the database with the ACS.sql file!")
        exit()

# acscursor.execute("CALL addRole('Skolledning')")
# acscursor.execute("CALL addRole('Teacher')")
# acscursor.execute("CALL addRole('Student')")
# acsDB.commit()
# acscursor.execute('SELECT * FROM `RoleGroups`')
# result = acscursor.fetchall()
# for x in result:
#     print(x)
# acscursor.execute("CALL addUser('Christian Nordahl',JSON_ARRAY(1,2))")
# acscursor.execute("CALL addUser('Anders Carlsson',JSON_ARRAY(2))")
# acscursor.execute("CALL addUser('Xiao Zhu',JSON_ARRAY(3))")
# acsDB.commit()
# acscursor.execute('SELECT userAssignedGroups(1)')
# result = acscursor.fetchone()
# print(tuple(json.loads(result[0])))
#main()

def main():
    connectDB()
    print("*This project is in purpose of application of Mysql")
    print("----Welcome to the Access Control System Demo----")
    selectInMain()

def selectInMain():
    printMainMenu()
    selected = input("> ") 
    selected = int(selected) if selected.isdigit() else -1
    match selected:
        case 1:
            selectInAdmin()
        case 2:
            acscursor.execute()
        case 9:
            print("Good Bye!")
            exit()
        case _:
            print("Unkown choise, select again")
            selectInMain()

def selectInAdmin():
    printAdminMenu()
    selected = input("> ")
    selected = int(selected) if selected.isdigit() else -1
    selected = int(selected)
    match selected:
        case 0:
            selectInMain()
        case 1:
            result = selectAllFromDB("Doors")
            print("----- Doors------")
            print("ID\tAccess Groups\tAccess Users")
            for x in result:
                print(str(x[0])+"\t"+str(x[1])+"\t"+str(x[2]))
        case 2:
            result = selectAllFromDB("Users")
            print("-----Users------")
            print("ID\tName\t\t\t\tRegistered Date\t\tAssigned Groups")
            for x in result:
                print(str(x[0])+"\t"+str(x[1])+"\t\t\t"+str(x[2])+"\t"+str(x[3]).expandtabs(16))
        case 3:
            result = selectAllFromDB("RoleGroups")
            print("-----Role Groups------")
            print("ID\tRole Name")
            for x in result:
                print(str(x[0])+"\t"+str(x[1]))
        case 5:
            print("---Create a  Door---")
            print("You have to enter the group ids which have access to pass this door\n\
Leave it blank if you want to cancel")
            groups = input("Groups that has access: ")
            if len(groups) != 0:
                acscursor.execute(f"CALL addDoor((SELECT JSON_ARRAY({groups})))")
                acsDB.commit()
                acscursor.execute("SELECT * FROM Doors ORDER BY `DoorID` DESC LIMIT 1;")
                result = acscursor.fetchone()
                print("A new Door created: "+str(result))
        case 6:
            print("---Add a User---")
            print("You have to enter user name and the group ids which this user is assigned to\n\
Leave it blank if you want to cancel")
            uname = input("User name: ")
            if len(uname) != 0:
                groups = input("Groups this user belongs: ")
                if len(groups) != 0:
                    acscursor.execute(f"CALL addUser('{uname}',(SELECT JSON_ARRAY({groups})))")
                    acsDB.commit()
                    acscursor.execute("SELECT * FROM users ORDER BY `userID` DESC LIMIT 1;")
                    result = acscursor.fetchone()
                    print("A new user added: "+str(result))
        case 7:
            print("---Add a Role---")
            print("You have to enter group name\n\
Leave it blank if you want to cancel")
            gname = input("Group name: ")
            if len(gname) != 0:
                acscursor.execute(f"CALL addRole('{gname}')")
                acsDB.commit()
                acscursor.execute("SELECT * FROM rolegroups ORDER BY `groupID` DESC LIMIT 1;")
                result = acscursor.fetchone()
                print("A new role added: "+str(result))
        case 8:
            print("---Remove a Door---")
            print("Write All if you want to remove all doors\n\
Leave it blank if you want to cancel")
            tid = input("Door id: ")
            if len(tid) != 0:
                acscursor.execute("DELETE FROM doors "+("" if tid.lower() == "all" else f"WHERE doorID = {tid}"))
        case 9:
            print("---Remove a User---")
            print("Write All if you want to remove all users\n\
Leave it blank if you want to cancel")
            tid = input("User id: ")
            if len(tid) != 0:
                acscursor.execute("DELETE FROM users "+("" if tid.lower() == "all" else f"WHERE userID = {tid}"))
        case 10:
            print("---Remove a Role---")
            print("Write All if you want to remove all roles\n\
Leave it blank if you want to cancel")
            tid = input("Role id: ")
            if len(tid) != 0:
                acscursor.execute("DELETE FROM RoleGroups "+("" if tid.lower() == "all" else f"WHERE groupID = {tid}"))
        case _:
            print("Unkown choise, select again")
    selectInAdmin()

def printMainMenu():
    print("-----------Menu------------")
    print("1. Administrator Panel")
    print("2. Blip my card")
    print(C_PURPLE+"9. Quit"+C_WHITE)
    print("---------------------------")

def printAdminMenu():
    print("-----------Admin Menu------------")
    print(C_PURPLE+"0. Previous Menu"+C_WHITE)
    print("1. Show all  Doors")
    print("2. Show all Users")
    print("3. Show all Roles")
    print("4. Search Log")
    print("5. Create  Door")
    print("6. Create User")
    print("7. Create Role")
    print(C_RED+"8. Delete  Door")
    print("9. Delete User")
    print("10. Delete Role"+C_WHITE)
    print("-------------------------------")

def selectAllFromDB(tbName:str):
    acscursor.execute("SELECT * FROM "+tbName)
    return acscursor.fetchall()
main()

