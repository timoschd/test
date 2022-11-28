DROP VIEW IF EXISTS sc.Zielwerte;

-- 
CREATE VIEW sc.Zielwerte (
Tagesziel,
Wochenziel,
Monatsziel,
Jahresziel) AS VALUES (180000, 1000000, 4000000, 48000000);

ALTER VIEW sc.zielwerte OWNER TO read_only