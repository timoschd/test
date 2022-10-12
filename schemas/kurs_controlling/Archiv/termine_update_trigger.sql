-- CREATE TRIGGER FUNCTION
CREATE OR REPLACE FUNCTION kc.upsert_termine()
RETURNS trigger AS
    $BODY$
    BEGIN


    -- DELETE conflicts
    DELETE FROM kc.termine
    WHERE app_item_id IN (SELECT app_item_id AS termin_id FROM podio.qs_terminmanagement 
            WHERE last_event_on > (SELECT max(last_event_on) FROM kc.termine)
            );
    -- UPSERT of newer entries
    INSERT INTO kc.termine
    SELECT qs_terminmanagement.app_item_id,
    qs_terminmanagement.tutoriengruppen_id::numeric AS termin_id,
    qs_terminmanagement.terminart::json ->> 'text'::text AS termin_terminart,
    qs_terminmanagement.statuswert AS termin_status,
    (qs_terminmanagement.json_terminmanagement::json -> 0) ->> 'Dozent'::text AS dozent_name,
    unnest(string_to_array(qs_terminmanagement.dozenteninformationen_id_dozentseminarhelfer, ','::text))::integer AS dozent_id_qm,
    unnest(string_to_array(qs_terminmanagement.ffmt_cmt_id, ','::text))::integer AS lehrgang_id,
	(fulfillment_component_2::json ->> 'app_item_id')::int as kurs_id_qm,
    qs_terminmanagement.anzahl_teilnehmer::numeric AS termin_anzahl_teilnehmer,
    (qs_terminmanagement.gultig_ab::json ->> 'start_date'::text)::date AS termin_gultig_ab,
    (qs_terminmanagement.gultig_bis::json ->> 'start_date'::text)::date AS termin_gultig_bis,
    last_event_on
FROM podio.qs_terminmanagement
WHERE (last_event_on > (SELECT max(last_event_on) FROM kc.termine)	OR app_item_id NOT IN (SELECT termin_id FROM kc.termine));

    RETURN NULL;
    END;

    $BODY$
LANGUAGE plpgsql;


-- DROP TRIGGER
DROP TRIGGER IF EXISTS trig_upsert_termine ON podio.qs_terminmanagement;

-- CREATE TRIGGER for UPDATE FUNCTION 
CREATE TRIGGER trig_upsert_termine
    AFTER INSERT OR UPDATE ON podio.qs_terminmanagement
    FOR EACH STATEMENT
    EXECUTE PROCEDURE kc.upsert_termine();