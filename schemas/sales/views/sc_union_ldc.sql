CREATE VIEW sc.union_ldc AS (
SELECT 
		"Leads"."Id",
		"Leads"."Lead Status" as lead_status,
		NULL as deal_stufe,
		"Leads"."Created Time" as datum,
		"Leads"."Art der Maßnahme" as art_der_massnahme,
		"Leads"."Owner Name" as lead_besitzer,
		NULL as deal_besitzer,
		NULL as betrag,
		NULL as closing_dauer,
		NULL as daal_geclosed,
		'Lead' as typ,
		-- calc first day of week (from created time)
		cast("Leads"."Created Time" as date) 
			- cast(date_Part('isodow', cast("Leads"."Created Time" as date)) as integer) 
			+ 1 as weekstart
	FROM zoho."Leads"

UNION 

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
	FROM zoho."Deals"
	
UNION

	SELECT 
		"Deals"."Id",
		NULL as lead_status,
		"Deals"."Stage" as deal_stufe,
		"Deals"."Auftragsdatum" as datum,
		CASE
			WHEN ("Deals"."Art der Maßnahme" NOT IN ('Weiterbildung', 'Umschulung', 'AVGS') OR "Deals"."Art der Maßnahme" IS NULL)
			AND "Deals"."Auftragsdatum" < '2022-10-01'
			AND "Deals"."Betrag 1"::numeric >= 33000 THEN 'Umschulung'
			WHEN ("Deals"."Art der Maßnahme" NOT IN ('Weiterbildung', 'Umschulung', 'AVGS') OR "Deals"."Art der Maßnahme" IS NULL)
			AND "Deals"."Auftragsdatum" < '2022-10-01'
			AND "Deals"."Betrag 1"::numeric < 33000 THEN 'Weiterbildung'
			ELSE "Deals"."Art der Maßnahme" END as art_der_massnahme,
		NULL as lead_besitzer,
		"Deals"."Owner Name" as deal_besitzer,
		"Deals"."Betrag 1"::numeric as betrag,
		"Deals"."Auftragsdatum" - "Deals"."Aufnahme Datum" as closing_dauer,
		NULL as daal_geclosed,
		'Closing' as typ,
		-- calc first day of week (from aufnahme datum)
		cast("Deals"."Auftragsdatum" as date) 
			- cast(date_Part('isodow', cast("Deals"."Aufnahme Datum" as date)) as integer) 
			+ 1 as weekstart
	FROM zoho."Deals"
	WHERE "Deals"."Stage" IN ('Abgeschlossen', 'Abgeschlossen, gewonnen'))