use database prod_raw_db;
use schema inka;

CREATE OR REPLACE TABLE
    "PROD_RAW_DB"."INKA"."E_BILLING_NAVIGA" (
        dateExtract TIMESTAMP_NTZ,
        primaryKey VARCHAR,
        SubscriptionID NUMBER (38, 0),
        emailAddress VARCHAR,
        Delivery_Name VARCHAR,
        Delivery_Address1 VARCHAR,
        Delivery_Address2 VARCHAR,
        Delivery_Address3 VARCHAR,
        DeliveryScheduleID VARCHAR,
        DeliveryScheduleDescription VARCHAR,
        BillDate DATE,
        RenewalType VARCHAR,
        RenewalNumber NUMBER (38, 0),
        RateCodeID VARCHAR,
        Current_PaidThrough_Date DATE,
        PastDueAmount VARCHAR,
        PymtTerm_Opt1_Description VARCHAR,
        PymtTerm_Opt1_Service_Dates VARCHAR,
        PymtTerm_Opt1_Amount VARCHAR,
        PymtTerm_Opt1_AmountBeforeTaxes VARCHAR,
        PymtTerm_Opt1_CityTax VARCHAR,
        PymtTerm_Opt1_CountyTax VARCHAR,
        PymtTerm_Opt1_StateTax VARCHAR,
        PymtTerm_Opt1_PaidThruDate DATE,
        PymtTerm_Opt2_Description VARCHAR,
        PymtTerm_Opt2_Service_Dates VARCHAR,
        PymtTerm_Opt2_Amount VARCHAR,
        PymtTerm_Opt2_AmountBeforeTaxes VARCHAR,
        PymtTerm_Opt2_CityTax VARCHAR,
        PymtTerm_Opt2_CountyTax VARCHAR,
        PymtTerm_Opt2_StateTax VARCHAR,
        PymtTerm_Opt2_PaidThruDate VARCHAR,
        PymtTerm_Opt3_Description VARCHAR,
        PymtTerm_Opt3_Service_Dates VARCHAR,
        PymtTerm_Opt3_Amount VARCHAR,
        PymtTerm_Opt3_AmountBeforeTaxes VARCHAR,
        PymtTerm_Opt3_CityTax VARCHAR,
        PymtTerm_Opt3_CountyTax VARCHAR,
        PymtTerm_Opt3_StateTax VARCHAR,
        PymtTerm_Opt3_PaidThruDate VARCHAR,
        PymtTerm_Opt4_Description VARCHAR,
        PymtTerm_Opt4_Service_Dates VARCHAR,
        PymtTerm_Opt4_Amount VARCHAR,
        PymtTerm_Opt4_AmountBeforeTaxes VARCHAR,
        PymtTerm_Opt4_CityTax VARCHAR,
        PymtTerm_Opt4_CountyTax VARCHAR,
        PymtTerm_Opt4_StateTax VARCHAR,
        PymtTerm_Opt4_PaidThruDate VARCHAR,
        GroupCode VARCHAR,
        dtiSubscriptionKey VARCHAR
    );

delete from PROD_RAW_DB.CONFIGS.INGEST_PARAMETERS where CONFIG_NAME='EBILL_FULL';

    INSERT INTO PROD_RAW_DB.CONFIGS.INGEST_PARAMETERS VALUES 
(
    'EBILL_FULL',
    'INKA',
    'E_BILLING_NAVIGA',
    'INKA_STAGE',
    'SFMC_Import_ebillinfo.csv',
    'INKA_FILE_FORMAT',
    'FULL_REPLACE',
    NULL,
    NULL,
    NULL,
    TRUE,
    CURRENT_TIMESTAMP(),
    CURRENT_TIMESTAMP()
);

select distinct productid
from mde_test;

select *
from nyt_games_bundle; --nytsubscriptioncode or nytreferenceid

-- send entire ebill (joined to mde) every sunday