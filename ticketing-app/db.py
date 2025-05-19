import mysql.connector

def get_db_connection():
    connection = mysql.connector.connect(
        host="localhost",
        user="root",
        port = 3308,
        password="sharanrao",
        database="ticketingdb"
    )
    return connection
