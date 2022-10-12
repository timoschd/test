-- CREATE TRIGGER FUNCTION
CREATE OR REPLACE FUNCTION tc.upsert_teilnehmer()
RETURNS trigger AS
    $BODY$
    BEGIN


    -- DELETE conflicts
    DELETE FROM tc.teilnehmer
	-- delete tutoren
    WHERE teilnehmer_id_tutoren IN (SELECT app_item_id AS teilnehmer_id_tutoren FROM podio.tutoren_teilnehmer
            WHERE last_event_on > (SELECT max(last_event_on_tutoren) FROM tc.teilnehmer))
			-- delete backoffice
			OR teilnehmer_id_backoffice IN (SELECT app_item_id AS teilnehmer_id_backoffice FROM podio.backoffice_fulfillment_ubersicht
            WHERE last_event_on > (SELECT max(last_event_on_backoffice) FROM tc.teilnehmer))
			-- delete where last event on is leer
			OR last_event_on_backoffice IS NULL;
    -- UPSERT of newer entries
    INSERT INTO tc.teilnehmer
    WITH teilnehmer_urls AS
	(SELECT app_item_id AS teilnehmer_id_tutoren,
			substring(navigation, ('https://podio.com/karrieretutorde/backoffice/apps/kontakte/items/\d+')) as kontakt_url,
	 		substring(navigation, ('https://podio.com/karrieretutorde/backoffice/apps/fulfillment-ubersicht/items/\d+')) as fulfillment_url,
	 		substring(navigation, ('https://podio.com/karrieretutorde/sales-management/apps/leads/items/\d+')) as leads_url, 		
			last_event_on AS last_event_on_tutoren
		FROM podio.tutoren_teilnehmer),
	teilnehmer_ids AS
	(SELECT teilnehmer_id_tutoren,
			substring(kontakt_url, ('\d+$'))::integer as kontakt_id,
			substring(fulfillment_url, ('\d+$'))::integer as teilnehmer_id_boffice,
			substring(leads_url, ('\d+$'))::integer as lead_id,
			last_event_on_tutoren
		FROM teilnehmer_urls),
	teilnehmer_daten AS
	(SELECT backoffice_fulfillment_ubersicht.app_item_id AS teilnehmer_id_backoffice,
			backoffice_fulfillment_ubersicht.account_art_leadsflow AS abrechnung,
			backoffice_fulfillment_ubersicht.zeiteinsatz_2 AS zeiteinsatz,
			(backoffice_fulfillment_ubersicht.betreuer_aa_ap_firma ->> 'app_item_id')::integer AS kontakt_id_betreuer_aa,
			backoffice_fulfillment_ubersicht.bildungsgutscheinnummer,
			(backoffice_fulfillment_ubersicht.startdatum_bildungsgutschein ->> 'start_date'::text)::date AS startdatum_bildungsgutschein,
			backoffice_fulfillment_ubersicht.massnahmenbogen_2 AS massnahmenbogen,
			CASE WHEN(backoffice_fulfillment_ubersicht.donnerstag_starttermin ->> 'start_date'::text)::date = '1970-01-01' THEN NULL ELSE (backoffice_fulfillment_ubersicht.donnerstag_starttermin ->> 'start_date'::text)::date END AS teilnehmer_startdatum,
			CASE WHEN(backoffice_fulfillment_ubersicht.end_date ->> 'start_date'::text)::date = '1970-01-01' THEN NULL ELSE (backoffice_fulfillment_ubersicht.end_date ->> 'start_date'::text)::date END AS teilnehmer_enddatum,
			backoffice_fulfillment_ubersicht.last_event_on AS last_event_on_backoffice
		FROM podio.backoffice_fulfillment_ubersicht)
SELECT 	*
FROM teilnehmer_ids
LEFT JOIN teilnehmer_daten ON teilnehmer_ids.teilnehmer_id_boffice = teilnehmer_daten.teilnehmer_id_backoffice
WHERE (last_event_on_tutoren > (SELECT max(last_event_on_tutoren) FROM tc.teilnehmer))	
	   OR (last_event_on_backoffice > (SELECT max(last_event_on_backoffice) FROM tc.teilnehmer))
	   OR (teilnehmer_id_tutoren NOT IN (SELECT teilnehmer_id_tutoren FROM tc.teilnehmer))

    ON CONFLICT (teilnehmer_id_tutoren) 
    DO NOTHING;

    RETURN NULL;
    END;

    $BODY$
LANGUAGE plpgsql;


-- DROP TRIGGER
DROP TRIGGER IF EXISTS trig_upsert_teilnehmer_tutoren ON podio.tutoren_teilnehmer;
	   
DROP TRIGGER IF EXISTS trig_upsert_teilnehmer_backoffice ON podio.backoffice_fulfillment_ubersicht;

-- CREATE TRIGGER for UPDATE FUNCTION
CREATE TRIGGER trig_upsert_teilnehmer_tutoren
    AFTER INSERT OR UPDATE ON podio.tutoren_teilnehmer
    FOR EACH STATEMENT
    EXECUTE PROCEDURE tc.upsert_teilnehmer();
	   
CREATE TRIGGER trig_upsert_teilnehmer_backoffice
    AFTER INSERT OR UPDATE ON podio.backoffice_fulfillment_ubersicht
    FOR EACH STATEMENT
    EXECUTE PROCEDURE tc.upsert_teilnehmer();