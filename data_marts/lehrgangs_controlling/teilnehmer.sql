-- create teilnehmer table in data mart. use all participants that paticipated in 2019 or later
CREATE TABLE lehrgangs_controlling.teilnehmer AS 
SELECT 
app_item_id as lead_id,
kategorien::json ->> 'text' as abrechnungs_kategorie,
(startdatum::json ->> 'start_date')::date as startdatum, 
bildungsgutscheinnummer,
(startdatum_bildungsgutschein::json ->> 'start_date')::date as startdatum_bildungsgutschein,
zeiteinsatz::json ->> 'text' as zeiteinsatz,
anzahl_monate_bgs::numeric::int,
calclehrgangsgebuehren as gebuehren_gesamt 

FROM podio.sales_management_leads
	WHERE sales_management_leads.auftragsdatum IS NOT NULL
		AND (sales_management_leads.status2::json ->> 'text'::text) <> 'STORNO'::text
		AND ((startdatum_bildungsgutschein::json ->> 'start_date')::date + ('1 month'::interval * anzahl_monate_bgs::numeric::int) >= '2019-01-01'::date
		OR (startdatum_bildungsgutschein::json ->> 'start_date')::date IS NULL OR anzahl_monate_bgs::numeric::int IS NULL)		
order by startdatum desc;


-- Create indices and primary key
CREATE INDEX ON lehrgangs_controlling.teilnehmer (startdatum);
ALTER TABLE lehrgangs_controlling.teilnehmer ADD PRIMARY KEY (lead_id);

-- Set constraints to table
ALTER TABLE lehrgangs_controlling.massnahmen_teilnehmer
ADD CONSTRAINT fk_lead
FOREIGN KEY (lead_id)
REFERENCES lehrgangs_controlling.teilnehmer (lead_id);


