import pandas as pd
import pymysql
import numpy as np

# Load CSV
df = pd.read_csv(r"C:\Users\HP\Downloads\bookings.csv")

# Replace NaN/NaT with None (Python null)
df = df.replace({np.nan: None, pd.NaT: None})

# --- MySQL Connection ---
conn = pymysql.connect(
    host="localhost",
    user="my_username",
    password="my_password",
    database="ola"
)
cursor = conn.cursor()

cursor.execute("DROP TABLE IF EXISTS bookings")

# Create table
create_table_query = """
CREATE TABLE IF NOT EXISTS bookings (
    Date DATE,
    Time VARCHAR(20),
    Booking_ID VARCHAR(50) PRIMARY KEY,
    Booking_Status VARCHAR(50),
    Customer_ID VARCHAR(50),
    Vehicle_Type VARCHAR(50),
    Pickup_Location VARCHAR(100),
    Drop_Location VARCHAR(100),
    V_TAT INT,
    C_TAT INT,
    Canceled_Rides_by_Customer VARCHAR(100),
    Canceled_Rides_by_Driver VARCHAR(100),
    Incomplete_Rides VARCHAR(10),
    Incomplete_Rides_Reason VARCHAR(255),
    Booking_Value FLOAT,
    Payment_Method VARCHAR(50),
    Ride_Distance FLOAT,
    Driver_Ratings FLOAT,
    Customer_Rating FLOAT
);
"""
cursor.execute(create_table_query)

# Prepare insert
insert_query = """
INSERT INTO bookings (
    Date, Time, Booking_ID, Booking_Status, Customer_ID,
    Vehicle_Type, Pickup_Location, Drop_Location, V_TAT, C_TAT,
    Canceled_Rides_by_Customer, Canceled_Rides_by_Driver,
    Incomplete_Rides, Incomplete_Rides_Reason, Booking_Value,
    Payment_Method, Ride_Distance, Driver_Ratings, Customer_Rating
) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
"""

# Convert dataframe rows into tuples
data = [tuple(row) for row in df.to_numpy()]

# Insert all data
cursor.executemany(insert_query, data)
conn.commit()

print("Data inserted successfully!")

cursor.close()
conn.close()
