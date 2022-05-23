-- CREATE TRIGGER FUNCTION
CREATE OR REPLACE FUNCTION kc.upsert_massnahme_kurse()
RETURNS trigger AS
    $BODY$
    BEGIN


    -- DELETE conflicts
    DELETE FROM kc.massnahme_kurs_zuordnung
    WHERE massnahmen_id_sales IN (SELECT app_item_id_formatted FROM podio.sales_management_courses 
            WHERE last_event_on > (SELECT max(last_event_on) FROM kc.massnahme_kurs_zuordnung)
            );
    -- UPSERT of newer entries
    INSERT INTO kc.massnahme_kurs_zuordnung
   WITH temptable AS
	(SELECT app_item_id_formatted AS massnahmen_id_sales,
			titel AS massnahme_titel,
			json_array_elements(json_formnplanning::JSON->'CmpDetails') AS lehrgangsdetails,
			last_event_on
		FROM podio.sales_management_courses)
SELECT	massnahmen_id_sales,
		massnahme_titel,
		(lehrgangsdetails::JSON->>'CmpID')::integer AS kurs_id,
		lehrgangsdetails::JSON->>'Component' AS kurs_titel,
		last_event_on
	FROM temptable
   WHERE  (last_event_on > (SELECT max(last_event_on) FROM kc.massnahme_kurs_zuordnung)	
            OR massnahmen_id_sales NOT IN (SELECT massnahmen_id_sales FROM kc.massnahme_kurs_zuordnung))

    ON CONFLICT (massnahmen_id_sales, kurs_id)
    DO NOTHING;

    RETURN NULL;
    END;

    $BODY$
LANGUAGE plpgsql;

-- DROP TRIGGER
DROP TRIGGER IF EXISTS trig_upsert_massnahme_kurse ON podio.massnahmen_organisation_courses;

-- CREATE TRIGGER for UPDATE FUNCTION
CREATE TRIGGER trig_upsert_massnahme_kurse
    AFTER INSERT OR UPDATE ON podio.massnahmen_organisation_courses
    FOR EACH STATEMENT
    EXECUTE PROCEDURE 
	kc.upsert_massnahme_kurse();