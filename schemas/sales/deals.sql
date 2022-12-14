-- delete view
DROP TABLE IF EXISTS sc.deals;

-- create view
CREATE TABLE sc.deals AS (
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
	FROM zoho."Deals");

-- set owner
ALTER TABLE sc.deals OWNER TO read_only;

-- PK
ALTER TABLE sc.deals
    ADD PRIMARY KEY ("Id");

CREATE INDEX ON sc.deals (last_event_on); 