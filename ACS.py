import json
import mysql.connector
#def main():
try:
    acsDB = mysql.connector.connect(
        host="localhost",
        user="root",
        password="root",
    )
    print("Connected to the database.")
except:
    raise Exception("Failed to connect the database")
    exit()
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
acscursor.execute('SELECT userAssignedGroups(1)')
result = acscursor.fetchone()
print(tuple(json.loads(result[0])))
#main()