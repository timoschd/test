-- delte view if exists
DROP VIEW IF EXISTS sc.closings_by_day_and_berater;

-- create view
CREATE VIEW sc.closings_by_day_and_berater AS 
with closings AS (
SELECT	"Owner Name"::text as berater,
        "Betrag 1"::numeric + "Betrag 2"::numeric as wert,
		"Auftragsdatum"::date as datum,
		CASE
			WHEN ("Art der Maßnahme"::text NOT IN ('Weiterbildung', 'Umschulung', 'AVGS') OR "Art der Maßnahme"::text IS NULL)
			AND "Auftragsdatum"::date< '2022-10-01'
			AND "Betrag 1"::numeric >= 33000 THEN 'Umschulung'
			WHEN ("Art der Maßnahme"::text NOT IN ('Weiterbildung', 'Umschulung', 'AVGS') OR "Art der Maßnahme"::text IS NULL)
			AND "Auftragsdatum"::date < '2022-10-01'
			AND "Betrag 1"::numeric < 33000 THEN 'Weiterbildung'
			ELSE "Art der Maßnahme"::text END as art
FROM zoho."Deals"
WHERE "Stage"::text IN ('Abgeschlossen', 'Abgeschlossen, gewonnen')),

split_wert AS (
SELECT	berater,
		wert,
		datum,
		art,
		CASE WHEN art = 'Weiterbildung' THEN wert END as w, --var w for art weiterbildung
		CASE WHEN art = 'Umschulung' THEN wert END as u, --var u for art umschulung
		CASE WHEN art = 'AVGS' THEN wert END as a, --var a for art avgs
		CASE WHEN art NOT IN ('Weiterbildung', 'Umschulung', 'AVGS') THEN wert END as x --var x for unknown art
FROM closings)

SELECT 	berater,
		sum(wert) as wert,
		datum,
		COUNT(DISTINCT w) as weiterbildungen,
		SUM(w) as wert_weiterbildungen,
		COUNT(DISTINCT u) as umschulungen,
		SUM(u) as wert_umschulungen,
		COUNT(DISTINCT a) as avgs,
		SUM(a) as wert_avgs,
		COUNT(DISTINCT x) as unbekannt,
		SUM(X) as wert_unbekannt
FROM split_wert
GROUP BY berater, datum;

-- set owner
ALTER TABLE sc.closings_by_day_and_berater OWNER to read_only;
