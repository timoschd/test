-- tabelle löschen
DROP TABLE IF EXISTS sc.zielwerte;

-- tabelle erstellen mit vorgegebenen werten
CREATE TABLE sc.zielwerte (
Tagesziel,
Wochenziel,
Monatsziel,
Jahresziel) AS VALUES (180000, 1000000, 4000000, 48000000);

-- owner read_only
ALTER TABLE sc.zielwerte OWNER TO read_only;