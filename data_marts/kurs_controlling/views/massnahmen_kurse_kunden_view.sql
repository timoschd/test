-- view for JOIN Table massnahmen_kunden & massnahmen_kurse
 WITH temptable AS (
         SELECT massnahmen_kunden_zuordnung.lead_id,
            massnahmen_kunden_zuordnung.teilnehmer_startdatum,
            massnahmen_kunden_zuordnung.teilnehmer_zeiteinsatz,
            massnahmen_kunden_zuordnung.massnahmen_titel AS mt,
            massnahmen_kunden_zuordnung.massnahmen_id_sales AS mids,
            massnahmen_kunden_zuordnung.massnahmen_gebuhr_nach_bgs,
            massnahmen_kunden_zuordnung.massnahmen_dauer_in_wochen,
            massnahmen_kunden_zuordnung.massnahmen_reihenfolge,
            massnahmen_kunden_zuordnung.massnahmen_dauer_in_wochen_cumsum,
            massnahmen_kunden_zuordnung.massnahmen_startdatum,
            massnahmen_kunden_zuordnung.f_startdatum_bgs,
            massnahmen_kunden_zuordnung.f_enddatum_bgs,
            massnahmen_kunden_zuordnung.f_lead_status,
            massnahmen_kunden_zuordnung.last_event_on AS last_event_on_2
           FROM kc.massnahmen_kunden_zuordnung
        ), temptable_2 AS (
         SELECT massnahme_kurs_zuordnung.app_item_id,
            massnahme_kurs_zuordnung.massnahmen_id_qm,
            massnahme_kurs_zuordnung.massnahmen_id_sales,
            massnahme_kurs_zuordnung.massnahmen_titel,
            massnahme_kurs_zuordnung.kurs_titel,
            massnahme_kurs_zuordnung.kurs_id,
            massnahme_kurs_zuordnung.kurs_fachbereich,
            massnahme_kurs_zuordnung.kurs_dauer_in_wochen,
            massnahme_kurs_zuordnung.kurs_reihenfolge,
            massnahme_kurs_zuordnung.kurs_dauer_in_wochen_cumsum,
            massnahme_kurs_zuordnung.last_event_on
           FROM kc.massnahme_kurs_zuordnung
        )
 SELECT temptable.lead_id,
    temptable.teilnehmer_startdatum,
    temptable.teilnehmer_zeiteinsatz,
    temptable.mt,
    temptable.mids,
    temptable.massnahmen_gebuhr_nach_bgs,
    temptable.massnahmen_dauer_in_wochen,
    temptable.massnahmen_reihenfolge,
    temptable.massnahmen_dauer_in_wochen_cumsum,
    temptable.massnahmen_startdatum,
    temptable.f_startdatum_bgs,
    temptable.f_enddatum_bgs,
    temptable.f_lead_status,
    temptable.last_event_on_2,
    temptable_2.app_item_id,
    temptable_2.massnahmen_id_qm,
    temptable_2.massnahmen_id_sales,
    temptable_2.massnahmen_titel,
    temptable_2.kurs_titel,
    temptable_2.kurs_id,
    temptable_2.kurs_fachbereich,
    temptable_2.kurs_dauer_in_wochen,
    temptable_2.kurs_reihenfolge,
    temptable_2.kurs_dauer_in_wochen_cumsum,
    temptable_2.last_event_on
   FROM temptable
     RIGHT JOIN temptable_2 ON temptable.mids = temptable_2.massnahmen_id_sales;