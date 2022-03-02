
-- Create Table termine
Create TABLE kc.termine AS
SELECT qs_terminmanagement.app_item_id,
    qs_terminmanagement.tutoriengruppen_id::numeric AS termin_id,
    qs_terminmanagement.terminart::json ->> 'text'::text AS termin_terminart,
    qs_terminmanagement.statuswert AS termin_status,
    (qs_terminmanagement.json_terminmanagement::json -> 0) ->> 'Dozent'::text AS dozent_name,
    unnest(string_to_array(qs_terminmanagement.dozenteninformationen_id_dozentseminarhelfer, ','::text))::integer AS dozent_id_qm,
    unnest(string_to_array(qs_terminmanagement.ffmt_cmt_id, ','::text))::integer AS lehrgang_id,
	(fulfillment_component_2::json ->> 'app_item_id')::int as kurs_id_qm,
    qs_terminmanagement.anzahl_teilnehmer::numeric AS termin_anzahl_teilnehmer,
    (qs_terminmanagement.gultig_ab::json ->> 'start_date'::text)::date AS termin_gultig_ab,
    (qs_terminmanagement.gultig_bis::json ->> 'start_date'::text)::date AS termin_gultig_bis,
    last_event_on
FROM podio.qs_terminmanagement;

-- Add indices and primary keys
ALTER TABLE kc.termine ADD COLUMN id SERIAL PRIMARY KEY;

CREATE INDEX ON kc.termine (termin_id);
CREATE INDEX ON kc.termine (kurs_id_qm);
CREATE INDEX ON kc.termine (dozent_id_qm);

-- Set forgein constraints
ALTER TABLE kc.termine
ADD CONSTRAINT fk_kurs
FOREIGN KEY (kurs_id_qm)
REFERENCES kc.kurse (kurs_id_qm)
DEFERRABLE INITIALLY DEFERRED;

--dozent key klappt nicht
ALTER TABLE kc.termine
ADD CONSTRAINT fk_dozent
FOREIGN KEY (dozent_id_qm)
REFERENCES kc.dozenten (dozent_id_qm)
DEFERRABLE INITIALLY DEFERRED;


-- Set table owner
ALTER TABLE kc.termine OWNER TO read_only;