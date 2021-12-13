 -- Create Table kurse
 Create TABLE kc.kurse AS
 SELECT qs_qm_lehrgange.app_item_id,
    qs_qm_lehrgange.fulfillment_components_id_2::numeric::integer AS kurs_id,
    qs_qm_lehrgange.titel_3 AS kurs_titel,
    qs_qm_lehrgange.fachgruppe::json ->> 'text'::text AS kurs_fachgruppe,
    qs_qm_lehrgange.fachbereich_2 AS kurs_fachbereich,
    qs_qm_lehrgange.prufung::json ->> 'text'::text AS kurs_prufung_art,
    qs_qm_lehrgange.prufung_extern::json ->> 'text'::text AS kurs_prufung_externe_einrichtung,
    qs_qm_lehrgange.prufungsgebuhr::numeric AS lehrgang_prufung_preis,
    (qs_qm_lehrgange.aktiv_gultig_ab_2::json ->> 'start_date'::text)::date AS kurs_gueltig_ab,
    (qs_qm_lehrgange.aktiv_gultig_bis_2::json ->> 'start_date'::text)::date AS kurs_gueltig_bis,
    qs_qm_lehrgange.produktion::json ->> 'text'::text AS kurs_produktion,
	qs_qm_lehrgange.dauer_in_wochen::numeric as kurs_dauer_in_wochen,
    qs_qm_lehrgange.tutorienzeit_gesamt_2::numeric AS kurs_tutorienzeit_pro_woche,
    qs_qm_lehrgange.lerngruppenzeit_gesamt_2::numeric AS kurs_lerngruppenzeit_pro_woche,
    qs_qm_lehrgange.onboardingzeit_gesamt::numeric AS kurs_onboardingzeit_pro_woche,
    qs_qm_lehrgange.prufungsvorbereitungszeit_gesamt::numeric AS kurs_prufungsvorbereitungszeit_pro_woche
   FROM podio.qs_qm_lehrgange
  WHERE qs_qm_lehrgange.app_item_id <> 453;
  
 -- Create primary key & not null 
 ALTER TABLE IF EXISTS kc.kurse
   ALTER COLUMN kurs_id SET NOT NULL;
  
 ALTER TABLE IF EXISTS kc.kurse
   ADD PRIMARY KEY (kurs_id);
   
 --