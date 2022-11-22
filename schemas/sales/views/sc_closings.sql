-- delte view
DROP VIEW IF EXISTS sc.closings;
-- create table 
CREATE VIEW sc.closings AS (
	SELECT 
		"Deals"."Id"::bigint,
		NULL::text as lead_status,
		"Deals"."Stage"::text as deal_stufe,
		"Deals"."Auftragsdatum"::date as datum,
		CASE
			WHEN ("Deals"."Art der Maßnahme"::text NOT IN ('Weiterbildung', 'Umschulung', 'AVGS') OR "Deals"."Art der Maßnahme"::text IS NULL)
			AND "Deals"."Auftragsdatum"::date< '2022-10-01'
			AND "Deals"."Betrag 1"::numeric >= 33000 THEN 'Umschulung'
			WHEN ("Deals"."Art der Maßnahme"::text NOT IN ('Weiterbildung', 'Umschulung', 'AVGS') OR "Deals"."Art der Maßnahme"::text IS NULL)
			AND "Deals"."Auftragsdatum"::date < '2022-10-01'
			AND "Deals"."Betrag 1"::numeric < 33000 THEN 'Weiterbildung'
			ELSE "Deals"."Art der Maßnahme"::text END as art_der_massnahme,
		NULL::text as lead_besitzer,
		"Deals"."Owner Name"::text as deal_besitzer,
		"Deals"."Betrag 1"::numeric as betrag,
		"Deals"."Auftragsdatum"::date - "Deals"."Aufnahme Datum"::date as closing_dauer,
		NULL::boolean as deal_geclosed,
		'Closing' as typ,
		-- calc first day of week (from aufnahme datum)
		cast("Deals"."Auftragsdatum" as date) 
			- cast(date_Part('isodow', cast("Deals"."Auftragsdatum" as date)) as integer) 
			+ 1 as weekstart,
		date_part('day', cast("Deals"."Auftragsdatum" as date)) as tag,
		date_part('isoweek', cast("Deals"."Auftragsdatum" as date)) as woche,
		date_part('month', cast("Deals"."Auftragsdatum" as date)) as monat,
		date_part('isoyear', cast("Deals"."Auftragsdatum" as date)) as jahr
	FROM zoho."Deals"
	WHERE "Deals"."Stage"::text IN ('Abgeschlossen', 'Abgeschlossen, gewonnen'));
-- set owner
ALTER TABLE sc.closings OWNER TO read_only;