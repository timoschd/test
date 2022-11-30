DROP View IF EXISTS sc.union_ldc;

-- create view
CREATE View sc.union_ldc AS (
    
    WITH leads AS(
    	SELECT 
		"Id"::bigint,
		"Lead Status"::text as lead_status,
		NULL::text as deal_stufe,
		NULL::integer as deal_stage,
		"Created Time"::date as datum,
		"Art der Maßnahme"::text as art_der_massnahme,
		"Owner Name"::text as lead_besitzer,
		NULL::text as deal_besitzer,
		NULL::numeric as betrag,
		NULL::boolean as aufnahme_older_7_days,
		NULL::integer as closing_dauer,
		NULL::boolean as deal_geclosed,
		'Lead' as typ,
		-- calc first day of week (from created time)
		date_trunc('week', "Created Time"::date) as weekstart,
		to_char("Created Time"::date, 'IYYY-IW') as woche,
		to_char("Created Time"::date, 'IYYY-MM') as monat,
		"Modified Time" as last_event_on
	FROM zoho."Leads"),
    closings AS (
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
    ),
    deals as (
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
	FROM zoho."Deals")
    

SELECT * FROM leads
	UNION
SELECT * FROM deals
	UNION
SELECT * FROM closings

);


-- set owner 
ALTER View sc.union_ldc OWNER TO read_only;