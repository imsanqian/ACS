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

acscursor.execute("CALL addReader((SELECT JSON_ARRAY(1,2,3,4)))")
acsDB.commit()
acscursor.execute('SELECT * FROM `Readers`')
result = acscursor.fetchall()
for x in result:
    print(x)

#main()