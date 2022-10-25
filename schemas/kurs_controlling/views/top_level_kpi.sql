-- View für Top-Level KPIs (monatlich) ab 01/2019
DROP VIEW IF EXISTS kc.top_level_kpi;
CREATE VIEW kc.top_level_kpi AS
-- alle Monate von 01/2019 bis heute + 1 Jahr
WITH date AS (
SELECT 	to_Char(date_trunc('month', dd)::date, 'YYYY-MM') as datum
FROM generate_series('2019-01-01'::date, CURRENT_DATE + '1 year'::interval, '1 month'::interval) dd),
-- count, sum & avg alle Deals pro Monat
deals AS (
SELECT 	to_Char((CAST(aufnahme_datum as json)->>'start_date')::date, 'YYYY-MM') as datum,
		COUNT(DISTINCT app_item_id) as deals_count,
		ROUND(SUM(calclehrgangsgebuehren::numeric), 2) as deals_sum,
		ROUND(AVG(calclehrgangsgebuehren::numeric), 2) as deals_avg
	FROM podio.sales_management_leads 
	WHERE (CAST(aufnahme_datum as json)->>'start_date')::date >= '2019-01-01'
	GROUP BY datum
	ORDER BY datum ASC),
-- count, sum & avg alle Bookings pro Monat
bookings AS (
SELECT 	to_Char((CAST(auftragsdatum as json)->>'start_date')::date, 'YYYY-MM') as datum,
		COUNT(DISTINCT app_item_id) as bookings_count,
		ROUND(SUM(calclehrgangsgebuehren::numeric), 2) as bookings_sum,
		ROUND(AVG(calclehrgangsgebuehren::numeric), 2) as bookings_avg
	FROM podio.sales_management_leads 
	WHERE (CAST(auftragsdatum as json)->>'start_date')::date >= '2019-01-01'
		AND (status2::JSON ->> 'text'::text) != 'STORNO'
		AND auftragsdatum IS NOT NULL
	GROUP BY datum
	ORDER BY datum ASC),
-- zähle Bookings ab Aufnahmedatum pro Monat
bookings_aufnahme AS (
SELECT 	to_Char((CAST(aufnahme_datum as json)->>'start_date')::date, 'YYYY-MM') as datum,
		COUNT(DISTINCT app_item_id) as bookings_aufnahme
	FROM podio.sales_management_leads 
	WHERE (CAST(aufnahme_datum as json)->>'start_date')::date >= '2019-01-01'
		AND (status2::JSON ->> 'text'::text) != 'STORNO'
		AND auftragsdatum IS NOT NULL
	GROUP BY datum
	ORDER BY datum ASC),
-- Realisierter Umsatz pro Monat
-- ## temp für gefilterte Einträge ohne mehrfach eintragungen
temp_umsatz AS (
SELECT lead_id, betrag_rate, startdatum_bgs, zahlungsende 
FROM kc.kunden_kurs_umsatz_pro_tag 
WHERE enddatum_bgs >= '2019-01-01'
	AND lead_status != 'STORNO'
GROUP BY lead_id, betrag_rate, startdatum_bgs, zahlungsende),
umsatz AS (
SELECT 	to_Char(date_trunc('month', dd)::date, 'YYYY-MM') as datum,
		ROUND(SUM(betrag_rate)::numeric, 2) as umsatz_realisiert
FROM generate_series('2019-01-01'::date, CURRENT_DATE + '1 year'::interval, '1 month'::interval) dd
JOIN temp_umsatz
	ON startdatum_bgs < (date_trunc('month', dd)::date) + ('1 month'::interval)
		AND zahlungsende >= date_trunc('month', dd)::date
GROUP BY datum
ORDER BY datum ASC),
-- zähle Teilnehmerstarts pro Monat
teilnehmerstarts AS (
SELECT	to_Char(teilnehmer_startdatum, 'YYYY-MM') as datum,
		COUNT(DISTINCT teilnehmer_id_tutoren) as teilnehmerstarts
	FROM tc.teilnehmer
	WHERE teilnehmer_startdatum >= '2019-01-01'
	GROUP BY datum
	ORDER BY datum ASC),
-- zähle Kursstarts pro Monat
kursstarts AS (
SELECT	to_Char(startdatum, 'YYYY-MM') as datum,
		COUNT(DISTINCT lehrgangs_details_id) as kursstarts
	FROM tc.teilnehmer_kurs_zuordnung
	WHERE startdatum >= '2019-01-01'
	GROUP BY datum
	ORDER BY datum ASC),
-- zähle Abbrecher pro Monat
abbrecher AS (
SELECT	to_Char(abbruchtag, 'YYYY-MM') as datum,
		COUNT(DISTINCT lead_id) as abbrecher
	FROM kc.kunden_kurs_umsatz_pro_tag
	WHERE abbruchtag >= '2019-01-01'
	GROUP BY datum
	ORDER BY datum ASC),
-- zähle Abgeschlossene Kurse pro Monat
abgeschlossen AS (
SELECT	to_Char(enddatum, 'YYYY-MM') as datum,
		COUNT(DISTINCT lehrgangs_details_id) as beendete_kurse
	FROM tc.teilnehmer_kurs_zuordnung
	WHERE enddatum >= '2019-01-01'
	GROUP BY datum
	ORDER BY datum ASC),
-- zähle Absolventen pro Monat
absolventen AS (
SELECT	to_Char(teilnehmer_enddatum, 'YYYY-MM') as datum,
		COUNT(DISTINCT teilnehmer_id_tutoren) as absolventen
	FROM tc.teilnehmer
	WHERE teilnehmer_enddatum >= '2019-01-01'
	GROUP BY datum
	ORDER BY datum ASC),
