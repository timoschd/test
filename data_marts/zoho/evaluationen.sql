-- Set OWNER to read_only
ALTER TABLE zoho.survey_collectors OWNER TO read_only;
ALTER TABLE zoho.survey_fields OWNER TO read_only;
ALTER TABLE zoho.survey_surveys OWNER TO read_only;
ALTER TABLE zoho.survey_pages OWNER TO read_only;
ALTER TABLE zoho.survey_questions OWNER TO read_only;
ALTER TABLE zoho.survey_respondents OWNER TO read_only;
ALTER TABLE zoho.survey_responses OWNER TO read_only;

--Delete view if exists and create new
DROP VIEW IF EXISTS zoho.evaluationen;
CREATE VIEW zoho.evaluationen AS
-- temptables für alle nötigen tabellen mit allen benötigten spalten
WITH questions AS (
SELECT 	id::bigint as q_id,
		type,
		text,
		page_id::bigint,
		survey_id::bigint,
		mandatory_enabled
	FROM zoho.survey_questions),
pages AS (
SELECT 	id::bigint as p_id,
		title,
		survey_id::bigint
	FROM zoho.survey_pages),
surveys AS (
SELECT 	id::bigint as s_id,
		name
	FROM zoho.survey_surveys),
collectors AS (
SELECT 	id::bigint as c_id,
		name,
		survey_id::bigint
	FROM zoho.survey_collectors),
responses AS (
SELECT 	respondent_id::bigint,
		question_id::bigint,
		survey_id::bigint,
		page_id::bigint,
		(CASE WHEN text = '' THEN NULL ELSE text END) as text,
		(CASE WHEN option = '' THEN NULL ELSE option END) as option
	FROM zoho.survey_responses),
respondents AS (
SELECT 	id::bigint as respondent_id,
		collector_id::bigint,
		survey_id::bigint,
		status,
		end_date::date as published_date,
		time_taken_in_minutes::numeric
	FROM zoho.survey_respondents),
--lehrgangs_details_id
details_id AS (
SELECT 	respondent_id,
		text as details_id
	FROM responses
	WHERE question_id IN (64151000000988059, 64151000000738307, 64151000000730429, 64151000000739907, 64151000000741699)),
-- extract vorname von respondent
vorname AS (
SELECT text, respondent_id, survey_id FROM zoho.survey_responses WHERE field_id::bigint = 64151000000754465 AND question_id::bigint = 64151000000754463
),
-- extract nachname von respondent
nachname AS (
SELECT text, respondent_id FROM zoho.survey_responses WHERE field_id::bigint = 64151000000754467 AND question_id::bigint = 64151000000754463
),
-- concat vor und nachname
dozent AS (
SELECT 	CONCAT(vorname.text,' ', nachname.text) as dozent_name, 
		vorname.respondent_id,
		vorname.survey_id
	FROM vorname 
	JOIN nachname ON vorname.respondent_id = nachname.respondent_id),
-- temptables join fragen an befragung
colectors_join_survey AS (	
SELECT 	collectors.c_id,
		collectors.survey_id,
		surveys.name
	FROM collectors
	FULL JOIN surveys ON collectors.survey_id = surveys.s_id),
survey_join_page AS (
SELECT 	colectors_join_survey.c_id,
		colectors_join_survey.survey_id,
		colectors_join_survey.name,
		pages.p_id,
		pages.title
	FROM colectors_join_survey
	FULL JOIN pages ON colectors_join_survey.survey_id = pages.survey_id),
survey_join_questions AS (
SELECT 	survey_join_page.c_id as collector_id,
		survey_join_page.survey_id,
		survey_join_page.name as survey_name,
		survey_join_page.p_id as page_id,
		survey_join_page.title as page_title,
		questions.q_id as question_id,
		questions.type as question_type,
		questions.text as question,
		mandatory_enabled as question_pflicht
	FROM survey_join_page
	FULL JOIN questions ON survey_join_page.survey_id = questions.survey_id AND survey_join_page.p_id = questions.page_id),
-- join antworten
antworten AS (
SELECT 	responses.respondent_id,
		responses.question_id,
		responses.survey_id,
		responses.page_id,
		responses.text,
		responses.option,
		respondents.collector_id,
		respondents.status,
		respondents.published_date,
		respondents.time_taken_in_minutes
	FROM responses
	FULL JOIN respondents ON responses.respondent_id = respondents.respondent_id AND responses.survey_id = respondents.survey_id),
-- join fragen und antworten
fragen_join_antworten AS (
SELECT 	survey_join_questions.collector_id,
		survey_join_questions.survey_id,
		survey_join_questions.survey_name,
		survey_join_questions.page_id,
		survey_join_questions.page_title,
		survey_join_questions.question_id,
		survey_join_questions.question_type,
		survey_join_questions.question,
		survey_join_questions.question_pflicht,
		antworten.respondent_id,
		COALESCE(antworten.option, antworten.text) as antwort,
		antworten.status,
		antworten.published_date,
		antworten.time_taken_in_minutes,
		antworten.published_date as datum_spalte
	FROM survey_join_questions
	FULL JOIN antworten ON survey_join_questions.question_id = antworten.question_id 
						AND survey_join_questions.page_id = antworten.page_id 
						AND survey_join_questions.survey_id = antworten.survey_id 
						AND survey_join_questions.collector_id = antworten.collector_id),
-- select all from join mit lehrgangs details id
all_join_details AS (
SELECT 	fragen_join_antworten.collector_id,
		fragen_join_antworten.survey_id,
		fragen_join_antworten.survey_name,
		fragen_join_antworten.page_id,
		fragen_join_antworten.page_title,
		fragen_join_antworten.question_id,
		fragen_join_antworten.question_type,
		fragen_join_antworten.question,
		fragen_join_antworten.question_pflicht,
		fragen_join_antworten.respondent_id,
		fragen_join_antworten.antwort,
		fragen_join_antworten.status,
		fragen_join_antworten.published_date,
		fragen_join_antworten.time_taken_in_minutes,
		fragen_join_antworten.datum_spalte,
		details_id.details_id
	FROM fragen_join_antworten
	LEFT JOIN details_id ON fragen_join_antworten.respondent_id = details_id.respondent_id)
SELECT 	all_join_details.*,
		dozent.dozent_name
	FROM all_join_details
	LEFT JOIN dozent ON all_join_details.respondent_id = dozent.respondent_id AND all_join_details.survey_id = dozent.survey_id
	ORDER BY collector_id, survey_id, page_id, question_id;

--setze owner to read_only
ALTER TABLE zoho.evaluationen OWNER TO read_only;


