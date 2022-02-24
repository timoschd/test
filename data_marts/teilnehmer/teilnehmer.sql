--Create TABLE Teilnehmer
CREATE TABLE tc.teilnehmer AS 
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
			backoffice_fulfillment_ubersicht.betreuer_aa_ap_firma ->> 'app_item_id' AS kontakt_id_betreuer_aa,
			backoffice_fulfillment_ubersicht.bildungsgutscheinnummer,
			(backoffice_fulfillment_ubersicht.startdatum_bildungsgutschein ->> 'start_date'::text)::date AS startdatum_bildungsgutschein,
			backoffice_fulfillment_ubersicht.massnahmenbogen_2 AS massnahmenbogen,
			(backoffice_fulfillment_ubersicht.donnerstag_starttermin ->> 'start_date'::text)::date AS teilnehmer_startdatum,
			(backoffice_fulfillment_ubersicht.end_date ->> 'start_date'::text)::date AS teilnehmer_enddatum,
			backoffice_fulfillment_ubersicht.last_event_on AS last_event_on_backoffice
		FROM podio.backoffice_fulfillment_ubersicht)
SELECT 	*
FROM teilnehmer_ids
LEFT JOIN teilnehmer_daten ON teilnehmer_ids.teilnehmer_id_boffice = teilnehmer_daten.teilnehmer_id_backoffice;

--Set key
ALTER TABLE tc.teilnehmer
    ADD PRIMARY KEY (teilnehmer_id_tutoren);
	
-- SET OWNER
ALTER TABLE tc.teilnehmer OWNER TO read_only;