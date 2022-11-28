--Tabelle niemals löschen!!!
-- Create Table
CREATE TABLE sc.upcoming_deals_by_time AS
-- select sum_upcoming_deals per timestamp
SELECT SUM("Deals"."Betrag 1"::numeric + "Deals"."Betrag 2"::numeric) betrag,
NOW()::timestamp as date_time
FROM zoho."Deals" 
WHERE "Deals"."Probability (%)" >= 50
AND "Deals"."Probability (%)" <= 85;

--set owner
ALTER TABLE sc.upcoming_deals_by_time OWNER TO read_only;
