
-- Create Table termine
Create TABLE lehrgangs_controlling.termine AS
SELECT qs_terminmanagement.app_item_id,
    qs_terminmanagement.tutoriengruppen_id::numeric AS termin_id,
    qs_terminmanagement.terminart::json ->> 'text'::text AS termin_terminart,
    qs_terminmanagement.statuswert AS termin_status,
    (qs_terminmanagement.json_terminmanagement::json -> 0) ->> 'Dozent'::text AS dozent_name,
    unnest(string_to_array(qs_terminmanagement.dozenteninformationen_id_dozentseminarhelfer, ','::text))::integer AS dozent_unique_id,
    unnest(string_to_array(qs_terminmanagement.ffmt_cmt_id, ','::text))::integer AS lehrgang_id,
	(fulfillment_component_2::json ->> 'app_item_id')::int as qm_lehrgang_id,
    qs_terminmanagement.anzahl_teilnehmer::numeric AS termin_anzahl_teilnehmer,
    (qs_terminmanagement.gultig_ab::json ->> 'start_date'::text)::date AS termin_gultig_ab,
    (qs_terminmanagement.gultig_bis::json ->> 'start_date'::text)::date AS termin_gultig_bis
FROM podio.qs_terminmanagement;

-- Add indices and primary keys
ALTER TABLE lehrgangs_controlling.termine ADD COLUMN id SERIAL PRIMARY KEY;

-- Set constraints to table (no unique col available)
CREATE UNIQUE INDEX ON lehrgangs_controlling.lehrgaenge (app_item_id);

ALTER TABLE lehrgangs_controlling.termine
ADD CONSTRAINT fk_lehrgang
FOREIGN KEY (qm_lehrgang_id)
REFERENCES lehrgangs_controlling.lehrgaenge (app_item_id);

ALTER TABLE lehrgangs_controlling.termine
ADD CONSTRAINT fk_dozent
FOREIGN KEY (dozent_unique_id)
REFERENCES lehrgangs_controlling.dozenten (dozent_unique_id);