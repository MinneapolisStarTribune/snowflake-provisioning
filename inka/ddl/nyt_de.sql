CREATE OR REPLACE TABLE
    "PROD_RAW_DB"."INKA"."nyt" (
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