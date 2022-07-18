-- select all relevant info about massnahmen/course kombi
WITH massnahmen_kurs AS (
    SELECT massnahmen_id_sales_int as app_item_id_sales_massnahmen,
        app_item_id as app_item_id_massnahmen,
        massnahmen_id,
        massnahmen_titel,
        massnahme_status,
        wochen,
        unterrichtseinheiten,
        dkz_nummer,
        gueltig_bis,
        gebuehren,
        massnahmenbogen_item_id,
        massnahmenbogen_titel,
     massnahme_kurs_zuordnung.kurs_id
    FROM kc.massnahmen
    LEFT JOIN kc.massnahme_kurs_zuordnung
        ON massnahmen.massnahmen_id_sales = massnahme_kurs_zuordnung.massnahmen_id_sales
        ),

kurse_sub AS (
    SELECT kurs_id,
        kurs_titel,
        kurs_status,
        kurs_id_qm,
        kurs_fachgruppe,
        kurs_fachbereich,
        kurs_prufung_art,
        kurs_prufung_externe_einrichtung,
        lehrgang_prufung_preis,
        kurs_gueltig_ab,
        kurs_gueltig_bis,
        kurs_produktion,
        kurs_dauer_in_wochen	
    FROM kc.kurse
)

SELECT * FROM massnahmen_kurs
LEFT JOIN kurse_sub ON massnahmen_kurs.kurs_id = kurse_sub.kurs_id;



-- extract Lerneinheiten for each course seperately
SELECT app_item_id as kurs_id,
        json_array_elements(json_modulinhalte::json -> 'modulinhalt') ->> 'title' as Lerneinheit,
        json_array_elements(json_modulinhalte::json -> 'modulinhalt') ->> 'LfdNummerLerneinheit' as Lerneinheit_Nr
FROM podio.backoffice_fulfillment_components; 