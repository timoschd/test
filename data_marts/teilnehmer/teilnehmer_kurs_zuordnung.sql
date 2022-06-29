-- CREATE TABLE for teilnehmer kurse zurodnung
CREATE TABLE tc.teilnehmer_kurs_zuordnung AS
SELECT app_item_id as lehrgangs_details_id,
    (cast(json_report as json)->>'Id')::integer as teilnehmer_id_tutoren,
	calclehrgang as kurs_titel,
	fulfillment_components_id_3::integer as kurs_id_backoffice,
	fc_id_2::integer as kurs_id_qm_2,
	(cast(calculation_18 as json)->>'start_date')::date as startdatum,
	(cast(calculation_9 as json)->>'start_date')::date as enddatum,
	cast(status as json)->>'text' as status,
	(cast(abbruch_datum as json)->>'start_date')::date as abbruch_datum,
	(cast(tutor_2 as json)->>'app_item_id')::integer as tutor_id,
	cast(tutor_2 as json)->>'title' as tutor_name,
	last_event_on
FROM podio.tutoren_lehrgangs_details;

-- SET keys
ALTER TABLE tc.teilnehmer_kurs_zuordnung 
    ADD PRIMARY KEY (lehrgangs_details_id);
	
CREATE INDEX ON  tc.teilnehmer_kurs_zuordnung  (kurs_id_backoffice);
CREATE INDEX ON  tc.teilnehmer_kurs_zuordnung  (teilnehmer_id_tutoren);
CREATE INDEX ON  tc.teilnehmer_kurs_zuordnung  (tutor_id);

ALTER TABLE tc.teilnehmer_kurs_zuordnung
	ADD CONSTRAINT fk_teilnehmer
	FOREIGN KEY (teilnehmer_id_tutoren)
	REFERENCES tc.teilnehmer (teilnehmer_id_tutoren)
	DEFERRABLE INITIALLY DEFERRED;
	
ALTER TABLE tc.teilnehmer_kurs_zuordnung
	ADD CONSTRAINT fk_kurse
	FOREIGN KEY (kurs_id_backoffice)
	REFERENCES kc.kurse (kurs_id)
	DEFERRABLE INITIALLY DEFERRED;
	
-- rules for teilnehmer kurs zuordnung
ALTER TABLE tc.teilnehmer_kurs_zuordnung
ADD CONSTRAINT teilnehmer_kurs_start
CHECK (startdatum < cast(CURRENT_DATE + ('1 year'::interval * 3) as date) AND startdatum >= '2015-01-01');,

ALTER TABLE tc.teilnehmer_kurs_zuordnung
ADD CONSTRAINT teilnehmer_kurs_ende
CHECK (enddatum < cast(CURRENT_DATE + ('1 year'::interval * 5) as date) AND enddatum >= '2015-01-01');

ALTER TABLE tc.teilnehmer_kurs_zuordnung
ADD CONSTRAINT teilnehmer_kurs_abbruch
CHECK (abbruch_datum < cast(CURRENT_DATE + ('1 year'::interval * 1) as date));

-- SET OWNER
ALTER TABLE tc.teilnehmer_kurs_zuordnung OWNER TO read_only;