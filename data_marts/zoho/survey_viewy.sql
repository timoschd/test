DROP VIEW IF EXISTS zoho.survey_view; 
CREATE VIEW zoho.survey_view AS
WITH fragen AS (
SELECT 	survey_surveys.name, 
		survey_surveys.id as s_id,
		survey_questions.text,
		survey_questions.type,
		survey_questions.id as q_id
	FROM zoho.survey_surveys
	RIGHT JOIN zoho.survey_questions ON survey_surveys.id = cast(survey_questions.survey_id as bigint)),
fragen_antworten AS (
SELECT 	fragen.name,
		fragen.s_id,
		fragen.text,
		fragen.type,
		fragen.q_id,
		coalesce(survey_responses.option, survey_responses.text) as antwort,
		survey_responses.respondent_id
	FROM fragen
	RIGHT JOIN zoho.survey_responses ON fragen.q_id = cast(survey_responses.question_id as bigint))
SELECT 	fragen_antworten.name as befragung_typ,
		fragen_antworten.s_id::bigint as befragung_id,
		fragen_antworten.text as frage,
		fragen_antworten.type as fragentyp,
		fragen_antworten.q_id::bigint as frage_id,
		fragen_antworten.antwort,
		fragen_antworten.respondent_id::bigint as befragten_id,
		survey_respondents.end_date::date as datum,
		survey_respondents.time_taken::numeric as antwortzeit
		FROM fragen_antworten
		LEFT JOIN zoho.survey_respondents ON fragen_antworten.respondent_id = survey_respondents.id;

ALTER TABLE zoho.survey_view OWNER TO read_only;