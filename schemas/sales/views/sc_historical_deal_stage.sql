-- drop view
DROP VIEW IF EXISTS sc.historical_deal_stage;
--Create view
Create VIEW sc.historical_deal_stage AS 
--select newest entrie per day
with max_time_by_date AS (
SELECT 	date_time::date as datum,
		max(date_time::time) as zeit
FROM sc.upcoming_deals_by_time
GROUP BY datum)
--select newest value per day by join value to newest entrie per day
SELECT 	max_time_by_date.datum as date,
		upcoming_deals_by_time.betrag as sum_upcoming_deals_all_time
	FROM max_time_by_date
	LEFT JOIN sc.upcoming_deals_by_time 
		ON max_time_by_date.datum = upcoming_deals_by_time.date_time::date 
		AND max_time_by_date.zeit = upcoming_deals_by_time.date_time::time;
-- set OWNER
ALTER TABLE sc.historical_deal_stage OWNER TO read_only;