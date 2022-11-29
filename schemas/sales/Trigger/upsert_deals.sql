--Create trigger function for insert newer deals
CREATE OR REPLACE FUNCTION sc.upsert_deals()
RETURNS TRIGGER AS
    $BODY$
    BEGIN

	-- delete old entries
    DELETE FROM sc.deals_test
	WHERE "Id" IN (SELECT "Id" FROM zoho."Deals" WHERE "Modified Time" > (SELECT max(last_event_on) FROM sc.deals_test)); 

	-- insert new deals 
    INSERT INTO sc.deals_test
        SELECT 
		"Id"::bigint,
		NULL::text as lead_status,
		"Stage"::text as deal_stufe,
		"Probability (%)"::integer as deal_stage,
		COALESCE("Aufnahme Datum"::date, "Created Time"::date) as datum,
		CASE
			WHEN ("Art der Maßnahme"::text NOT IN ('Weiterbildung', 'Umschulung', 'AVGS') OR "Art der Maßnahme"::text IS NULL)
			AND "Aufnahme Datum"::date < '2022-10-01'
			AND "Betrag 1"::numeric >= 33000 THEN 'Umschulung'
			WHEN ("Art der Maßnahme"::text NOT IN ('Weiterbildung', 'Umschulung', 'AVGS') OR "Art der Maßnahme"::text IS NULL)
			AND "Aufnahme Datum"::date < '2022-10-01'
			AND "Betrag 1"::numeric < 33000 THEN 'Weiterbildung'
			ELSE "Art der Maßnahme"::text END as art_der_massnahme,
		NULL::text as lead_besitzer,
		"Owner Name"::text as deal_besitzer,
		("Betrag 1"::numeric + "Betrag 2"::numeric) as betrag,
		CASE 
			WHEN (CURRENT_DATE - COALESCE("Aufnahme Datum"::date, "Created Time"::date)) >= 7
			THEN TRUE::boolean
			ELSE FALSE::boolean END as aufnahme_older_7_days,
		"Auftragsdatum"::date - "Aufnahme Datum"::date as closing_dauer,
		-- calc boolean for deal closed
		CASE 
			WHEN "Auftragsdatum"::date IS NOT NULL 
			AND "Stage"::text IN ('Abgeschlossen','Abgeschlossen, gewonnen')
			THEN TRUE::boolean ELSE FALSE::boolean END as deal_geclosed,
		'Deal' as typ,
		-- calc first day of week (from aufnahme datum)
		date_trunc('week', COALESCE("Aufnahme Datum"::date, "Created Time"::date)) as weekstart,
		to_Char(COALESCE("Aufnahme Datum"::date, "Created Time"::date), 'IYYY-IW') as woche,
		to_Char(COALESCE("Aufnahme Datum"::date, "Created Time"::date), 'IYYY-MM') as monat,
    	"Modified Time" as last_event_on
	FROM zoho."Deals"
	WHERE "Id" NOT IN (SELECT Id FROM sc.deals)
     
    ON CONFLICT ("Id")
    DO NOTHING;

	RETURN NULL;
    END;

    $BODY$
LANGUAGE plpgsql;
-- drop trigger
DROP TRIGGER IF EXISTS trig_deals_sc ON zoho."Deals";

-- trigger on base zoho table with function
CREATE TRIGGER trig_deals_sc
    AFTER INSERT OR UPDATE ON zoho."Deals"
    FOR EACH STATEMENT
    EXECUTE PROCEDURE sc.upsert_deals();
