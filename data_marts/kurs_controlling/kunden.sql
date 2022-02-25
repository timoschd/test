-- create teilnehmer table in data mart. use all participants that paticipated in 2019 or later
CREATE TABLE kc.kunden AS 
SELECT app_item_id AS lead_id,
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
FROM podio.sales_management_leads
WHERE sales_management_leads.auftragsdatum IS NOT NULL
	AND (sales_management_leads.status2::JSON ->> 'text'::text) <> 'STORNO'::text
	AND ((startdatum_bildungsgutschein::JSON ->> 'start_date')::date + ('1 month'::interval * anzahl_monate_bgs::numeric::int) >= '2019-01-01'::date
	OR (startdatum_bildungsgutschein::JSON ->> 'start_date')::date IS NULL
	OR anzahl_monate_bgs::numeric::int IS NULL)
ORDER BY startdatum DESC;


-- Create indices and primary key
CREATE INDEX ON kc.kunden (startdatum);
ALTER TABLE kc.kunden ADD PRIMARY KEY (lead_id);

-- Set table owner
ALTER TABLE kc.kunden OWNER TO read_only;