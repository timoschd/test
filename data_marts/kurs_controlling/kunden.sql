-- create teilnehmer table in data mart. use all participants 
CREATE TABLE kc.kunden AS 
SELECT app_item_id AS lead_id,
	sales_management_leads.auftragsberechnungen::JSON ->> 'app_item_id'::text AS auftragsberechnungen_id,
	(sales_management_leads.auftragsdatum::JSON ->>'start_date')::date as auftragsdatum,
	sales_management_leads.kontakt_backoffice::JSON ->> 'app_item_id'::text AS kontakt_id,
	sales_management_leads.angebots_produkte::JSON ->> 'app_item_id'::text AS angbots_produkt_id,
	kategorien::JSON ->> 'text' AS abrechnungs_kategorie,
	(startdatum::JSON ->> 'start_date')::date AS startdatum,
	bildungsgutscheinnummer,
	sales_management_leads.account_backoffice::JSON ->> 'title'::text AS agentur_stelle,
	(startdatum_bildungsgutschein::JSON ->> 'start_date')::date AS startdatum_bildungsgutschein,
	((startdatum_bildungsgutschein::JSON ->> 'start_date')::date + ('1 month'::interval * anzahl_monate_bgs::numeric::int)) as enddatum_bildungsgutschein,
	(sales_management_leads.status2::JSON ->> 'text'::text) as status,
	sales_management_leads.berufsklassifikation::JSON ->> 'title'::text AS berufsklassifikation,
	zeiteinsatz::JSON ->> 'text' AS zeiteinsatz,
	anzahl_monate_bgs::numeric::int,
	last_event_on,
	calclehrgangsgebuehren::numeric AS gebuehren_gesamt
FROM podio.sales_management_leads;

-- Create indices and primary key
CREATE INDEX ON kc.kunden (startdatum);
ALTER TABLE kc.kunden ADD PRIMARY KEY (lead_id);

-- rules for kunden
ALTER TABLE kc.kunden 
ADD CONSTRAINT kunden_gebuehren 
CHECK (gebuehren_gesamt>=0 AND gebuehren_gesamt<50000); 

ALTER TABLE kc.kunden 
ADD CONSTRAINT kunden_datum_bgs 
CHECK (startdatum_bildungsgutschein<enddatum_bildungsgutschein); 

ALTER TABLE kc.kunden 
ADD CONSTRAINT kunden_startdatum
CHECK (startdatum > '2015-01-01' AND startdatum < cast(CURRENT_DATE + ('1 year'::interval * 3)as date)); 

-- Set table owner
ALTER TABLE kc.kunden OWNER TO read_only;