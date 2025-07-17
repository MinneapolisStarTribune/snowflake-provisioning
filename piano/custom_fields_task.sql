use role fr_prod_ingestion;

create or replace procedure PROD_RAW_DB.piano.update_custom_fields()
returns string
language SQL
execute as caller
as
$$
begin
  truncate table "PROD_RAW_DB"."PIANO"."CUSTOM_FIELDS";
  
  CREATE TEMP FILE FORMAT "PROD_RAW_DB"."PIANO"."temp_piano_format"
    TYPE=CSV
    SKIP_HEADER=1
    FIELD_DELIMITER=','
    TRIM_SPACE=TRUE
    FIELD_OPTIONALLY_ENCLOSED_BY='"'
    REPLACE_INVALID_CHARACTERS=TRUE
    DATE_FORMAT=AUTO
    TIME_FORMAT=AUTO
    TIMESTAMP_FORMAT=AUTO; 

  COPY INTO "PROD_RAW_DB"."PIANO"."CUSTOM_FIELDS" 
  FROM (SELECT $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20, $21
      FROM '@"PROD_RAW_DB"."PIANO"."PIANO_S3_STAGE"') 
  FILES = ('/extracted/SFMC_Custom_Fields.csv') 
  FILE_FORMAT = '"PROD_RAW_DB"."PIANO"."temp_piano_format"' 
  ON_ERROR=ABORT_STATEMENT;
  
  return 'Success';
end;
$$;

create or replace task PROD_RAW_DB.piano.update_custom_fields
schedule = 'USING CRON 0 5 * * * America/Chicago'
as call PROD_RAW_DB.piano.update_custom_fields();


alter task PROD_RAW_DB.piano.update_custom_fields resume;

