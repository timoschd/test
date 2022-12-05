-- delete
DROP VIEW IF EXISTS zoho.ruecklaufquoten;

-- create
CREATE VIEW zoho.ruecklaufquoten AS
-- definiere Zeitraum von 08/2022 (Start der befragungen) bis heute + 1 Jahr & cross join alle befragungstypen
with monat AS (
SELECT 	to_Char(date_trunc('month', dd)::date, 'YYYY-MM') as monat,
		CASE 
			WHEN survey_surveys.name = 'Absolventenbefragung 2022' 
			THEN 'Absolventenbefragung' 
			ELSE survey_surveys.name 
		END as befragung
	FROM generate_series('2022-08-01'::date, CURRENT_DATE + '1 year'::interval, '1 month'::interval) as dd
	CROSS JOIN zoho.survey_surveys
),
-- select anzahl antworten pro monat, befragung
antworten AS (
SELECT 	COUNT(DISTINCT survey_respondents.id) as antworten,  
		to_Char(survey_respondents.end_date::date, 'YYYY-MM') as monat, 
		CASE 
			WHEN survey_surveys.name = 'Absolventenbefragung 2022' 
			THEN 'Absolventenbefragung' 
			ELSE survey_surveys.name 
		END as befragung	FROM zoho.survey_respondents
	 JOIN zoho.survey_surveys
		ON survey_respondents.survey_id = survey_surveys.id
	GROUP BY befragung, monat
	ORDER BY monat DESC, befragung ASC
),
-- select anzahl gesendete befragungen pro monat, befragung
gesendet AS (
SELECT 	COUNT(DISTINCT app_item_id) as gesendet,
		to_char((CAST(sende_datum as json)->>'start_date')::date, 'YYYY-MM') as monat,
		CAST(json_surveydetails as json)->>'SurveyType' as befragung
	FROM podio.evaluation_survey
	WHERE CAST(status as json)->>'text' = 'Gesendet'
	GROUP BY befragung, monat
	ORDER BY monat DESC, befragung ASC
),
-- select anzahl befragungen welche versendet werden sollen pro monat, befragung
senden AS (
SELECT 	COUNT(DISTINCT app_item_id) as senden,
		to_char((CAST(sende_datum as json)->>'start_date')::date, 'YYYY-MM') as monat,
		CAST(json_surveydetails as json)->>'SurveyType' as befragung
	FROM podio.evaluation_survey
	WHERE CAST(status as json)->>'text' IN ('Erstellt', 'Senden')
	GROUP BY befragung, monat
	ORDER BY monat DESC, befragung ASC)
-- join ausgefüllt, senden, gesendet an monat/befragung
SELECT 	monat.monat as jahr_monat, 
		monat.befragung as befragungstyp, 
		COALESCE(antworten.antworten, 0) as ausgefuellt,
		COALESCE(gesendet.gesendet, 0) as versendet,
		COALESCE(senden.senden, 0) as zu_versenden
	FROM monat 
	LEFT JOIN antworten ON monat.monat = antworten.monat AND monat.befragung = antworten.befragung
	LEFT JOIN gesendet ON monat.monat = gesendet.monat AND monat.befragung = gesendet.befragung
	LEFT JOIN senden ON monat.monat = senden.monat AND monat.befragung = senden.befragung
	ORDER BY jahr_monat, befragungstyp;
	
-- setze owner		
ALTER TABLE zoho.ruecklaufquoten 
	OWNER TO read_only;