-- CREATE TRIGGER FUNCTION
CREATE OR REPLACE FUNCTION tc.upsert_teilnehmer_kurs()
RETURNS trigger AS
    $BODY$
    BEGIN


    -- DELETE conflicts
    DELETE FROM tc.teilnehmer_kurs_zuordnung
    WHERE lehrgangs_details_id IN (SELECT app_item_id AS lehrgangs_details_id FROM podio.tutoren_lehrgangs_details
            WHERE last_event_on > (SELECT max(last_event_on) FROM tc.teilnehmer_kurs_zuordnung)
            );
    -- UPSERT of newer entries
    INSERT INTO tc.teilnehmer_kurs_zuordnung
    SELECT app_item_id as lehrgangs_details_id,
    (cast(json_report as json)->>'Id')::integer as teilnehmer_id_tutoren,
	calclehrgang as kurs_titel,
	fulfillment_components_id_3::integer as kurs_id_backoffice,
	fc_id_2::integer as kurs_id_qm_2,
	(cast(calculation_18 as json)->>'start_date')::date as startdatum,
	(cast(calculation_9 as json)->>'start_date')::date as enddatum,
	cast(status as json)->>'text' as status,
	(cast(abbruch_datum as json)->>'start_date')::date as abbruch_datum,
	(cast(tutor_2 as json)->>'app_item_id')::integer as tutor_id,
	cast(tutor_2 as json)->>'title' as tutor_name,
	last_event_on
FROM podio.tutoren_lehrgangs_details
WHERE (last_event_on > (SELECT max(last_event_on) FROM tc.teilnehmer_kurs_zuordnung)	OR app_item_id NOT IN (SELECT lehrgangs_details_id FROM tc.teilnehmer_kurs_zuordnung))
    AND (cast(json_report as json)->>'Id')::integer IN (SELECT teilnehmer_id_tutoren FROM tc.teilnehmer) -- do not use entries where there is no teilnehmer in tc.teilnehmer (teilnehmer table update gets triggered before)

    ON CONFLICT (lehrgangs_details_id) 
    DO NOTHING;

    RETURN NULL;
    END;

    $BODY$
LANGUAGE plpgsql;


-- DROP TRIGGER
DROP TRIGGER IF EXISTS trig_upsert_teilnehmer_kurs ON podio.tutoren_lehrgangs_details;

-- CREATE TRIGGER for UPDATE FUNCTION
CREATE TRIGGER trig_upsert_teilnehmer_kurs
    AFTER INSERT OR UPDATE ON podio.tutoren_lehrgangs_details
    FOR EACH STATEMENT
    EXECUTE PROCEDURE tc.upsert_teilnehmer_kurs();