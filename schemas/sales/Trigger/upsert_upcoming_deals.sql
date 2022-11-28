--Create trigger function for insert newer upcoming_deals
CREATE OR REPLACE FUNCTION sc.upsert_upcoming_deals()
RETURNS TRIGGER AS
    $BODY$
    BEGIN
	-- insert new deal value by time 
    INSERT INTO sc.upcoming_deals_by_time
        SELECT 	SUM("Deals"."Betrag 1"::numeric + "Deals"."Betrag 2"::numeric) betrag,
				NOW()::timestamp as date_time
			FROM zoho."Deals" 
			WHERE "Deals"."Probability (%)" >= 50
			AND "Deals"."Probability (%)" <= 85

    ON CONFLICT (date_time)
    DO NOTHING;

	RETURN NULL;
    END;

    $BODY$
LANGUAGE plpgsql;
-- drop trigger
DROP TRIGGER IF EXISTS trig_upsert_upcoming_deals ON zoho."Deals";

-- trigger on base podio table with function
CREATE TRIGGER trig_upsert_upcoming_deals
    AFTER INSERT OR UPDATE ON zoho."Deals"
    FOR EACH STATEMENT
    EXECUTE PROCEDURE sc.upsert_upcoming_deals();
