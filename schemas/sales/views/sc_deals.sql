CREATE VIEW sc.deals AS (
	SELECT 
		"Deals"."Id",
		NULL as lead_status,
		"Deals"."Stage" as deal_stufe,
		"Deals"."Aufnahme Datum" as datum,
		CASE
			WHEN ("Deals"."Art der Maßnahme" NOT IN ('Weiterbildung', 'Umschulung', 'AVGS') OR "Deals"."Art der Maßnahme" IS NULL)
			AND "Deals"."Aufnahme Datum" < '2022-10-01'
			AND "Deals"."Betrag 1"::numeric >= 33000 THEN 'Umschulung'
			WHEN ("Deals"."Art der Maßnahme" NOT IN ('Weiterbildung', 'Umschulung', 'AVGS') OR "Deals"."Art der Maßnahme" IS NULL)
			AND "Deals"."Aufnahme Datum" < '2022-10-01'
			AND "Deals"."Betrag 1"::numeric < 33000 THEN 'Weiterbildung'
			ELSE "Deals"."Art der Maßnahme" END as art_der_massnahme,
		NULL as lead_besitzer,
		"Deals"."Owner Name" as deal_besitzer,
		"Deals"."Betrag 1"::numeric as betrag,
		"Deals"."Auftragsdatum" - "Deals"."Aufnahme Datum" as closing_dauer,
		-- calc boolean for deal closed
		CASE 
			WHEN "Deals"."Auftragsdatum" IS NULL 
			AND "Deals"."Stage" IN ('Abgeschlossen','Abgeschlossen, gewonnen')
			THEN 'True' ELSE 'False' END as daal_geclosed,
		'Deal' as typ,
		-- calc first day of week (from aufnahme datum)
		cast("Deals"."Aufnahme Datum" as date) 
			- cast(date_Part('isodow', cast("Deals"."Aufnahme Datum" as date)) as integer) 
			+ 1 as weekstart
	FROM zoho."Deals")
	