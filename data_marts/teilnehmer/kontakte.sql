-- CREATE TABLE tc.kontakte
CREATE TABLE tc.kontakte AS
SELECT app_item_id AS kontakt_id,
	app_item_id_formatted AS kontakt_id_formatted,
	cast(anrede AS JSON)->>'text' AS anrede,
	extract(YEAR FROM (cast(geburtsdatum AS JSON)->>'start_date')::date) AS geburtsdatum,
	substring(anschrift, ('\w+$')) as land,
	(cast(json_address AS JSON)->>'PostalCode') AS plz,
	aktiver_lead::numeric AS aktive_leads,
	total_lead::numeric AS anzahl_leads,
	total_calls::numeric AS anzahl_anrufe,
	last_event_on
FROM podio.backoffice_kontakte;

-- Set Key
ALTER TABLE tc.kontakte 
    ADD PRIMARY KEY (kontakt_id);

CREATE UNIQUE INDEX ON tc.kontakte (kontakt_id_formatted);

-- rules for kontakte
ALTER TABLE tc.kontakte
ADD CONSTRAINT kontake_birth
CHECK (geburtsdatum >= 1900);

ALTER TABLE tc.kontakte
ADD CONSTRAINT kontake_leads
CHECK (aktive_leads >= 0 AND anzahl_leads >= 0);

ALTER TABLE tc.kontakte
ADD CONSTRAINT kontake_anrufe
CHECK (anzahl_anrufe >= 0);

-- SET OWNER
ALTER TABLE tc.kontakte OWNER TO read_only;