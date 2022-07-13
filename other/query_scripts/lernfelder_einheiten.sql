-- extract lernfelder to course relation with lerneinheiten from qm podio workspaces

WITH lern AS (
SELECT 
app_item_id as lerneinheit_id_qm,
substring(lfd_nr_lerneinheit, '[A-Z0-9]?\.\d?') as lerneinheit_nr,
title,
woche::numeric::int,
unnest(string_to_array(qm_ffmt_cmt_ids, ','))::bigint as kurs_id_qm2
FROM podio.qs_lerneinheiten
    ),
    
kurse as (SELECT kurs_id_qm, kurs_id FROM kc. kurse),

-- join kurs_id to lerneinheiten
lerneinheit AS (
    SELECT * FROM lern
LEFT JOIN kurse
ON lern.kurs_id_qm2 = kurse.kurs_id_qm
    ),

lernfeld AS (
SELECT 
app_item_id AS lernfeld_id_qm,
title,
substring(lfd_nr_lerneinheit, '(?<=\>)[A-Z0-9]?(?=\<)') as lernfeld_nr,
unnest(string_to_array(qm_ffmt_cmt_ids, ','))::bigint as kurs_id_qm
FROM podio.qs_lernfelder
)

-- join lernfelder to kurs_lerneinheit
SELECT * FROM lerneinheit
LEFT JOIN lernfeld
ON LEFT(lerneinheit.lerneinheit_nr, 1) = lernfeld.lernfeld_nr AND lerneinheit.kurs_id_qm2 = lernfeld.kurs_id_qm;
