--Create TABLE massnahmen_kurs_zuordnung
CREATE TABLE tc.massnahmen_kurs_zuordnung AS
 SELECT massnahme_kurs_zuordnung.app_item_id,
    massnahme_kurs_zuordnung.massnahmen_id_sales as massnahmen_id,
    massnahme_kurs_zuordnung.massnahmen_titel,
    massnahme_kurs_zuordnung.kurs_titel,
    massnahme_kurs_zuordnung.kurs_id,
    massnahme_kurs_zuordnung.kurs_fachbereich,
    massnahme_kurs_zuordnung.kurs_dauer_in_wochen,
    massnahme_kurs_zuordnung.kurs_reihenfolge,
    massnahme_kurs_zuordnung.kurs_dauer_in_wochen_cumsum,
    massnahme_kurs_zuordnung.last_event_on,
    massnahme_kurs_zuordnung.id
   FROM kc.massnahme_kurs_zuordnung;

--SET KEYS
ALTER TABLE tc.massnahmen_kurs_zuordnung 
    ADD PRIMARY KEY (massnahmen_id, kurs_id);
