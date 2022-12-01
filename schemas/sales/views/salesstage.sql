--drop view 
DROP VIEW IF EXISTS sc.salesstage;

-- Create view
CREATE VIEW sc.salesstage AS
-- closings per berater today
with today AS (
SELECT 	"Owner Name"::text as berater,
		SUM("Betrag 1"::numeric) + SUM("Betrag 2"::numeric) as closing_heute
	FROM zoho."Deals"
	WHERE "Auftragsdatum" = CURRENT_DATE
		AND "Stage" IN ('Abgeschlossen', 'Abgeschlossen, gewonnen')
	GROUP BY berater),
-- closings per berater this week	
week AS (
SELECT 	"Owner Name"::text as berater,
		SUM("Betrag 1"::numeric) + SUM("Betrag 2"::numeric) as closing_woche
	FROM zoho."Deals"
	WHERE date_trunc('week', "Auftragsdatum") = date_trunc('week', CURRENT_DATE)
		AND "Stage" IN ('Abgeschlossen', 'Abgeschlossen, gewonnen')
	GROUP BY berater
),
-- closings per berater this month
month AS (
SELECT 	"Owner Name"::text as berater,
		SUM("Betrag 1"::numeric) + SUM("Betrag 2"::numeric) as closing_monat
	FROM zoho."Deals"
	WHERE date_trunc('month', "Auftragsdatum") = date_trunc('month', CURRENT_DATE)
		AND "Stage" IN ('Abgeschlossen', 'Abgeschlossen, gewonnen')
	GROUP BY berater
),
-- closings per berater this year
year AS (
SELECT 	"Owner Name"::text as berater,
		SUM("Betrag 1"::numeric) + SUM("Betrag 2"::numeric) as closing_year
	FROM zoho."Deals"
	WHERE date_trunc('year', "Auftragsdatum") = date_trunc('year', CURRENT_DATE)
		AND "Stage" IN ('Abgeschlossen', 'Abgeschlossen, gewonnen')
	GROUP BY berater
),
-- closings per berater with stage 75% all time
stage AS (
SELECT 	"Owner Name"::text as berater,
		SUM("Betrag 1"::numeric) + SUM("Betrag 2"::numeric) as "75er_gesamt"
	FROM zoho."Deals"
	WHERE "Probability (%)" = 75
	GROUP BY berater
),
-- closings per berater woth stage 75% and closing date this month
stage_closing AS (
SELECT 	"Owner Name"::text as berater,
		SUM("Betrag 1"::numeric) + SUM("Betrag 2"::numeric) as "75er_stage_mit_closing_date_diesen_monat"
	FROM zoho."Deals"
	WHERE date_trunc('month', "Closing Date") = date_trunc('month', CURRENT_DATE)
		AND "Probability (%)" = 75
	GROUP BY berater
),
-- all berater (unique)
berater AS (
SELECT 	"Deals"."Owner Name"::text as berater
	FROM zoho."Deals"
	GROUP BY berater
	HAVING "Deals"."Owner Name"::text NOT IN ('Steffen Deutsch', 'Lars Petersen', 'Peter Langheinrich', 'Romy Kopsch', 'karriere tutor', 
                                                'Kiriaki Orfanidis Corral', 'Test Account', 'Melanie Schnitzler')
	),
images as (
SELECT 	berater,
		url
	FROM sc.images)
	
-- Table for all kpis

SELECT	berater.berater,
		COALESCE(today.closing_heute, 0) as closings_heute,
		COALESCE(week.closing_woche, 0) as closings_woche,
		COALESCE(month.closing_monat, 0) as closings_monat,
		COALESCE(year.closing_year, 0) as closings_jahr,
		COALESCE(stage."75er_gesamt", 0) as "closings_75_stage_gesamt",
		COALESCE(stage_closing."75er_stage_mit_closing_date_diesen_monat", 0) as "75er_stage_mit_closing_date_diesen_monat",
		images.url
FROM berater
	LEFT JOIN today on berater.berater = today.berater
	LEFT JOIN week on berater.berater = week.berater
	LEFT JOIN month on berater.berater = month.berater
	LEFT JOIN year on berater.berater = year.berater
	LEFT JOIN stage ON berater.berater = stage.berater
	LEFT JOIN stage_closing ON berater.berater = stage_closing.berater
	LEFT JOIN images ON berater.berater = images.berater;

-- set owner
ALTER VIEW sc.salesstage OWNER to read_only;