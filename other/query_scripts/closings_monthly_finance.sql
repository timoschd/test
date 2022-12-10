-- Calculate Total Closings per month and Geschaeftsfeld

with temptbl AS (
SELECT 
	"Id",
	"Auftragsdatum"::date,
	CASE
			WHEN ("Art der Maßnahme"::text NOT IN ('Weiterbildung', 'Umschulung', 'AVGS') OR "Art der Maßnahme"::text IS NULL)
			AND "Auftragsdatum"::date< '2022-10-01'
			AND "Betrag 1"::numeric >= 33000 THEN 'Umschulung'
			WHEN ("Art der Maßnahme"::text NOT IN ('Weiterbildung', 'Umschulung', 'AVGS') OR "Art der Maßnahme"::text IS NULL)
			AND "Auftragsdatum"::date < '2022-10-01'
			AND "Betrag 1"::numeric < 33000 THEN 'Weiterbildung'
			ELSE "Art der Maßnahme"::text END
	as art_x,
	"Betrag 1"::numeric + "Betrag 2"::numeric as closing_value,
	"Stage"
	FROM zoho."Deals"
	WHERE "Auftragsdatum" IS NOT NULL and "Auftragsdatum" >= '2022-06-01' 
	  AND ("Stage" = 'Abgeschlossen' OR "Stage" = 'Storno')
)

SELECT
 date_trunc('month', "Auftragsdatum")::date as Monat,
 art,
 count("Id") as anzahl_closings,
 ROUND(SUM(closing_value)) as closing_value,
 "Stage"
FROM temptbl
GROUP BY date_trunc('month', "Auftragsdatum"::date), "Stage", art
ORDER BY date_trunc('month', "Auftragsdatum"::date)::date;
