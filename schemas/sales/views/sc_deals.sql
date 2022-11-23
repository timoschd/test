-- delete view
DROP VIEW IF EXISTS sc.deals;
-- create view
CREATE VIEW sc.deals AS (
	SELECT 
		"Deals"."Id"::bigint,
		NULL::text as lead_status,
		"Deals"."Stage"::text as deal_stufe,
		"Deals"."Probability (%)"::integer as deal_stage,
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
		("Deals"."Betrag 1"::numeric + "Deals"."Betrag 2"::numeric) as betrag,
		"Deals"."Auftragsdatum"::date - "Deals"."Aufnahme Datum"::date as closing_dauer,
		-- calc boolean for deal closed
		CASE 
			WHEN "Deals"."Auftragsdatum"::date IS NULL 
			AND "Deals"."Stage"::text IN ('Abgeschlossen','Abgeschlossen, gewonnen')
			THEN 'True'::boolean ELSE 'False'::boolean END as deal_geclosed,
		'Deal' as typ,
		-- calc first day of week (from aufnahme datum)
		date_trunc('week', "Deals"."Aufnahme Datum"::date) as weekstart,
		to_Char("Deals"."Aufnahme Datum"::date, 'IYYY-IW') as woche,
		to_Char("Deals"."Aufnahme Datum"::date, 'IYYY-MM') as monat
	FROM zoho."Deals");
-- set owner
ALTER TABLE sc.deals OWNER TO read_only;