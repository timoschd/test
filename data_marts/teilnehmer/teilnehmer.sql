-- CREATE TABLE for teilnehmer kurse zurodnung
 CREATE TABLE tc.teilnehmer AS
         SELECT backoffice_fulfillment_ubersicht.app_item_id,
            backoffice_fulfillment_ubersicht.teilnehmer_id_2::numeric::integer AS teilnehmer_id,
            ((backoffice_fulfillment_ubersicht.json_data_kontakte::json -> 'json'::text) ->> 'uniqueid'::text)::integer AS kontakt_id,
            (backoffice_fulfillment_ubersicht.json_dataleads::json ->> 'uniqueid'::text)::integer AS lead_id,
            backoffice_fulfillment_ubersicht.account_art_leadsflow AS abrechnung,
            backoffice_fulfillment_ubersicht.zeiteinsatz_2 AS zeiteinsatz,
            backoffice_fulfillment_ubersicht.bildungsgutscheinnummer,
            (backoffice_fulfillment_ubersicht.startdatum_bildungsgutschein ->> 'start_date'::text)::date AS startdatum_bildungsgutschein,
            backoffice_fulfillment_ubersicht.massnahmenbogen_2 AS massnahmenbogen,
            (backoffice_fulfillment_ubersicht.end_date ->> 'start_date'::text)::date AS teilnehmer_enddatum,
            backoffice_fulfillment_ubersicht.last_event_on
           FROM podio.backoffice_fulfillment_ubersicht;

-- SET keys
ALTER TABLE tc.teilnehmer 
    ADD PRIMARY KEY (app_item_id);

-- SET OWNER
ALTER TABLE tc.teilnehmer OWNER TO read_only;