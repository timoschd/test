-- CREATE TRIGGER FUNCTION
CREATE OR REPLACE FUNCTION kc.upsert_massnahmen()
RETURNS trigger AS
    $BODY$
    BEGIN


    -- DELETE conflicts
    DELETE FROM kc.massnahmen
	--delete massnahmen courses
    WHERE massnahmen_id IN (SELECT app_item_id_formatted FROM podio.massnahmen_organisation_courses  
            WHERE last_event_on > (SELECT max(last_event_on) FROM kc.massnahmen))
			--delete sales courses
			OR massnahmen_id_sales IN (SELECT app_item_id_formatted FROM podio.sales_management_courses  
            WHERE last_event_on > (SELECT max(last_event_on_sales) FROM kc.massnahmen));
    -- UPSERT of newer entries
    INSERT INTO kc.massnahmen
    WITH massnahmen_sales AS
	(SELECT app_item_id AS massnahmen_id_sales_int, -- id ohne CRSE
 			app_item_id_formatted AS massnahmen_id_sales, -- formatted id (bisher in pbi als massnahmen_id_sales)
 			last_event_on AS last_event_on_sales
		FROM podio.sales_management_courses),
	massnahmen_organisation AS
	(SELECT massnahmen_organisation_courses.app_item_id,
			massnahmen_organisation_courses.app_item_id_formatted AS massnahmen_id, -- massnahmen id mit CRSE
 			(massnahmen_organisation_courses.courses_sales_management::JSON ->> 'app_item_id')::integer AS m_id_sales, -- sales massnahmen id für join
 			massnahmen_organisation_courses.titel AS massnahmen_titel,
			massnahmen_organisation_courses.gesamt_status AS massnahme_status,
			massnahmen_organisation_courses.course_status AS erweiterter_status,
			massnahmen_organisation_courses.massnahmen_nr_2,
			massnahmen_organisation_courses.uw AS wochen,
			massnahmen_organisation_courses.ue_2 AS unterrichtseinheiten,
			massnahmen_organisation_courses.dkz_nummer,
			(massnahmen_organisation_courses.gultig_bis_2::JSON ->> 'start_date')::date AS gueltig_bis,
			massnahmen_organisation_courses.calcgebuehren::numeric AS gebuehren,
			massnahmen_organisation_courses.massnahmenbogen_item_id::integer,
			massnahmen_organisation_courses.massnahmenbogen_titel,
			last_event_on
		FROM podio.massnahmen_organisation_courses)
        SELECT *
        FROM massnahmen_sales
        LEFT JOIN massnahmen_organisation ON massnahmen_sales.massnahmen_id_sales_int = massnahmen_organisation.m_id_sales
            WHERE (last_event_on_sales > (SELECT max(last_event_on_sales) FROM kc.massnahmen))	
				   OR (last_event_on > (SELECT max(last_event_on) FROM kc.massnahmen))
				   OR (massnahmen_id_sales NOT IN (SELECT massnahmen_id_sales FROM kc.massnahmen))

    ON CONFLICT (massnahmen_id_sales)
    DO NOTHING;

    END;

    $BODY$
LANGUAGE plpgsql;

-- DROP TRIGGER
DROP TRIGGER IF EXISTS trig_upsert_massnahmen_sales ON podio.sales_management_courses;
DROP TRIGGER IF EXISTS trig_upsert_massnahmen_organisation ON podio.massnahmen_organisation_courses;

-- CREATE TRIGGER for UPDATE FUNCTION
CREATE TRIGGER trig_upsert_massnahmen_sales
    AFTER INSERT OR UPDATE ON podio.sales_management_courses
    FOR EACH STATEMENT
    EXECUTE PROCEDURE 
	kc.upsert_massnahmen();
	
CREATE TRIGGER trig_upsert_massnahmen_organisation
    AFTER INSERT OR UPDATE ON podio.massnahmen_organisation_courses
    FOR EACH STATEMENT
    EXECUTE PROCEDURE 
	kc.upsert_massnahmen();