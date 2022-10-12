-- CREATE TRIGGER FUNCTION
CREATE OR REPLACE FUNCTION lead_tracking.update_kontakt_annahme()
RETURNS trigger AS
    $BODY$
    BEGIN


    -- DELETE TABLE
    DELETE FROM lead_tracking.kontakt_annahme
	WHERE app_item_id IN (SELECT app_item_id FROM lead_tracking.podio_kontakt_annahmen
			WHERE last_event_on > (SELECT max(last_event_on) FROM lead_tracking.kontakt_annahme));
    -- CREATE TABLE
    INSERT INTO lead_tracking.kontakt_annahme
	SELECT app_item_id,
 		cast(kontakt AS JSON) ->> 'app_item_id' AS kontakt_id,
 		cast(leads AS JSON) ->> 'app_item_id' AS lead_id,
 		cast(eingegangen_um AS JSON) ->> 'start_date' AS eingangsdatum,
 		cast(lead_owner AS JSON) ->> 'name' AS lead_besitzer,
 		cast(aktion AS JSON) ->> 'text' AS anfrage_status,
 		cast(unqualifiziert_detail AS JSON) ->> 'text' AS unqualifiziert_detail,
 		cast(art_der_anfrage AS JSON) ->> 'text' AS herkunft,
 		cast(account_art AS JSON) ->> 'text' AS account_art,
 		email,
 		calculation_2 AS telefon,
 		last_event_on
	FROM lead_tracking.podio_kontakt_annahme
	WHERE (last_event_on > (SELECT max(last_event_on) FROM lead_tracking.kontakt_annahme) OR app_item_id NOT IN (SELECT app_item_id FROM lead_tracking.kontakt_annahme));

    RETURN NULL;
    END;

    $BODY$
LANGUAGE plpgsql;

-- DROP TRIGGER
DROP TRIGGER IF EXISTS trig_update_kontakt_annahme ON lead_tracking.podio_kontakt_annahme;

-- CREATE TRIGGER for UPDATE FUNCTION
CREATE TRIGGER trig_update_kontakt_annahme
    AFTER INSERT OR UPDATE ON lead_tracking.podio_kontakt_annahme
    FOR EACH STATEMENT
    EXECUTE PROCEDURE lead_tracking.update_kontakt_annahme();