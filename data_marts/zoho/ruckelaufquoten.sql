DROP VIEW IF EXISTS zoho.ruecklaufquoten;
CREATE VIEW zoho.ruecklaufquoten AS
--alle respondent ids mit datum und befragungstyp
with respondents AS (
SELECT 	survey_respondents.id, 
		survey_respondents.start_date, 
		survey_surveys.name
	FROM zoho.survey_respondents
	JOIN zoho.survey_surveys
		ON survey_respondents.survey_id = survey_surveys.id),
--alle jahr/monat mit anzahl der ausgefüllten und befragungstyp
antworten AS (
SELECT 	COUNT(id) as ausgefuellt, 
		name,
		to_char(CAST(start_date as date), 'YYYY-MM') as monat 
	FROM respondents
	GROUP BY monat, name
	ORDER BY monat DESC, name ASC),
--alle jahr/monat mit anzahl der gesendeten und befragungstyp
gesendet AS (
SELECT 	COUNT(app_item_id) as anzahl,
		to_char((CAST(sende_datum as json)->>'start_date')::date, 'YYYY-MM') as monat,
		CAST(json_surveydetails as json)->>'SurveyType' as typ
	FROM podio.evaluation_survey
	WHERE CAST(status as json)->>'text' = 'Gesendet'
	GROUP BY monat, typ
	ORDER BY monat DESC, typ ASC)
--join antworten und gesendete
SELECT 	gesendet.monat as jahr_monat,
		gesendet.typ as befragungstyp,
		COALESCE(antworten.ausgefuellt, 0) as ausgefuellt,
		gesendet.anzahl as versendet
	FROM antworten
	RIGHT JOIN gesendet
		ON antworten.monat = gesendet.monat AND antworten.name = gesendet.typ
	ORDER BY gesendet.monat DESC, typ;