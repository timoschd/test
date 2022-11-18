SELECT tc.teilnehmer_kurs_zuordnung.teilnehmer_id_tutoren, tc.teilnehmer.kontakt_id, lead_id, abrechnung, bildungsgutscheinnummer,
anrede, vorname, nachname, phone, adresse, email, geburtsdatum, land, plz, 
lehrgangs_details_id, kurs_titel, kurs_id_backoffice, startdatum, enddatum, abbruch_datum,  tutor_id, tutor_name 
FROM tc.teilnehmer_kurs_zuordnung
LEFT JOIN tc.teilnehmer ON tc.teilnehmer_kurs_zuordnung.teilnehmer_id_tutoren = tc.teilnehmer.teilnehmer_id_tutoren
LEFT JOIN podio.kontakte_view_pii_teilnehmer ON tc.teilnehmer.kontakt_id = podio.kontakte_view_pii_teilnehmer.kontakt_id
WHERE (kurs_titel ILIKE '%Kaufmann%' or kurs_titel ILIKE '%Fachinformatik%');


