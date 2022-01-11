-- create teilnehmer table in data mart. use all participants that paticipated in 2019 or later
CREATE TABLE kc.teilnehmer AS 
SELECT 
app_item_id as lead_id,
kategorien::json ->> 'text' as abrechnungs_kategorie,
(startdatum::json ->> 'start_date')::date as startdatum, 
bildungsgutscheinnummer,
(startdatum_bildungsgutschein::json ->> 'start_date')::date as startdatum_bildungsgutschein,
zeiteinsatz::json ->> 'text' as zeiteinsatz,
anzahl_monate_bgs::numeric::int,
calclehrgangsgebuehren as gebuehren_gesamt,
last_event_on

FROM podio.sales_management_leads
	WHERE sales_management_leads.auftragsdatum IS NOT NULL
		AND (sales_management_leads.status2::json ->> 'text'::text) <> 'STORNO'::text
		AND ((startdatum_bildungsgutschein::json ->> 'start_date')::date + ('1 month'::interval * anzahl_monate_bgs::numeric::int) >= '2019-01-01'::date
		OR (startdatum_bildungsgutschein::json ->> 'start_date')::date IS NULL OR anzahl_monate_bgs::numeric::int IS NULL)		
order by startdatum desc;


-- Create indices and primary key
CREATE INDEX ON kc.teilnehmer (startdatum);
ALTER TABLE kc.teilnehmer ADD PRIMARY KEY (lead_id);

-- Set table owner
ALTER TABLE kc.teilnehmer OWNER TO read_only;