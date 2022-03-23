-- Create Table kc.kurse as join from qm and backoffice
CREATE TABLE kc.kurse AS
WITH kurse_backoffice AS
	(SELECT app_item_id AS kurs_id, --backoffice id
 			substring(qm_ffmt_comp, ('(\d+)\)$'))::integer AS kurs_id_qs_qm,
			titel AS kurs_titel,
			status_2 AS kurs_status,
			last_event_on AS last_event_on_backoffice
		FROM podio.backoffice_fulfillment_components), 
kurse_qm AS
	(SELECT qs_qm_lehrgange.app_item_id AS kurs_id_qm,
			qs_qm_lehrgange.fachgruppe::JSON ->> 'text'::text AS kurs_fachgruppe,
			qs_qm_lehrgange.fachbereich_2 AS kurs_fachbereich,
			qs_qm_lehrgange.prufung::JSON ->> 'text'::text AS kurs_prufung_art,
			qs_qm_lehrgange.prufung_extern::JSON ->> 'text'::text AS kurs_prufung_externe_einrichtung,
			qs_qm_lehrgange.prufungsgebuhr::numeric AS lehrgang_prufung_preis,
			(qs_qm_lehrgange.aktiv_gultig_ab_2::JSON ->> 'start_date'::text)::date AS kurs_gueltig_ab,
			(qs_qm_lehrgange.aktiv_gultig_bis_2::JSON ->> 'start_date'::text)::date AS kurs_gueltig_bis,
			qs_qm_lehrgange.produktion::JSON ->> 'text'::text AS kurs_produktion,
			qs_qm_lehrgange.dauer_in_wochen::numeric AS kurs_dauer_in_wochen,
			qs_qm_lehrgange.tutorienzeit_gesamt_2::numeric AS kurs_tutorienzeit_pro_woche,
			qs_qm_lehrgange.lerngruppenzeit_gesamt_2::numeric AS kurs_lerngruppenzeit_pro_woche,
			qs_qm_lehrgange.onboardingzeit_gesamt::numeric AS kurs_onboardingzeit_pro_woche,
			qs_qm_lehrgange.prufungsvorbereitungszeit_gesamt::numeric AS kurs_prufungsvorbereitungszeit_pro_woche,
			last_event_on
		FROM podio.qs_qm_lehrgange)
		
	SELECT * FROM kurse_backoffice
	LEFT JOIN kurse_qm ON kurse_backoffice.kurs_id_qs_qm = kurse_qm.kurs_id_qm; 
  
 -- Create indices
ALTER TABLE IF EXISTS kc.kurse
   ADD PRIMARY KEY (kurs_id);
   
CREATE UNIQUE INDEX ON kc.kurse (kurs_id_qm);

-- Set table owner
ALTER TABLE kc.kurse OWNER TO read_only;