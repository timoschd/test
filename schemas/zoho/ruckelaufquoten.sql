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
SELECT 	COUNT(DISTINCT respondent_id) as ausgefuellt, 
		survey_name,
		to_char(CAST(datum_spalte as date), 'YYYY-MM') as monat 
	FROM zoho.evaluationen
	GROUP BY monat, survey_name
	ORDER BY monat DESC, survey_name ASC),
--alle jahr/monat mit anzahl der gesendeten und befragungstyp
gesendet AS (
SELECT 	COUNT(app_item_id) as anzahl,
		to_char((CAST(sende_datum as json)->>'start_date')::date, 'YYYY-MM') as monat,
		CAST(json_surveydetails as json)->>'SurveyType' as typ
	FROM podio.evaluation_survey
	WHERE CAST(status as json)->>'text' = 'Gesendet'
	GROUP BY monat, typ
	ORDER BY monat DESC, typ ASC),
--alle jahr/monat mit anzahl der zu sendenden und befragungstyp
naechste_2 AS (
SELECT 	COUNT(app_item_id) as anzahl,
		to_char((CAST(sende_datum as json)->>'start_date')::date, 'YYYY-MM') as monat,
		CAST(json_surveydetails as json)->>'SurveyType' as typ
	FROM podio.evaluation_survey
	WHERE (CAST(status as json)->>'text' = 'Erstellt' OR CAST(status as json)->>'text' = 'Senden') 
	GROUP BY monat, typ
	ORDER BY monat DESC, typ ASC),
--join antworten und gesendete
join_antworten AS (
SELECT 	gesendet.monat as jahr_monat,
		gesendet.typ as befragungstyp,
		COALESCE(antworten.ausgefuellt, 0) as ausgefuellt,
		gesendet.anzahl as versendet
	FROM antworten
	RIGHT JOIN gesendet
		ON antworten.monat = gesendet.monat AND antworten.survey_name = gesendet.typ
	ORDER BY gesendet.monat DESC, typ),
--join nächste monate dazu
join_naechste AS (
SELECT 	join_antworten.jahr_monat,
		join_antworten.befragungstyp,
		join_antworten.ausgefuellt,
		join_antworten.versendet,
		naechste_2.anzahl,
		naechste_2.monat,
		naechste_2.typ
	FROM join_antworten
	FULL JOIN naechste_2
	ON join_antworten.jahr_monat = naechste_2.monat AND join_antworten.befragungstyp = naechste_2.typ
)
SELECT 	CONCAT(COALESCE(jahr_monat, monat),'-28') as jahr_monat,
		COALESCE(befragungstyp, typ) as befragungstyp,
		ausgefuellt,
		COALESCE(versendet, 0) as versendet,
		COALESCE(anzahl, 0) as zu_versenden
	FROM join_naechste
	ORDER BY jahr_monat, befragungstyp;
	
ALTER TABLE zoho.ruecklaufquoten 
	OWNER TO read_only;