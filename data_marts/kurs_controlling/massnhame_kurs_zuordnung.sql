-- create table with kurses added to corresponding massnahmen
CREATE TABLE lehrgangs_controlling.massnhame_kurs_zuordnung AS
WITH temptable AS (
         SELECT massnahmen_organisation_courses.app_item_id,
            massnahmen_organisation_courses.app_item_id_formatted AS massnahmen_id_qm,
            massnahmen_organisation_courses.titel AS massnahmen_titel,
            json_array_elements((massnahmen_organisation_courses.json_coursedetails_new::json -> 0) -> 'Komponenten'::text) AS lehrgangsdetails,
	 		 CONCAT('CRSE', massnahmen_organisation_courses.courses_sales_management::json ->> 'app_item_id') as massnahmen_id
           FROM podio.massnahmen_organisation_courses
        ), temptable_2 AS (
         SELECT temptable.app_item_id,
			temptable.massnahmen_id_qm,
            temptable.massnahmen_id,
            temptable.massnahmen_titel,
            temptable.lehrgangsdetails ->> 'Titel'::text AS lehrgang_titel,
            (temptable.lehrgangsdetails ->> 'fmtCmpId'::text)::integer AS lehrgang_id,
            temptable.lehrgangsdetails ->> 'roleTitle'::text AS lehrgang_fachbereich,
            (temptable.lehrgangsdetails ->> 'Dauer'::text)::double precision AS lehrgang_dauer_in_wochen,
            row_number() OVER (PARTITION BY temptable.app_item_id) AS lehrgang_reihenfolge
           FROM temptable
        )
 SELECT temptable_2.app_item_id,
 	temptable_2.massnahmen_id_qm,
    temptable_2.massnahmen_id,
    temptable_2.massnahmen_titel,
    temptable_2.lehrgang_titel,
    temptable_2.lehrgang_id,
    temptable_2.lehrgang_fachbereich,
    temptable_2.lehrgang_dauer_in_wochen,
    temptable_2.lehrgang_reihenfolge,
    sum(temptable_2.lehrgang_dauer_in_wochen) OVER (PARTITION BY temptable_2.app_item_id ORDER BY temptable_2.lehrgang_reihenfolge) AS lehrgang_dauer_in_wochen_sum
   FROM temptable_2;
   
-- Set indices
ALTER TABLE lehrgangs_controlling.massnhame_kurs_zuordnung ADD COLUMN id SERIAL PRIMARY KEY;
CREATE INDEX ON lehrgangs_controlling.massnhame_kurs_zuordnung (massnahmen_id);
CREATE INDEX ON lehrgangs_controlling.massnhame_kurs_zuordnung (massnahmen_id_qm);
CREATE INDEX ON lehrgangs_controlling.massnhame_kurs_zuordnung (lehrgang_id);


-- Set forgein constraints
ALTER TABLE lehrgangs_controlling.massnhame_kurs_zuordnung
ADD CONSTRAINT fk_massnahme
FOREIGN KEY (massnahmen_id_qm)
REFERENCES lehrgangs_controlling.massnahmen (massnahmen_id);

ALTER TABLE lehrgangs_controlling.massnhame_kurs_zuordnung
ADD CONSTRAINT fk_lehrgang
FOREIGN KEY (lehrgang_id)
REFERENCES lehrgangs_controlling.kurse (lehrgang_id);
