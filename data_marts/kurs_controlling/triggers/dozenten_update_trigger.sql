-- CREATE TRIGGER FUNCTION
CREATE OR REPLACE FUNCTION kc.upsert_dozenten()
RETURNS trigger AS
    $BODY$
    BEGIN


    -- DELETE conflicts
    DELETE FROM kc.dozenten
    WHERE dozent_id IN (SELECT app_item_id AS dozent_id_qm FROM podio.qs_dozenteninformationen 
            WHERE last_event_on > (SELECT max(last_event_on) FROM kc.dozenten)
            );
    -- UPSERT of newer entries
    INSERT INTO kc.dozenten
    SELECT qs_dozenteninformationen.app_item_id as dozent_id_qm,
    qs_dozenteninformationen.verbindung::json ->> 'title'::text AS dozent_name,
    qs_dozenteninformationen.dozenten_id::numeric::integer AS dozent_id,
    qs_dozenteninformationen.kategorien::json ->> 'text'::text AS dozent_vertragsstatus,
    qs_dozenteninformationen.fachgruppe::json ->> 'text'::text AS dozent_fachgruppe,
    (qs_dozenteninformationen.gultig_ab::json ->> 'start_date_utc'::text)::date AS dozent_gueltig_ab,
    (qs_dozenteninformationen.gultig_bis::json ->> 'start_date_utc'::text)::date AS dozent_gueltig_bis,
    qs_dozenteninformationen.teilnehmer_aktuell_2::numeric::integer AS dozent_anzahl_teilnehmer,
    qs_dozenteninformationen.stunden_fur_produktion::numeric AS dozent_stunden_fur_produktion_pro_woche,
    qs_dozenteninformationen.sonderaufgaben_in_stunden_pro_woche::numeric AS dozenten_sonderaufgaben_pro_woche,
    qs_dozenteninformationen.arbeitsstunden_pro_woche::numeric AS dozent_stunden_pro_woche,
    --qs_dozenteninformationen.gehalt_pro_stunde::numeric AS dozent_gehalt_pro_stunde,
    --qs_dozenteninformationen.gehalt_pro_monat::numeric AS dozent_gehalt_pro_monat,
    last_event_on
   FROM podio.qs_dozenteninformationen
            WHERE (last_event_on > (SELECT max(last_event_on) FROM kc.dozenten)	OR app_item_id NOT IN (SELECT dozent_id_qm FROM kc.dozenten));

    ON CONFLICT (dozent_id_qm)
    DO NOTHING;

    RETURN NULL;
    END;

    $BODY$
LANGUAGE plpgsql;


-- DROP TRIGGER
DROP TRIGGER IF EXISTS trig_upsert_dozenten ON podio.qs_dozenteninformationen;

-- CREATE TRIGGER for UPDATE FUNCTION
CREATE TRIGGER trig_upsert_dozenten
    AFTER INSERT OR UPDATE ON podio.qs_dozenteninformationen
    FOR EACH STATEMENT
    EXECUTE PROCEDURE kc.upsert_dozenten();