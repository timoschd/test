-- Create TABLE abbrecher
Create TABLE tc.abbrecher AS
WITH temptable AS(
SELECT  app_item_id,
        (teilnehmer_id_2::numeric)::integer as teilnehmer_id, 
		(cast(json_data_kontakte as json)->'json'->>'uniqueid')::integer as kontakt_id,
		cast(json_name as json)->>'Name' as name,
		replace(cast(kundenflag as json)->>'text','"','') as status,
		(cast(abbruch_datum_2 as json)->>'start_date')::date as abbruch_datum,
		(cast(abbruch_datum_intern as json)->>'start_date')::date as abbruch_datum_intern,
		last_event_on
	FROM PODIO.BACKOFFICE_FULFILLMENT_UBERSICHT)
	
SELECT * FROM temptable WHERE status = 'Abbruch';

--SET KEYS
ALTER TABLE tc.abbrecher 
    ADD PRIMARY KEY (teilnehmer_id);