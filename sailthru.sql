use database prod_raw_db;
use schema sailthru;

SELECT *
from campaign c
left join client cl on c.client_id = cl.client_id
limit 1000;

select distinct name
from campaign;