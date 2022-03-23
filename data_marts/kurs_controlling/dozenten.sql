 -- Create Table dozenten
 
 CREATE TABLE kc.dozenten_ (
	dozent_anzahl_teilnehmer integer,
	dozent_fachgruppe text,
	dozent_gehalt_pro_monat numeric,
	dozent_gehalt_pro_stunde numeric,
	dozent_gueltig_ab date,
	dozent_gueltig_bis date,
	dozent_id integer,
	dozent_id_qm integer PRIMARY KEY,
	dozent_name text,
	dozent_stunden_fur_produktion_pro_woche numeric,
	dozent_stunden_pro_woche numeric,
	dozent_vertragsstatus text,
	dozenten_sonderaufgaben_pro_woche text
);


--old 
 Create TABLE kc.dozenten AS
 SELECT qs_dozenteninformationen.app_item_id as dozent_id_qm,
    qs_dozenteninformationen.verbindung::json ->> 'title'::text AS dozent_name,
    qs_dozenteninformationen.dozenten_id::numeric::integer AS dozent_id,
    qs_dozenteninformationen.kategorien::json ->> 'text'::text AS dozent_vertragsstatus,
    qs_dozenteninformationen.fachgruppe::json ->> 'text'::text AS dozent_fachgruppe,
    (qs_dozenteninformationen.gultig_ab::json ->> 'start_date_utc'::text)::date AS dozent_gueltig_ab,
    (qs_dozenteninformationen.gultig_bis::json ->> 'start_date_utc'::text)::date AS dozent_gueltig_bis,
    qs_dozenteninformationen.teilnehmer_aktuell_2::numeric::integer AS dozent_anzahl_teilnehmer,
    qs_dozenteninformationen.stunden_fur_produktion::numeric AS dozent_stunden_fur_produktion_pro_woche,
    qs_dozenteninformationen.sonderaufgaben_in_stunden_pro_woche::numeric AS dozenten_sonderaufgaben_pro_woche,
    qs_dozenteninformationen.arbeitsstunden_pro_woche::numeric AS dozent_stunden_pro_woche,
    --qs_dozenteninformationen.gehalt_pro_stunde::numeric AS dozent_gehalt_pro_stunde,
    --qs_dozenteninformationen.gehalt_pro_monat::numeric AS dozent_gehalt_pro_monat,
    last_event_on
   FROM podio.qs_dozenteninformationen;
  
  -- Create indices
ALTER TABLE IF EXISTS kc.dozenten
    ADD PRIMARY KEY (dozent_id_qm);

CREATE INDEX ON kc.dozenten (dozent_id);

-- Set table owner
ALTER TABLE kc.dozenten OWNER TO read_only;