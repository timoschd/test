-- CREATE TRIGGER FUNCTION
CREATE OR REPLACE FUNCTION kc.upsert_massnahmen()
RETURNS void AS
    $BODY$
    BEGIN


    -- DELETE conflicts
    DELETE FROM kc.massnahmen
    WHERE massnahmen_id IN (SELECT app_item_id_formatted FROM podio.massnahmen_organisation_courses 
            WHERE last_event_on > (SELECT max(last_event_on) FROM kc.massnahmen)
            );
    -- UPSERT of newer entries
    INSERT INTO kc.massnahmen
    SELECT massnahmen_organisation_courses.app_item_id,
    massnahmen_organisation_courses.app_item_id_formatted AS massnahmen_id,
	CASE massnahmen_organisation_courses.app_item_id_formatted WHEN 'CRSE1294' THEN 'CRSE2551duplicate'
	ELSE concat('CRSE', massnahmen_organisation_courses.courses_sales_management::json ->> 'app_item_id'::text)
	END AS massnahmen_id_sales,
	massnahmen_organisation_courses.titel AS massnahmen_titel,
	massnahmen_organisation_courses.gesamt_status AS massnahme_status,
	massnahmen_organisation_courses.course_status AS erweiterter_status,
	massnahmen_organisation_courses.massnahmen_nr_2,
	massnahmen_organisation_courses.uw as wochen,
	massnahmen_organisation_courses.ue_2 as unterrichtseinheiten,
	massnahmen_organisation_courses.dkz_nummer,
	(massnahmen_organisation_courses.gultig_bis_2::json->>'start_date')::date as gueltig_bis,
	massnahmen_organisation_courses.calcgebuehren::numeric AS gebuehren,
	massnahmen_organisation_courses.massnahmenbogen_item_id::integer,
	massnahmen_organisation_courses.massnahmenbogen_titel,
	last_event_on	
  FROM podio.massnahmen_organisation_courses
            WHERE (last_event_on > (SELECT max(last_event_on) FROM kc.massnahmen)	OR app_item_id_formatted NOT IN (SELECT massnahmen_id FROM kc.massnahmen))

    ON CONFLICT (massnahmen_id)
    DO NOTHING;

    END;

    $BODY$
LANGUAGE plpgsql;

-- CREATE TRIGGER FUNCTION
CREATE OR REPLACE FUNCTION kc.upsert_massnahme_kurse()
RETURNS void AS
    $BODY$
    BEGIN


    -- DELETE conflicts
    DELETE FROM kc.massnahme_kurs_zuordnung
    WHERE app_item_id IN (SELECT app_item_id FROM podio.massnahmen_organisation_courses 
            WHERE last_event_on > (SELECT max(last_event_on) FROM kc.massnahme_kurs_zuordnung)
            );
    -- UPSERT of newer entries
    INSERT INTO kc.massnahme_kurs_zuordnung
    WITH temptable AS (
         SELECT massnahmen_organisation_courses.app_item_id,
            massnahmen_organisation_courses.app_item_id_formatted AS massnahmen_id_qm,
            massnahmen_organisation_courses.titel AS massnahmen_titel,
            json_array_elements((massnahmen_organisation_courses.json_coursedetails_new::json -> 0) -> 'Komponenten'::text) AS lehrgangsdetails,
            CONCAT('CRSE', massnahmen_organisation_courses.courses_sales_management::json ->> 'app_item_id') as massnahmen_id_sales,
            last_event_on
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
   FROM temptable_2
   WHERE  (last_event_on > (SELECT max(last_event_on) FROM kc.massnahme_kurs_zuordnung)	OR app_item_id NOT IN (SELECT app_item_id FROM kc.massnahme_kurs_zuordnung))

    ON CONFLICT (massnahmen_id_sales, kurs_id)
    DO NOTHING;

    END;

    $BODY$
LANGUAGE plpgsql;

--function for upsert massnahmen and massnahmen_kruse
CREATE OR REPLACE FUNCTION kc.upsert_massnahme_and_massnahmen_kurse()
RETURNS trigger AS
    $BODY$
    BEGIN
	perform kc.upsert_massnahmen();
	perform kc.upsert_massnahme_kurse();
    RETURN NULL;
    END;

    $BODY$
LANGUAGE plpgsql;


-- DROP TRIGGER
DROP TRIGGER IF EXISTS trig_upsert_massnahmen_and_massnahmen_kurse ON podio.massnahmen_organisation_courses;

-- CREATE TRIGGER for UPDATE FUNCTION
CREATE TRIGGER trig_upsert_massnahmen_and_massnahmen_kurse
    AFTER INSERT OR UPDATE ON podio.massnahmen_organisation_courses
    FOR EACH STATEMENT
    EXECUTE PROCEDURE 
	kc.upsert_massnahme_and_massnahmen_kurse();