-- zähle kursteilnahmen pro Monat
kursteilnahmen AS (
-- ##	selektiere alle Monate von Datumliste und formatiere zu Jahr-Monat
SELECT 	to_Char(date_trunc('month', dd)::date, 'YYYY-MM') as datum,
		-- ##	zähle alle tn aus tn_k_z
		COUNT(DISTINCT lehrgangs_details_id) as kursteilnahmen
-- ##	generiere Liste mit allen Monaten von 01/2019 bis heute + 1 Jahr
FROM generate_series('2019-01-01'::date, CURRENT_DATE + '1 year'::interval, '1 month'::interval) dd
-- ##	joine die liste teilnehmer Kurs dran
JOIN tc.teilnehmer_kurs_zuordnung 
	-- ##	startdatum muss vor oder am monatsletzten sein
	ON startdatum < (date_trunc('month', dd)::date) + ('1 month'::interval)
		-- ##	enddatum muss nach oder am monatsersten sein
		AND enddatum >= date_trunc('month', dd)::date
-- ##	grupiere nach monat und sortiere aufsteigend
GROUP BY datum
ORDER BY datum ASC),
-- zähle alle teilnehmer pro Monat
teilnehmer AS (
SELECT 	to_Char(date_trunc('month', dd)::date, 'YYYY-MM') as datum,
		COUNT(DISTINCT teilnehmer_id_tutoren) as teilnehmer
FROM generate_series('2019-01-01'::date, CURRENT_DATE + '1 year'::interval, '1 month'::interval) dd
LEFT JOIN tc.teilnehmer_kurs_zuordnung 
	ON startdatum < (date_trunc('month', dd)::date) + ('1 month'::interval)
		AND COALESCE(abbruch_datum, enddatum) >= date_trunc('month', dd)::date
WHERE teilnehmer_kurs_zuordnung.status IN ('Beendet', 'Abbruch nach aktuellem Lehrgang', 'Im Lehrgang', 'Prüfungswoche') 
GROUP BY datum
ORDER BY datum ASC),
-- Ø Teilnehmer pro Monat
-- ## temptable für Teilnehmeranzahl (tageweise)
temp_tn_avg AS (
SELECT 	date_trunc('day', dd)::date as d,
		COUNT(DISTINCT teilnehmer_id_tutoren) as teilnehmer_avg
FROM generate_series('2019-01-01'::date, CURRENT_DATE + '1 year'::interval, '1 day'::interval) dd
LEFT JOIN tc.teilnehmer_kurs_zuordnung 
	ON startdatum <= (date_trunc('day', dd)::date)
		AND COALESCE(abbruch_datum, enddatum) >= date_trunc('day', dd)::date
WHERE teilnehmer_kurs_zuordnung.status IN ('Beendet', 'Abbruch nach aktuellem Lehrgang', 'Im Lehrgang', 'Prüfungswoche')
GROUP BY d
ORDER BY d ASC),
-- ## hier Øteilnehmer
avg_teilnehmer AS (
SELECT 	to_Char(d, 'YYYY-MM') as datum,
		ROUND(AVG(teilnehmer_avg), 2) as teilnehmer_avg
	FROM temp_tn_avg
	GROUP BY datum
	ORDER BY datum ASC)
-- join kpis
SELECT	date.datum,
		COALESCE(deals.deals_count, 0) as deals_count,
		COALESCE(deals.deals_sum, 0) as deals_sum,
		COALESCE(deals.deals_avg, 0) as deals_avg,
		COALESCE(bookings.bookings_count, 0) as bookings_count,
		COALESCE(bookings.bookings_sum, 0) as bookings_sum,
		COALESCE(bookings.bookings_avg, 0) as bookings_avg,
		COALESCE(bookings_aufnahme.bookings_aufnahme, 0) as bookings_aufnahme,
		COALESCE(umsatz.umsatz_realisiert, 0) as umsatz_realisiert,
		COALESCE(teilnehmerstarts.teilnehmerstarts, 0) as teilnehmerstarts,
		COALESCE(kursstarts.kursstarts, 0) as kursstarts,
		COALESCE(abbrecher.abbrecher, 0) as abbrecher,
		COALESCE(abgeschlossen.beendete_kurse, 0) as beendete_kurse,
		COALESCE(absolventen.absolventen, 0) as absolventen,
		COALESCE(kursteilnahmen.kursteilnahmen, 0) as kursteilnahmen,
		COALESCE(teilnehmer.teilnehmer, 0) as teilnehmer,
		COALESCE(avg_teilnehmer.teilnehmer_avg, 0) as teilnehmer_avg
	FROM date
	LEFT JOIN deals ON date.datum = deals.datum
	LEFT JOIN bookings ON date.datum = bookings.datum
	LEFT JOIN bookings_aufnahme ON date.datum = bookings_aufnahme.datum
	LEFT JOIN umsatz ON date.datum = umsatz.datum
	LEFT JOIN teilnehmerstarts ON date.datum = teilnehmerstarts.datum
	LEFT JOIN kursstarts ON date.datum = kursstarts.datum
	LEFT JOIN abbrecher ON date.datum = abbrecher.datum
	LEFT JOIN abgeschlossen ON date.datum = abgeschlossen.datum
	LEFT JOIN absolventen ON date.datum = absolventen.datum
	LEFT JOIN kursteilnahmen ON date.datum = kursteilnahmen.datum
	LEFT JOIN teilnehmer ON date.datum = teilnehmer.datum
	LEFT JOIN avg_teilnehmer ON date.datum = avg_teilnehmer.datum;
	