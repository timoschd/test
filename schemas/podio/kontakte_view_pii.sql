-- CREATE view tc.kontakte_view_pii
CREATE view podio.kontakte_view_pii AS
SELECT app_item_id AS kontakt_id,
	app_item_id_formatted AS kontakt_id_formatted,
	cast(anrede AS JSON)->>'text' AS anrede,
	vorname,
	nachname,
	formatted_number AS Phone,
	address AS Adresse,
	email,
	extract(YEAR FROM (cast(geburtsdatum AS JSON)->>'start_date')::date) AS geburtsdatum,
	substring(anschrift, ('\w+$')) as land,
	(cast(json_address AS JSON)->>'PostalCode') AS plz,
	aktiver_lead::numeric AS aktive_leads,
	total_lead::numeric AS anzahl_leads,
	total_calls::numeric AS anzahl_anrufe,
	last_event_on
FROM podio.backoffice_kontakte;

-- SET OWNER
ALTER View podio.kontakte_view_pii OWNER TO read_only;