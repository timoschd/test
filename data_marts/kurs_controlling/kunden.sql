-- create teilnehmer table in data mart. use all participants that paticipated in 2019 or later
CREATE TABLE kc.kunden AS 
SELECT app_item_id AS lead_id,
	substring(cast(json_data_3 AS JSON) -> 'json' ->> 'fulfillment_ubersicht_url', '(\d+)\s?$')::integer,
	sales_management_leads.auftragsberechnungen::JSON ->> 'app_item_id'::text AS auftragsberechnungen_id,
	sales_management_leads.kontakt_backoffice::JSON ->> 'app_item_id'::text AS kontakt_id,
	sales_management_leads.angebots_produkte::JSON ->> 'app_item_id'::text AS angbots_produkt_id,
	kategorien::JSON ->> 'text' AS abrechnungs_kategorie,
	(startdatum::JSON ->> 'start_date')::date AS startdatum,
	bildungsgutscheinnummer,
	sales_management_leads.account_backoffice::JSON ->> 'title'::text AS agentur_stelle,
	(startdatum_bildungsgutschein::JSON ->> 'start_date')::date AS startdatum_bildungsgutschein,
	sales_management_leads.berufsklassifikation::JSON ->> 'title'::text AS berufsklassifikation,
	zeiteinsatz::JSON ->> 'text' AS zeiteinsatz,
	anzahl_monate_bgs::numeric::int,
	calclehrgangsgebuehren AS gebuehren_gesamt,
	last_event_on
FROM podio.sales_management_leads;

-- Create indices and primary key
CREATE INDEX ON kc.kunden (startdatum);
ALTER TABLE kc.kunden ADD PRIMARY KEY (lead_id);

-- Set table owner
ALTER TABLE kc.kunden OWNER TO read_only;