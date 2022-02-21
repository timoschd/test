-- CREATE TABLE for kontakte kurse zurodnung
 CREATE TABLE tc.kontakte_kurse_zuordnung AS
 WITH temptable AS (
         SELECT backoffice_fulfillment_ubersicht.app_item_id,
            backoffice_fulfillment_ubersicht.teilnehmer_id_2::numeric::integer AS teilnehmer_id,
            ((backoffice_fulfillment_ubersicht.json_data_kontakte::json -> 'json'::text) ->> 'uniqueid'::text)::integer AS kontakt_id,
            (backoffice_fulfillment_ubersicht.json_dataleads::json ->> 'uniqueid'::text)::integer AS lead_id,
            replace(backoffice_fulfillment_ubersicht.kundenflag::json ->> 'text'::text, '"'::text, ''::text) AS status,
            (backoffice_fulfillment_ubersicht.abbruch_datum_2::json ->> 'start_date'::text)::date AS abbruch_datum,
            (backoffice_fulfillment_ubersicht.abbruch_datum_intern::json ->> 'start_date'::text)::date AS abbruch_datum_intern,
            backoffice_fulfillment_ubersicht.account_art_leadsflow AS abrechnung,
            backoffice_fulfillment_ubersicht.zeiteinsatz_2 AS zeiteinsatz,
            backoffice_fulfillment_ubersicht.bildungsgutscheinnummer,
            (backoffice_fulfillment_ubersicht.startdatum_bildungsgutschein ->> 'start_date'::text)::date AS startdatum_bildungsgutschein,
            backoffice_fulfillment_ubersicht.massnahmenbogen_2 AS massnahmenbogen,
            json_array_elements(backoffice_fulfillment_ubersicht.json_kursplan::json) AS kurse,
            (backoffice_fulfillment_ubersicht.end_date ->> 'start_date'::text)::date AS teilnehmer_enddatum,
            backoffice_fulfillment_ubersicht.last_event_on
           FROM podio.backoffice_fulfillment_ubersicht
        )
 SELECT temptable.app_item_id,
    temptable.teilnehmer_id,
    temptable.kontakt_id,
    temptable.lead_id,
    temptable.abrechnung,
    temptable.zeiteinsatz,
    temptable.bildungsgutscheinnummer,
    temptable.startdatum_bildungsgutschein,
    temptable.massnahmenbogen,
    temptable.kurse ->> 'strComponent'::text AS lehrgang,
    (temptable.kurse ->> 'StartDate'::text)::date AS startdatum,
    (temptable.kurse ->> 'EndDate'::text)::date AS enddatum,
    (temptable.kurse ->> 'Wochen'::text)::numeric AS wochen,
    row_number() OVER (PARTITION BY temptable.app_item_id) AS lehrgang_reihenfolge,
    temptable.status,
    temptable.abbruch_datum,
    temptable.abbruch_datum_intern,
    temptable.teilnehmer_enddatum,
    temptable.last_event_on
   FROM temptable;

-- SET keys
ALTER TABLE tc.kontakte_kurse_zuordnung 
    ADD PRIMARY KEY (app_item_id, startdatum, lehrgang);

-- SET OWNER
ALTER TABLE tc.kontakte_kurse_zuordnung OWNER TO read_only;