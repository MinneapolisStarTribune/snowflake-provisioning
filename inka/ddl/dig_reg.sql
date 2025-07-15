CREATE OR REPLACE TABLE
    "PROD_RAW_DB"."INKA"."PIANO_DIGITAL_REGISTRATIONS" (
        primaryKey VARCHAR,
        User_ID VARCHAR,
        User_Email VARCHAR,
        First_Name VARCHAR,
        Last_Name VARCHAR,
        Create_Date VARCHAR,
        Start_Date DATE,
        Access_Status BOOLEAN,
        Access_Expiration_Date VARCHAR,
        Term_ID VARCHAR,
        Term_Name VARCHAR
    );