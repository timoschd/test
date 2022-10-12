--Delete Table
DROP TABLE kc.dozenten;

--Create Table Dozenten
CREATE TABLE kc.dozenten (
	id integer,
	name text,
	vertragsstatus text,
	fachgruppe text,
	mail text,
	aktiv_ab date,
	aktiv_bis date,
	bearbeitet_am timestamp,
	gehalt_fix numeric,
	gehalt_stunde numeric,
	stunden numeric,
	podio_id integer);

-- insert old dozenten (form excel)
INSERT INTO kc.dozenten
SELECT 	dozenten_alt.dozent_id_qm::integer as id,
		dozenten_alt.dozent_name::text as name,
		dozenten_alt.dozent_vertragsstatus::text as vertragsstatus,
		dozenten_alt.dozent_fachgruppe::text as fachgruppe,
		dozenten_alt.mail::text as mail,
		dozenten_alt.dozent_gueltig_ab::date as aktiv_ab,
		dozenten_alt.dozent_gueltig_bis::date as aktiv_bis,
		dozenten_alt.last_event_on::timestamp as bearbeitet_am,
		dozenten_alt.dozent_gehalt_pro_monat::numeric as gehalt_fix,
		dozenten_alt.dozent_gehalt_pro_stunde::numeric as gehalt_stunde,
		dozenten_alt.dozent_stunden_pro_woche::numeric as stunden,
		(qs_dozenteninformationen.verbindung::json->>'app_item_id')::integer as podio_id
		FROM kc.dozenten_alt
		LEFT JOIN podio.qs_dozenteninformationen ON dozenten_alt.dozent_id_qm = qs_dozenteninformationen.app_item_id
		WHERE (dozent_gueltig_ab IS NOT NULL OR dozent_gueltig_bis IS NOT NULL)
			AND (dozent_gehalt_pro_monat IS NOT NULL OR dozent_gehalt_pro_stunde IS NOT NULL);
	
-- insert new dozenten (from personio)#
INSERT INTO kc.dozenten
SELECT 	mitarbeiterdaten.id::integer as id,
		CONCAT(mitarbeiterdaten.last_name, ', ',mitarbeiterdaten.first_name) as name,
		mitarbeiterdaten.beschäftigungsart::text as vertragsstatus,
		mitarbeiterdaten.fachgruppe::text as fachgruppe,
		mitarbeiterdaten.email::text as mail,
		mitarbeiterdaten.hire_date::date as aktiv_ab,
		mitarbeiterdaten.termination_date::date as aktiv_bis,
		mitarbeiterdaten.last_modified::timestamp as bearbeitet_am,
		mitarbeiterdaten.fix_salary::numeric as gehalt_fix,
		mitarbeiterdaten.hourly_salary::numeric as gehalt_stunde,
		NULL as stunden,
		(qs_dozenteninformationen.verbindung::json->>'app_item_id')::integer as podio_id
		FROM personio.mitarbeiterdaten
		LEFT JOIN podio.qs_dozenteninformationen ON mitarbeiterdaten.email = qs_dozenteninformationen.e_mail;


--lösche doppelte
DELETE FROM kc.dozenten WHERE id IN (64,115,135,99,17,129,108,84,27,110,134,101,151,62,9,152,95,39,132,88,90,157,74,68,24,131,77,154,1,139,104,63,18,33,105,26,137,107,19,98,30,128,7,93,117,169,11,149,120,142,140,133);

--update inaktive
UPDATE kc.dozenten SET aktiv_bis = '2021-01-30' WHERE id = 94;
UPDATE kc.dozenten SET aktiv_bis = '2021-10-13' WHERE id = 6;
UPDATE kc.dozenten SET aktiv_bis = '2022-01-30' WHERE id = 136;
UPDATE kc.dozenten SET aktiv_bis = '2021-11-08' WHERE id = 89;
UPDATE kc.dozenten SET aktiv_bis = '2022-02-27' WHERE id = 113;
UPDATE kc.dozenten SET aktiv_bis = '2021-01-09' WHERE id = 109;

-- set bearbeitet am falls leer
UPDATE kc.dozenten SET bearbeitet_am = '2022-01-01 00:00:00' WHERE bearbeitet_am IS NULL;

-- PRIMARY KEY
ALTER TABLE kc.dozenten ADD PRIMARY KEY (mail, aktiv_ab);

-- add cloumn id
ALTER TABLE kc.dozenten ADD COLUMN item_id SERIAL;

-- add rules for dozenten
ALTER TABLE kc.dozenten 
ADD CONSTRAINT dozenten_aktiv_ab
CHECK (aktiv_ab < cast(CURRENT_DATE + ('1 year'::interval * 1)as date) AND 
	   aktiv_ab > '2015-01-01'); 

ALTER TABLE kc.dozenten 
ADD CONSTRAINT dozenten_zeitraum
CHECK ((aktiv_ab <= aktiv_bis) OR aktiv_bis IS NULL);

ALTER TABLE kc.dozenten 
ADD CONSTRAINT dozenten_gehalt
CHECK (gehalt_fix <= 12000 AND gehalt_fix >=0);

ALTER TABLE kc.dozenten 
ADD CONSTRAINT dozenten_gehalt_stunde
CHECK (gehalt_stunde <= 150 AND gehalt_stunde >=0);

ALTER TABLE kc.dozenten 
ADD CONSTRAINT dozenten_stunden
CHECK (stunden <= 120 AND stunden >=0);



-- set owner to read_only
ALTER TABLE kc.dozenten OWNER to read_only;
