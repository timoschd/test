-- CREATE TRIGGER FUNCTION
CREATE OR REPLACE FUNCTION kc.upsert_kurse()
RETURNS trigger AS
    $BODY$
    BEGIN


    -- DELETE conflicts
    DELETE FROM kc.kurse
    WHERE kurs_id_qm IN (SELECT app_item_id AS kurs_id_qm FROM podio.qs_qm_lehrgange 
            WHERE last_event_on > (SELECT max(last_event_on) FROM kc.teilnehmer)
            );
    -- UPSERT of newer entries
    INSERT INTO kc.teilnehmer
    SELECT qs_qm_lehrgange.app_item_id AS kurs_id_qm,
      qs_qm_lehrgange.fulfillment_components_id_2::numeric::integer AS kurs_id,
      qs_qm_lehrgange.titel_3 AS kurs_titel,
      qs_qm_lehrgange.fachgruppe::json ->> 'text'::text AS kurs_fachgruppe,
      qs_qm_lehrgange.fachbereich_2 AS kurs_fachbereich,
      qs_qm_lehrgange.prufung::json ->> 'text'::text AS kurs_prufung_art,
      qs_qm_lehrgange.prufung_extern::json ->> 'text'::text AS kurs_prufung_externe_einrichtung,
      qs_qm_lehrgange.prufungsgebuhr::numeric AS lehrgang_prufung_preis,
      (qs_qm_lehrgange.aktiv_gultig_ab_2::json ->> 'start_date'::text)::date AS kurs_gueltig_ab,
      (qs_qm_lehrgange.aktiv_gultig_bis_2::json ->> 'start_date'::text)::date AS kurs_gueltig_bis,
      qs_qm_lehrgange.produktion::json ->> 'text'::text AS kurs_produktion,
      qs_qm_lehrgange.dauer_in_wochen::numeric as kurs_dauer_in_wochen,
      qs_qm_lehrgange.tutorienzeit_gesamt_2::numeric AS kurs_tutorienzeit_pro_woche,
      qs_qm_lehrgange.lerngruppenzeit_gesamt_2::numeric AS kurs_lerngruppenzeit_pro_woche,
      qs_qm_lehrgange.onboardingzeit_gesamt::numeric AS kurs_onboardingzeit_pro_woche,
      qs_qm_lehrgange.prufungsvorbereitungszeit_gesamt::numeric AS kurs_prufungsvorbereitungszeit_pro_woche,
      last_event_on
     FROM podio.qs_qm_lehrgange
        WHERE qs_qm_lehrgange.app_item_id <> 453
            AND (last_event_on > (SELECT max(last_event_on) FROM kc.kurse)	OR app_item_id NOT IN (SELECT kurs_id_qm FROM kc.kurse))

    ON CONFLICT (kurs_id_qm)
    DO NOTHING;

    RETURN NULL;
    END;

    $BODY$
LANGUAGE plpgsql;


-- DROP TRIGGER
DROP TRIGGER IF EXISTS trig_upsert_kurse ON podio.qs_qm_lehrgange;

-- CREATE TRIGGER for UPDATE FUNCTION
CREATE TRIGGER trig_upsert_kurse
    AFTER INSERT OR UPDATE ON podio.qs_qm_lehrgange
    FOR EACH STATEMENT
    EXECUTE PROCEDURE kc.upsert_kurse();