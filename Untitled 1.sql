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


    CREATE OR REPLACE TABLE
    "PROD_RAW_DB"."INKA"."NYT_GAMES_BUNDLE" (
        dateExtract TIMESTAMP_NTZ,
        primaryKey VARCHAR,
        email VARCHAR,
        nytReferenceID VARCHAR,
        nytSubscriptionCode VARCHAR,
        nytCampaignURL VARCHAR,
        pianoSubscriptionID VARCHAR,
        pianoUserID VARCHAR,
        pianoStartDate VARCHAR,
        pianoSubStatus VARCHAR,
        pianoTermName VARCHAR,
        firstName VARCHAR,
        lastName VARCHAR
    );

    
INSERT INTO PROD_RAW_DB.CONFIGS.INGEST_PARAMETERS VALUES 
(
    'NYT_FULL',
    'INKA',
    'NYT_GAMES_BUNDLE',
    'INKA_STAGE',
    'NYT_DE.csv',
    'INKA_FILE_FORMAT',
    'FULL_REPLACE',
    NULL,
    NULL,
    NULL,
    TRUE,
    CURRENT_TIMESTAMP(),
    CURRENT_TIMESTAMP()
);

INSERT INTO PROD_RAW_DB.CONFIGS.INGEST_PARAMETERS VALUES 
(
    'DIG_REG_FULL',
    'INKA',
    'PIANO_DIGITAL_REGISTRATIONS',
    'INKA_STAGE',
    'SFMC_Piano_DigReg.csv',
    'INKA_FILE_FORMAT',
    'FULL_REPLACE',
    NULL,
    NULL,
    NULL,
    TRUE,
    CURRENT_TIMESTAMP(),
    CURRENT_TIMESTAMP()
);