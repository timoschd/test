-- View for JOIN table teilnehmer & teilnehmer_kurs
 CREATE VIEW tc.teilnehmer_gesamt AS
 WITH temptable AS (
         SELECT teilnehmer_kurs_zuordnung.lehrgangs_details_id,
            teilnehmer_kurs_zuordnung.teilnehmer_id_tutoren AS tidt,
            teilnehmer_kurs_zuordnung.kurs_titel,
            teilnehmer_kurs_zuordnung.kurs_id_backoffice,
            teilnehmer_kurs_zuordnung.kurs_id_qm_2,
            teilnehmer_kurs_zuordnung.startdatum,
            teilnehmer_kurs_zuordnung.enddatum,
            teilnehmer_kurs_zuordnung.status,
            teilnehmer_kurs_zuordnung.abbruch_datum,
            teilnehmer_kurs_zuordnung.tutor_id,
            teilnehmer_kurs_zuordnung.tutor_name,
            teilnehmer_kurs_zuordnung.last_event_on AS last_event_on_1
           FROM tc.teilnehmer_kurs_zuordnung
        )
 SELECT temptable.lehrgangs_details_id,
    temptable.tidt,
    temptable.kurs_titel,
    temptable.kurs_id_backoffice,
    temptable.kurs_id_qm_2,
    temptable.startdatum,
    temptable.enddatum,
    temptable.status,
    temptable.abbruch_datum,
    temptable.tutor_id,
    temptable.tutor_name,
    temptable.last_event_on_1,
    teilnehmer.teilnehmer_id_tutoren,
    teilnehmer.kontakt_id,
    teilnehmer.teilnehmer_id_boffice,
    teilnehmer.lead_id,
    teilnehmer.last_event_on_tutoren,
    teilnehmer.teilnehmer_id_backoffice,
    teilnehmer.abrechnung,
    teilnehmer.zeiteinsatz,
    teilnehmer.kontakt_id_betreuer_aa,
    teilnehmer.bildungsgutscheinnummer,
    teilnehmer.startdatum_bildungsgutschein,
    teilnehmer.massnahmenbogen,
    teilnehmer.teilnehmer_startdatum,
    teilnehmer.teilnehmer_enddatum,
    teilnehmer.last_event_on_backoffice,
	CONCAT(kurs_id_backoffice,'/',lead_id) as kurs_lead_key
   FROM temptable
     LEFT JOIN tc.teilnehmer ON temptable.tidt = teilnehmer.teilnehmer_id_tutoren;