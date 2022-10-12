---CREATE view tc.kontakte_view_pii_teilnehmer
CREATE view podio.kontakte_view_pii_teilnehmer AS
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
	last_event_on,
	tc.teilnehmer.teilnehmer_id_tutoren as teilnehmer_id_tutoren,
	date(tc.teilnehmer.teilnehmer_enddatum) as teilnehmer_enddatum
FROM podio.backoffice_kontakte
    LEFT JOIN tc.teilnehmer on podio.backoffice_kontakte.app_item_id = tc.teilnehmer.kontakt_id
WHERE teilnehmer_enddatum >= '2020-01-01' AND teilnehmer_id_tutoren IS NOT NULL;

--SET OWNER
ALTER VIEW podio.kontakte_view_pii_teilnehmer OWNER TO read_only;