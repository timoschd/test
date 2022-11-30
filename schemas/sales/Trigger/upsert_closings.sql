--Create trigger function for insert newer closings
CREATE OR REPLACE FUNCTION sc.upsert_closings()
RETURNS TRIGGER AS
    $BODY$
    BEGIN

	-- delete old entries
    DELETE FROM sc.closings
	WHERE "Id" IN (SELECT "Id" FROM zoho."Deals" WHERE "Modified Time" > (SELECT max(last_event_on) FROM sc.closings)); 

	-- insert new closings 
    INSERT INTO sc.closings
        SELECT 
		"Id"::bigint,
		NULL::text as lead_status,
		"Stage"::text as deal_stufe,
		"Probability (%)"::integer as deal_stage,
		"Auftragsdatum"::date as datum,
		CASE
			WHEN ("Art der Maßnahme"::text NOT IN ('Weiterbildung', 'Umschulung', 'AVGS') OR "Art der Maßnahme"::text IS NULL)
			AND "Auftragsdatum"::date< '2022-10-01'
			AND "Betrag 1"::numeric >= 33000 THEN 'Umschulung'
			WHEN ("Art der Maßnahme"::text NOT IN ('Weiterbildung', 'Umschulung', 'AVGS') OR "Art der Maßnahme"::text IS NULL)
			AND "Auftragsdatum"::date < '2022-10-01'
			AND "Betrag 1"::numeric < 33000 THEN 'Weiterbildung'
			ELSE "Art der Maßnahme"::text END as art_der_massnahme,
		NULL::text as lead_besitzer,
		"Owner Name"::text as deal_besitzer,
		"Betrag 1"::numeric + "Betrag 2"::numeric as betrag,
		NULL::boolean as aufnahme_older_7_days,
		"Auftragsdatum"::date - COALESCE("Aufnahme Datum"::date, "Created Time"::date) as closing_dauer,
		NULL::boolean as deal_geclosed,
		'Closing' as typ,
		-- calc first day of week (from Auftragsdatum datum)
		date_trunc('week', "Auftragsdatum") as weekstart,
		to_Char("Auftragsdatum"::date, 'IYYY-IW') as woche,
		to_char("Auftragsdatum"::date, 'IYYY-MM') as monat,
		"Modified Time" as last_event_on
	FROM zoho."Deals"
	WHERE "Stage"::text IN ('Abgeschlossen', 'Abgeschlossen, gewonnen')
    AND "Id" NOT IN (SELECT "Id" FROM sc.closings) 

    ON CONFLICT ("Id")
    DO NOTHING;

	RETURN NULL;
    END;

    $BODY$
LANGUAGE plpgsql;
-- drop trigger
DROP TRIGGER IF EXISTS trig_closings_sc ON zoho."Deals";

-- trigger on base zoho table with function
CREATE TRIGGER trig_closings_sc
    AFTER INSERT OR UPDATE ON zoho."Deals"
    FOR EACH STATEMENT
    EXECUTE PROCEDURE sc.upsert_closings();
