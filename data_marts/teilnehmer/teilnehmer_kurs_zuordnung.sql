-- CREATE TABLE for kontakte kurse zurodnung
CREATE TABLE tc.teilnehmer_kurs_zuordnung AS
SELECT app_item_id as lehrgangs_details_id,
    (cast(json_report as json)->>'Id')::integer as teilnehmer_id_tutoren,
	calclehrgang as lehrgang,
	fulfillment_components_id_3::integer as lehrgang_id_backoffice,
	fc_id_2::integer as lehrgang_id_qm_2,
	(cast(calculation_18 as json)->>'start_date')::date as startdatum,
	(cast(calculation_9 as json)->>'start_date')::date as enddatum,
	cast(status as json)->>'text' as status,
	(cast(tutor_2 as json)->>'app_item_id')::integer as tutor_id,
	cast(tutor_2 as json)->>'title' as tutor_name,
	last_event_on
FROM podio.tutoren_lehrgangs_details;

-- SET keys
ALTER TABLE tc.teilnehmer_kurs_zuordnung 
    ADD PRIMARY KEY (lehrgangs_details_id);

ALTER TABLE tc.teilnehmer_kurs_zuordnung
	ADD CONSTRAINT fk_teilnehmer_tutoren
	FOREIGN KEY (teilnehmer_id_tutoren)
	REFERENCES tc.teilnehmer_ids (teilnehmer_id_tutoren);
	
-- SET OWNER
ALTER TABLE tc.teilnehmer_kurs_zuordnung OWNER TO read_only;