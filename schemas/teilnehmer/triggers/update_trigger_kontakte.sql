-- CREATE TRIGGER FUNCTION
CREATE OR REPLACE FUNCTION tc.upsert_kontakte()
RETURNS trigger AS
    $BODY$
    BEGIN


    -- DELETE conflicts
    DELETE FROM tc.kontakte
    WHERE kontakt_id IN (SELECT app_item_id AS kontakt_id FROM podio.backoffice_kontakte
            WHERE last_event_on > (SELECT max(last_event_on) FROM tc.kontakte)
            );
    -- UPSERT of newer entries
    INSERT INTO tc.kontakte
    SELECT app_item_id AS kontakt_id,
	app_item_id_formatted AS kontakt_id_formatted,
	cast(anrede AS JSON)->>'text' AS anrede,
	extract(YEAR FROM (cast(geburtsdatum AS JSON)->>'start_date')::date) AS geburtsdatum,
	substring(anschrift, ('\w+$')) as land,
	(cast(json_address AS JSON)->>'PostalCode') AS plz,
	aktiver_lead::numeric AS aktive_leads,
	total_lead::numeric AS anzahl_leads,
	total_calls::numeric AS anzahl_anrufe,
	last_event_on
FROM podio.backoffice_kontakte
WHERE (last_event_on > (SELECT max(last_event_on) FROM tc.kontakte)	OR app_item_id NOT IN (SELECT kontakt_id FROM tc.kontakte))

    ON CONFLICT (kontakt_id) 
    DO NOTHING;

    RETURN NULL;
    END;

    $BODY$
LANGUAGE plpgsql;


-- DROP TRIGGER
DROP TRIGGER IF EXISTS trig_upsert_kontakte ON podio.backoffice_kontakte;

-- CREATE TRIGGER for UPDATE FUNCTION
CREATE TRIGGER trig_upsert_kontakte
    AFTER INSERT OR UPDATE ON podio.backoffice_kontakte
    FOR EACH STATEMENT
    EXECUTE PROCEDURE tc.upsert_kontakte();