--Create Table kurse
CREATE TABLE tc.kurse AS
SELECT  kurs_id,
        kurs_titel,
        kurs_fachgruppe,
        kurs_fachbereich,
        kurs_gueltig_ab,
        kurs_gueltig_bis,
        kurs_prufung_art,
        kurs_prufung_externe_einrichtung,
        kurs_produktion,
        kurs_dauer_in_wochen,
        last_event_on
	FROM kc.kurse;

-- SET KEYS
ALTER TABLE tc.kurse 
    ADD PRIMARY KEY (kurs_id);