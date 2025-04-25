use database dev_raw_db;
use schema naviga;

create or replace task gh_test_task
  warehouse = ingestion_wh
  schedule = 'USING CRON 0 0 * * * UTC'
  as
  select 1;