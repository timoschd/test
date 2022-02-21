-- Create Table kontakte
CREATE TABLE tc.kontakte AS
SELECT 	app_item_id,
		app_item_id_formatted as kontakt_id,
		cast(anrede as json)->>'text' as anrede,
		vorname,
		nachname,
		(cast(geburtsdatum as json)->>'start_date')::date as geburtsdatum,
        last_event_on
	FROM podio.backoffice_kontakte;

-- Set Key
ALTER TABLE tc.kontakte 
    ADD PRIMARY KEY (kontakt_id);