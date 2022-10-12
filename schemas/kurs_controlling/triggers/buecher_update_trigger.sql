-- CREATE TRIGGER FUNCTION
CREATE OR REPLACE FUNCTION kc.upsert_buecher()
RETURNS trigger AS
    $BODY$
    BEGIN


    -- DELETE conflicts
    DELETE FROM kc.buecher_kurs_zuordnung
    WHERE buch_id_qm IN (SELECT app_item_id AS buch_id_qm FROM podio.qs_bucherliste 
            WHERE last_event_on > (SELECT max(last_event_on) FROM kc.buecher_kurs_zuordnung)
            );
    -- UPSERT of newer entries
    INSERT INTO kc.buecher_kurs_zuordnung
    SELECT
	app_item_id as buch_id_qm,
	item_id as buch_id,
	titel as buch_titel,
	lgb_title as lgb_titel,
	kategorien->>'text' as kategorie,
	cast(json_book as json)->>'author' as autor,
	(auflage_2::numeric)::integer as auflage,
	(jahr_2::numeric)::integer as jahr,
	isbn_2 as isbn,
	kosten_fachliteratur::numeric as buch_kosten,
	(cast(gultig_ab as json)->>'start_date')::date as buch_gultig_ab,
	(cast(gultig_bis as json)->>'start_date')::date as buch_gultig_bis,
	unnest(string_to_array(qm_ffmt_cmt_ids,','::text))::integer as kurs_id_qm,
    (fulfillment_components_id::numeric)::integer as kurs_id_boffice,
	lizenzkosten as buch_lizenzkosten,--kein cast auf nummeric möglich -> bsp:(730,00€ zzgl. MwSt.), buch_nr: 474
	(cast(lizenz_gultigkeit as json)->>'start_date')::date as lizenz_gueltig_ab,
	(cast(lizenz_gultig_bis as json)->>'start_date')::date as lizenz_gueltig_bis,
	cast(lizenzbereiche as json)->>'text' as lizenzbereiche,
	cast(lizenzart as json)->>'text' as lizenzart,
	lizenz_anmerkung as anmerkungen_zur_lizenz,
	last_event_on
FROM podio.qs_bucherliste
            WHERE (last_event_on > (SELECT max(last_event_on) FROM kc.buecher_kurs_zuordnung)	OR app_item_id NOT IN (SELECT buch_id_qm FROM kc.buecher_kurs_zuordnung))
            AND app_item_id NOT IN (986)

    ON CONFLICT (buch_id_qm, kurs_id_qm)
    DO NOTHING;

    RETURN NULL;
    END;

    $BODY$
LANGUAGE plpgsql;


-- DROP TRIGGER
DROP TRIGGER IF EXISTS trig_upsert_buecher ON podio.qs_bucherliste;

-- CREATE TRIGGER for UPDATE FUNCTION
CREATE TRIGGER trig_upsert_buecher
    AFTER INSERT OR UPDATE ON podio.qs_bucherliste
    FOR EACH STATEMENT
    EXECUTE PROCEDURE kc.upsert_buecher();