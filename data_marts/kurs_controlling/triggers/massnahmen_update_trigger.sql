-- CREATE TRIGGER FUNCTION
CREATE OR REPLACE FUNCTION kc.upsert_massnahmen()
RETURNS trigger AS
    $BODY$
    BEGIN


    -- DELETE conflicts
    DELETE FROM kc.massnahmen
    WHERE massnahmen_id IN (SELECT app_item_id AS massnahmen_id FROM podio.massnahmen_organisation_courses 
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
            WHERE (last_event_on > (SELECT max(last_event_on) FROM kc.massnahmen)	OR app_item_id NOT IN (SELECT massnahmen_id FROM kc.massnahmen))

    ON CONFLICT (massnahmen_id)
    DO NOTHING;

    RETURN NULL;
    END;

    $BODY$
LANGUAGE plpgsql;

--function for upsert massnahmen and massnahmen_kruse
CREATE OR REPLACE FUNCTION kc.upsert_massnahme_and_massnahmen_kurse()
RETURNS trigger AS
    $BODY$
    BEGIN
	perform upsert_massnahmen();
	perform upsert_massnahme_kurse();
    RETURN NULL;
    END;

    $BODY$
LANGUAGE plpgsql;


-- DROP TRIGGER
DROP TRIGGER IF EXISTS trig_upsert_massnahmen ON podio.massnahmen_organisation_courses;

-- CREATE TRIGGER for UPDATE FUNCTION
CREATE TRIGGER trig_upsert_massnahmen_and_massnahmen_kurse
    AFTER INSERT OR UPDATE ON podio.massnahmen_organisation_courses
    FOR EACH STATEMENT
    EXECUTE PROCEDURE 
	kc.upsert_massnahme_and_massnahmen_kurse();