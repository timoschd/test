-- delete view
DROP VIEW IF EXISTS sc.deals;
-- create view
CREATE VIEW sc.deals AS (
	SELECT 
		"Deals"."Id"::bigint,
		NULL::text as lead_status,
		"Deals"."Stage"::text as deal_stufe,
		"Deals"."Aufnahme Datum"::date as datum,
		CASE
			WHEN ("Deals"."Art der Maßnahme"::text NOT IN ('Weiterbildung', 'Umschulung', 'AVGS') OR "Deals"."Art der Maßnahme"::text IS NULL)
			AND "Deals"."Aufnahme Datum"::date < '2022-10-01'
			AND "Deals"."Betrag 1"::numeric >= 33000 THEN 'Umschulung'
			WHEN ("Deals"."Art der Maßnahme"::text NOT IN ('Weiterbildung', 'Umschulung', 'AVGS') OR "Deals"."Art der Maßnahme"::text IS NULL)
			AND "Deals"."Aufnahme Datum"::date < '2022-10-01'
			AND "Deals"."Betrag 1"::numeric < 33000 THEN 'Weiterbildung'
			ELSE "Deals"."Art der Maßnahme"::text END as art_der_massnahme,
		NULL::text as lead_besitzer,
		"Deals"."Owner Name"::text as deal_besitzer,
		"Deals"."Betrag 1"::numeric as betrag,
		"Deals"."Auftragsdatum"::date - "Deals"."Aufnahme Datum"::date as closing_dauer,
		-- calc boolean for deal closed
		CASE 
			WHEN "Deals"."Auftragsdatum"::date IS NULL 
			AND "Deals"."Stage"::text IN ('Abgeschlossen','Abgeschlossen, gewonnen')
			THEN 'True'::boolean ELSE 'False'::boolean END as deal_geclosed,
		'Deal' as typ,
		-- calc first day of week (from aufnahme datum)
		cast("Deals"."Aufnahme Datum" as date) 
			- cast(date_Part('isodow', cast("Deals"."Aufnahme Datum" as date)) as integer) 
			+ 1 as weekstart,
		date_part('day', cast("Deals"."Aufnahme Datum" as date)) as tag,
		date_part('isoweek', cast("Deals"."Aufnahme Datum" as date)) as woche,
		date_part('month', cast("Deals"."Aufnahme Datum" as date)) as monat,
		date_part('isoyear', cast("Deals"."Aufnahme Datum" as date)) as jahr
	FROM zoho."Deals");
-- set owner
ALTER TABLE sc.deals OWNER TO read_only;