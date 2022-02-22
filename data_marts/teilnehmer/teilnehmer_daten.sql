-- CREATE TABLE for teilnehmer daten
CREATE TABLE tc.teilnehmer_daten AS
SELECT backoffice_fulfillment_ubersicht.app_item_id AS teilnehmer_id_backoffice,
	backoffice_fulfillment_ubersicht.account_art_leadsflow AS abrechnung,
	backoffice_fulfillment_ubersicht.zeiteinsatz_2 AS zeiteinsatz,
	backoffice_fulfillment_ubersicht.betreuer_aa_ap_firma ->> 'app_item_id' AS kontakt_id_betreuer_aa,
	backoffice_fulfillment_ubersicht.bildungsgutscheinnummer,
	(backoffice_fulfillment_ubersicht.startdatum_bildungsgutschein ->> 'start_date'::text)::date AS startdatum_bildungsgutschein,
	backoffice_fulfillment_ubersicht.massnahmenbogen_2 AS massnahmenbogen,
	(backoffice_fulfillment_ubersicht.donnerstag_starttermin ->> 'start_date'::text)::date AS teilnehmer_startdatum,
	(backoffice_fulfillment_ubersicht.end_date ->> 'start_date'::text)::date AS teilnehmer_enddatum,
	backoffice_fulfillment_ubersicht.last_event_on
FROM podio.backoffice_fulfillment_ubersicht;

-- SET keys
ALTER TABLE tc.teilnehmer_daten 
    ADD PRIMARY KEY (teilnehmer_id_backoffice);

-- SET OWNER
ALTER TABLE tc.teilnehmer_daten OWNER TO read_only;