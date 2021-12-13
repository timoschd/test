 -- Create Table dozenten
 Create TABLE kc.dozenten AS
 SELECT qs_dozenteninformationen.app_item_id,
    qs_dozenteninformationen.verbindung::json ->> 'title'::text AS dozent_name,
    qs_dozenteninformationen.dozenten_id::numeric::integer AS dozent_id_qm,
    qs_dozenteninformationen.kategorien::json ->> 'text'::text AS dozent_vertragsstatus,
    qs_dozenteninformationen.fachgruppe::json ->> 'text'::text AS dozent_fachgruppe,
    (qs_dozenteninformationen.gultig_ab::json ->> 'start_date_utc'::text)::date AS dozent_gueltig_ab,
    (qs_dozenteninformationen.gultig_bis::json ->> 'start_date_utc'::text)::date AS dozent_gueltig_bis,
    qs_dozenteninformationen.teilnehmer_aktuell_2::numeric::integer AS dozent_anzahl_teilnehmer,
    qs_dozenteninformationen.stunden_fur_produktion::numeric AS dozent_stunden_fur_produktion_pro_woche,
    qs_dozenteninformationen.sonderaufgaben_in_stunden_pro_woche::numeric AS dozenten_sonderaufgaben_pro_woche,
    qs_dozenteninformationen.arbeitsstunden_pro_woche::numeric AS dozent_stunden_pro_woche,
    qs_dozenteninformationen.gehalt_pro_stunde::numeric AS dozent_gehalt_pro_stunde,
    qs_dozenteninformationen.gehalt_pro_monat::numeric AS dozent_gehalt_pro_monat
   FROM podio.qs_dozenteninformationen;
   
  -- Create primary key & not null 
  ALTER TABLE IF EXISTS kc.dozenten
    ALTER COLUMN dozent_unique_id SET NOT NULL;
  
  ALTER TABLE IF EXISTS kc.dozenten
    ADD PRIMARY KEY (dozent_unique_id);
   
 --