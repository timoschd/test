-- create table with kurses added to corresponding massnahmen
CREATE TABLE kc.massnahme_kurs_zuordnung AS
WITH temptable AS (
         SELECT massnahmen_organisation_courses.app_item_id,
            massnahmen_organisation_courses.app_item_id_formatted AS massnahmen_id_qm,
            massnahmen_organisation_courses.titel AS massnahmen_titel,
            json_array_elements((massnahmen_organisation_courses.json_coursedetails_new::json -> 0) -> 'Komponenten'::text) AS lehrgangsdetails,
			massnahmen_organisation_courses.courses_sales_management::json ->> 'app_item_id' as massnahmen_id_sales_raw,
            last_event_on
            FROM podio.massnahmen_organisation_courses
        ), temptable_2 AS (
         SELECT temptable.app_item_id,
			temptable.massnahmen_id_qm,
            CASE WHEN LENGTH(massnahmen_id_sales_raw) > 3
				THEN CONCAT('CRSE', massnahmen_id_sales_raw) 
				ELSE CONCAT('CRSE0', massnahmen_id_sales_raw)
			END as massnahmen_id_sales,
            temptable.massnahmen_titel,
            temptable.lehrgangsdetails ->> 'Titel'::text AS kurs_titel,
            (temptable.lehrgangsdetails ->> 'fmtCmpId'::text)::integer AS kurs_id,
            temptable.lehrgangsdetails ->> 'roleTitle'::text AS kurs_fachbereich,
            (temptable.lehrgangsdetails ->> 'Dauer'::text)::double precision AS kurs_dauer_in_wochen,
            row_number() OVER (PARTITION BY temptable.app_item_id) AS kurs_reihenfolge,
            temptable.last_event_on
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
   sum(temptable_2.kurs_dauer_in_wochen) OVER (PARTITION BY temptable_2.app_item_id ORDER BY temptable_2.kurs_reihenfolge) AS kurs_dauer_in_wochen_cumsum,
   temptable_2.last_event_on
   FROM temptable_2;
   
-- Set indices
ALTER TABLE kc.massnahme_kurs_zuordnung ADD PRIMARY KEY (massnahmen_id_sales, kurs_id);
CREATE INDEX ON kc.massnahme_kurs_zuordnung (massnahmen_id_sales);
CREATE INDEX ON kc.massnahme_kurs_zuordnung (massnahmen_id_qm);
CREATE INDEX ON kc.massnahme_kurs_zuordnung (kurs_id);


-- Set forgein constraints
ALTER TABLE kc.massnahme_kurs_zuordnung
ADD CONSTRAINT fk_massnahme
FOREIGN KEY (massnahmen_id_sales)
REFERENCES kc.massnahmen (massnahmen_id_sales)
DEFERRABLE INITIALLY DEFERRED;

ALTER TABLE kc.massnahme_kurs_zuordnung
ADD CONSTRAINT fk_kurs
FOREIGN KEY (kurs_id)
REFERENCES kc.kurse (kurs_id)
DEFERRABLE INITIALLY DEFERRED;

-- Set table owner
ALTER TABLE kc.massnahme_kurs_zuordnung OWNER TO read_only;

