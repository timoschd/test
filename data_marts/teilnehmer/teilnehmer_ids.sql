--Create Table for teilnehmer ids
CREATE TABLE tc.teilnehmer_ids AS
SELECT app_item_id AS teilnehmer_id_tutoren,
	cast(json_navigation AS JSON) ->> 'Kontaktid' AS kontakt_id,
	cast(json_navigation AS JSON) ->> 'Leadsid' AS lead_id,
	cast(json_navigation AS JSON) ->> 'FFMTID' AS teilnehmer_id_backoffice,
	last_event_on
FROM podio.tutoren_teilnehmer;

-- SET keys
ALTER TABLE tc.teilnehmer_ids
    ADD PRIMARY KEY (teilnehmer_id_tutoren);

-- SET OWNER
ALTER TABLE tc.teilnehmer_ids OWNER TO read_only;