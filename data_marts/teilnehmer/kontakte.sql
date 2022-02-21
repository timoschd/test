-- CREATE TABLE tc.kontakte
CREATE TABLE tc.kontakte AS
SELECT app_item_id,
	app_item_id_formatted AS kontakt_id,
	cast(anrede AS JSON)->>'text' AS anrede,
	extract(YEAR FROM (cast(geburtsdatum AS JSON)->>'start_date')::date) AS geburtsdatum,
	(cast(json_address AS JSON)->>'PostalCode') AS plz,
	aktiver_lead::numeric AS aktive_leads,
	total_lead::numeric AS anzahl_leads,
	total_calls::numeric AS anzahl_anrufe,
	last_event_on
FROM podio.backoffice_kontakte;

-- Set Key
ALTER TABLE tc.kontakte 
    ADD PRIMARY KEY (kontakt_id);

CREATE UNIQUE INDEX ON tc.kontakte (app_item_id);

-- SET OWNER
ALTER TABLE tc.kontakte OWNER TO read_only;