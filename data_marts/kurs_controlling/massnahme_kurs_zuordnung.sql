-- create table with kurses added to corresponding massnahmen
CREATE TABLE kc.massnahme_kurs_zuordnung AS
WITH temptable AS (
         SELECT massnahmen_organisation_courses.app_item_id,
            massnahmen_organisation_courses.app_item_id_formatted AS massnahmen_id_qm,
            massnahmen_organisation_courses.titel AS massnahmen_titel,
            json_array_elements((massnahmen_organisation_courses.json_coursedetails_new::json -> 0) -> 'Komponenten'::text) AS lehrgangsdetails,
            CONCAT('CRSE', massnahmen_organisation_courses.courses_sales_management::json ->> 'app_item_id') as massnahmen_id_sales
            FROM podio.massnahmen_organisation_courses
        ), temptable_2 AS (
         SELECT temptable.app_item_id,
			temptable.massnahmen_id_qm,
            temptable.massnahmen_id_sales,
            temptable.massnahmen_titel,
            temptable.lehrgangsdetails ->> 'Titel'::text AS kurs_titel,
            (temptable.lehrgangsdetails ->> 'fmtCmpId'::text)::integer AS kurs_id,
            temptable.lehrgangsdetails ->> 'roleTitle'::text AS kurs_fachbereich,
            (temptable.lehrgangsdetails ->> 'Dauer'::text)::double precision AS kurs_dauer_in_wochen,
            row_number() OVER (PARTITION BY temptable.app_item_id) AS kurs_reihenfolge
            FROM temptable
        )
SELECT temptable_2.app_item_id,
   temptable_2.massnahmen_id_qm,
   temptable_2.massnahmen_id_sales,
   temptable_2.massnahmen_titel,
   temptable_2.kurs_titel,
   temptable_2.kurs_id,
   temptable_2.kurs_fachbereich,
   temptable_2.kurs_dauer_in_wochen,
   temptable_2.kurs_reihenfolge,
   sum(temptable_2.kurs_dauer_in_wochen) OVER (PARTITION BY temptable_2.app_item_id ORDER BY temptable_2.kurs_reihenfolge) AS kurs_dauer_in_wochen_cumsum
   FROM temptable_2
   WHERE kurs_id IN (SELECT kurs_id FROM kc.kurse);
   
-- Set indices
ALTER TABLE kc.massnahme_kurs_zuordnung ADD COLUMN id SERIAL PRIMARY KEY;
CREATE INDEX ON kc.massnahme_kurs_zuordnung (massnahmen_id_sales);
CREATE INDEX ON kc.massnahme_kurs_zuordnung (massnahmen_id_qm);
CREATE INDEX ON kc.massnahme_kurs_zuordnung (kurs_id);


-- Set forgein constraints
ALTER TABLE kc.massnahme_kurs_zuordnung
ADD CONSTRAINT fk_massnahme
FOREIGN KEY (massnahmen_id_sales)
REFERENCES kc.massnahmen (massnahmen_id_sales);

ALTER TABLE kc.massnahme_kurs_zuordnung
ADD CONSTRAINT fk_kurs
FOREIGN KEY (kurs_id)
REFERENCES kc.kurse (kurs_id);

-- Set table owner
ALTER TABLE kc.massnahme_kurs_zuordnung OWNER TO read_only;

