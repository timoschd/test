-- Lösche VIEW
DROP VIEW IF EXISTS kc.kunden_kurs_umsatz_pro_tag;
-- Create VIEW 
CREATE VIEW kc.kunden_kurs_umsatz_pro_tag AS
-- kmk - kunden_massnahmen_kurse -> lead_id/kurs_id mit min date ohne dopplungen
WITH kmk_ohne_duplikate AS (
SELECT 	massnahmen_kunden_zuordnung.lead_id,
  	    min(massnahmen_kunden_zuordnung.massnahmen_startdatum) as start_datum,
		massnahme_kurs_zuordnung.kurs_id
	FROM kc.massnahmen_kunden_zuordnung
	JOIN kc.massnahme_kurs_zuordnung ON massnahmen_kunden_zuordnung.massnahmen_id_sales = massnahme_kurs_zuordnung.massnahmen_id_sales
	GROUP BY lead_id, kurs_id
	),
-- kmk gesamt (mit dupes) -> hier alle spalten von kmk
kmk_gesamt AS (
SELECT 	massnahmen_kunden_zuordnung.lead_id,
		massnahmen_kunden_zuordnung.massnahmen_id_sales as mid,
		massnahmen_kunden_zuordnung.massnahmen_startdatum as mstart,
		massnahmen_kunden_zuordnung.massnahmen_titel as mtitel,
		massnahmen_kunden_zuordnung.massnahmen_gebuhr_nach_bgs as mgebuehr,
		massnahmen_kunden_zuordnung.f_startdatum_bgs as bgs_start,
		massnahmen_kunden_zuordnung.f_enddatum_bgs::date as bgs_ende,
		massnahmen_kunden_zuordnung.f_lead_status as lstatus,
		massnahme_kurs_zuordnung.kurs_id,
		massnahme_kurs_zuordnung.kurs_titel as ktitel
	FROM kc.massnahmen_kunden_zuordnung
	LEFT JOIN kc.massnahme_kurs_zuordnung ON massnahmen_kunden_zuordnung.massnahmen_id_sales = massnahme_kurs_zuordnung.massnahmen_id_sales
	),
-- kmk (eindeutig) LEFT JOIN kmk_gesamt on lead, startdate & kurs
kmk_gesamt_eindeutig AS (
SELECT 	kmk_ohne_duplikate.lead_id,
		kmk_ohne_duplikate.start_datum as mstart,
		kmk_ohne_duplikate.kurs_id,
		kmk_gesamt.mid,
		kmk_gesamt.mtitel,
		kmk_gesamt.mgebuehr,
		kmk_gesamt.bgs_start,
		kmk_gesamt.bgs_ende,
		kmk_gesamt.lstatus,
		kmk_gesamt.ktitel
	FROM kmk_ohne_duplikate
	JOIN kmk_gesamt ON kmk_ohne_duplikate.lead_id = kmk_gesamt.lead_id AND kmk_ohne_duplikate.kurs_id = kmk_gesamt.kurs_id AND kmk_ohne_duplikate.start_datum = kmk_gesamt.mstart
),
-- tn gesamt -> hier sind alle spalten von teilnehmer_gesamt
teilnehmer_gesamt AS (
SELECT	teilnehmer.lead_id,
		(CASE
			WHEN teilnehmer_kurs_zuordnung.kurs_titel = 'Social Media Manager Backup' THEN 8
			WHEN teilnehmer_kurs_zuordnung.kurs_titel = 'Professional Scrum Master (PSM I)  Backup' THEN 1717
			WHEN teilnehmer_kurs_zuordnung.kurs_titel = 'ITIL® Foundation Backup' THEN 13
			WHEN teilnehmer_kurs_zuordnung.kurs_titel = 'SAP Foundation Level Backup' THEN 34
			WHEN teilnehmer_kurs_zuordnung.kurs_titel = 'Professional Scrum Master (PSM II) Backup' THEN 1718
			WHEN teilnehmer_kurs_zuordnung.kurs_titel = 'Einführung Online Marketing Backup' THEN 971
			WHEN teilnehmer_kurs_zuordnung.kurs_titel = 'Strategisches Marketingmanagement Backup' THEN 1706
			ELSE teilnehmer_kurs_zuordnung.kurs_id_backoffice END) as kurs_id,
		teilnehmer_kurs_zuordnung.status as kstatus,
		teilnehmer_kurs_zuordnung.startdatum as kstart,
		teilnehmer_kurs_zuordnung.enddatum as kende,
		teilnehmer_kurs_zuordnung.abbruch_datum as kabbruch,
		--gib jedem abbrecher ein datum
		(CASE
		 -- 7 verschiedene fälle für abbruch mit und ohne datum
		 WHEN teilnehmer_kurs_zuordnung.status = 'Abbruch vor LG-Start' AND teilnehmer_kurs_zuordnung.abbruch_datum IS NULL THEN (teilnehmer_kurs_zuordnung.startdatum - 1)
		 WHEN teilnehmer_kurs_zuordnung.status = 'Abbruch vor LG-Start' AND teilnehmer_kurs_zuordnung.abbruch_datum IS NOT NULL THEN teilnehmer_kurs_zuordnung.abbruch_datum		
		 WHEN teilnehmer_kurs_zuordnung.status = 'Abbruch nach LG-Start' AND teilnehmer_kurs_zuordnung.abbruch_datum IS NULL THEN (teilnehmer_kurs_zuordnung.startdatum + 1)                                         
		 WHEN teilnehmer_kurs_zuordnung.status = 'Abbruch nach LG-Start' AND teilnehmer_kurs_zuordnung.abbruch_datum IS NOT NULL THEN teilnehmer_kurs_zuordnung.abbruch_datum                                         		
		 WHEN teilnehmer_kurs_zuordnung.status = 'Abbruch nach aktuellem Lehrgang' AND teilnehmer_kurs_zuordnung.abbruch_datum IS NULL THEN (teilnehmer_kurs_zuordnung.enddatum + 1)
		 WHEN teilnehmer_kurs_zuordnung.status = 'Abbruch nach aktuellem Lehrgang' AND teilnehmer_kurs_zuordnung.abbruch_datum IS NOT NULL THEN teilnehmer_kurs_zuordnung.abbruch_datum
		 WHEN teilnehmer_kurs_zuordnung.status NOT LIKE '%Abbruch%' AND teilnehmer_kurs_zuordnung.abbruch_datum IS NOT NULL THEN teilnehmer_kurs_zuordnung.abbruch_datum
		 END) as calcabbruch,
		teilnehmer_kurs_zuordnung.tutor_name as ktutor,
	-- replace doppelte mitarbeiterids bei dozenten durch eindeutige id
		(CASE
		WHEN teilnehmer_kurs_zuordnung.tutor_id = 7106 THEN 7393 
		WHEN teilnehmer_kurs_zuordnung.tutor_id = 7101 THEN 7453
		WHEN teilnehmer_kurs_zuordnung.tutor_id = 7100 THEN 7371
		WHEN teilnehmer_kurs_zuordnung.tutor_id = 200 THEN 7392
		WHEN teilnehmer_kurs_zuordnung.tutor_id = 565 THEN 7133
		WHEN teilnehmer_kurs_zuordnung.tutor_id = 7167 THEN 7376 
		WHEN teilnehmer_kurs_zuordnung.tutor_id = 513 THEN 7223
		WHEN teilnehmer_kurs_zuordnung.tutor_id = 7093 THEN 7390
		WHEN teilnehmer_kurs_zuordnung.tutor_id = 7165 THEN 7374
		WHEN teilnehmer_kurs_zuordnung.tutor_id = 7131 THEN 7367
		WHEN teilnehmer_kurs_zuordnung.tutor_id = 7107 THEN 7377
		WHEN teilnehmer_kurs_zuordnung.tutor_id = 7171 THEN 7176
		WHEN teilnehmer_kurs_zuordnung.tutor_id NOT IN (7106,7101,7100,200,565,7167,513,7093,7165,7131,7107,7171) THEN teilnehmer_kurs_zuordnung.tutor_id
		END) as ktid
	FROM tc.teilnehmer_kurs_zuordnung
	LEFT JOIN tc.teilnehmer ON teilnehmer_kurs_zuordnung.teilnehmer_id_tutoren = teilnehmer.teilnehmer_id_tutoren
),
-- join kmk mit tn_gesamt (lead,massnahme,kurs mit start, ende und Abbruch)
kmk_mit_tn AS (
SELECT 	kmk_gesamt_eindeutig.lead_id,
		kmk_gesamt_eindeutig.lstatus as lead_status,
		kmk_gesamt_eindeutig.bgs_start as startdatum_bgs,
		kmk_gesamt_eindeutig.bgs_ende as enddatum_bgs,
		kmk_gesamt_eindeutig.mstart as startdatum_massnahme,
		kmk_gesamt_eindeutig.mid as massnahmen_id_sales,
		kmk_gesamt_eindeutig.mtitel as massnahmen_titel,
		kmk_gesamt_eindeutig.mgebuehr as massnahmen_gebuehr,
		--massnahmen gebühr auf kursebene runterberechen (massnahmengebühr gleichmäßig auf alle kurse)
		(kmk_gesamt_eindeutig.mgebuehr / (COUNT(kmk_gesamt_eindeutig.kurs_id) OVER (PARTITION BY kmk_gesamt_eindeutig.lead_id, kmk_gesamt_eindeutig.mid))) as kurs_gebuehr,
		kmk_gesamt_eindeutig.kurs_id,
		kmk_gesamt_eindeutig.ktitel as kurs_titel,
		teilnehmer_gesamt.kstatus as kurs_status,
		teilnehmer_gesamt.kstart as startdatum_kurs,
		teilnehmer_gesamt.kende as enddatum_kurs,
		--berechne claculiertes abbruchdatum auf kursebene
		teilnehmer_gesamt.kabbruch as abbruchdatum,
		(CASE 
		 WHEN teilnehmer_gesamt.calcabbruch IS NULL
		 THEN kmk_gesamt_eindeutig.bgs_ende
		 ELSE teilnehmer_gesamt.calcabbruch
		 END) as calcabbruch, 
		 -- berechne das ende jeden kurses -> wenn abbruch und abbruch vor kursende dann abbruchdatum sonst kursende 
		 (CASE
		  WHEN teilnehmer_gesamt.calcabbruch IS NOT NULL AND teilnehmer_gesamt.calcabbruch < teilnehmer_gesamt.kende
		  THEN teilnehmer_gesamt.calcabbruch
		  ELSE teilnehmer_gesamt.kende
		  END) as calcende,
		-- tage im kurs geplant berechnen
		(teilnehmer_gesamt.kende - teilnehmer_gesamt.kstart) as tage_im_kurs_geplant,
		teilnehmer_gesamt.ktutor as name_dozent,
		teilnehmer_gesamt.ktid as dozent_id
	FROM kmk_gesamt_eindeutig
	FULL JOIN teilnehmer_gesamt ON kmk_gesamt_eindeutig.lead_id = teilnehmer_gesamt.lead_id AND kmk_gesamt_eindeutig.kurs_id = teilnehmer_gesamt.kurs_id
	),
-- join prüfungskosten zu kmk_mit_tn
join_pk AS (
SELECT 	kmk_mit_tn.*,
		kurse.lehrgang_prufung_preis as gebuehren_pruefung,
		kurse.kurs_fachbereich,
		kurse.kurs_fachgruppe
	FROM kmk_mit_tn
	LEFT JOIN kc.kurse ON kmk_mit_tn.kurs_id = kurse.kurs_id
),
-- berechne abbruchtag
all_ber_abbruchtag AS (
SELECT 	*,
		-- gib den Tag an welchem der Teilnehmer abgebrochen hat auf lead ebene
		(min(join_pk.calcabbruch) OVER(PARTITION BY join_pk.lead_id)) as abbruchtag
	FROM join_pk
),

--berechne zahlungsende
all_ber_zahlungsende AS (
SELECT 	*,
		-- berechne tage, welche der tn tatsächlich da war -> wenn calcende vor start oder calcende nach ende = tatsächliche Tage im kurs
		(CASE 
		 WHEN all_ber_abbruchtag.calcende < all_ber_abbruchtag.startdatum_kurs THEN 0
		 WHEN (all_ber_abbruchtag.calcende > all_ber_abbruchtag.startdatum_kurs AND all_ber_abbruchtag.calcende < all_ber_abbruchtag.enddatum_kurs) THEN (all_ber_abbruchtag.calcende - all_ber_abbruchtag.startdatum_kurs)
		 ELSE (all_ber_abbruchtag.enddatum_kurs - all_ber_abbruchtag.startdatum_kurs) 
		 END) as tage_im_kurs,
		--
		-- zahlungsende bei Abbruch = calcabbruch sonst bgs ende
		(CASE
		 -- nur bei abbrechern (abbruch=true)
		 WHEN all_ber_abbruchtag.abbruchtag IS NOT NULL
		 THEN (CASE 
 			   -- Wenn abbruch + 2 Monate > als bgs ende
 			   WHEN all_ber_abbruchtag.abbruchtag + ('1 month'::interval * 2) > all_ber_abbruchtag.enddatum_bgs
 			   -- wenn ja dann bgs ende
 			   THEN all_ber_abbruchtag.enddatum_bgs
			   ELSE all_ber_abbruchtag.abbruchtag + ('1 month'::interval * 2)
			   END)
		 --bei abbruch=false
		 ELSE all_ber_abbruchtag.enddatum_bgs
		 END)::date as zahlungsende,
		 -- summiere alle massnahmengebühren (auf kursebene) auf als lead_gebühr
		(sum(all_ber_abbruchtag.kurs_gebuehr) OVER(PARTITION BY all_ber_abbruchtag.lead_id )) as lead_gebuehr
	FROM all_ber_abbruchtag
),
-- berechne raten
all_ber_raten AS(
SELECT 	*,
		-- berechne geplante tage in massnahme 
		SUM(all_ber_zahlungsende.tage_im_kurs_geplant) OVER(PARTITION BY all_ber_zahlungsende.lead_id, all_ber_zahlungsende.massnahmen_id_sales) as tage_in_massnahme_geplant,
		-- berechne anzahl der tatsächlichen raten
		TRUNC((all_ber_zahlungsende.zahlungsende - all_ber_zahlungsende.startdatum_bgs) / 30.25) as raten,
		--berechne anzahl der geplanten raten
		TRUNC((all_ber_zahlungsende.enddatum_bgs - all_ber_zahlungsende.startdatum_bgs) / 30.25) as raten_geplant,
		-- berechne höhe der raten
		(CASE WHEN (all_ber_zahlungsende.lead_gebuehr <> 0 AND (TRUNC((all_ber_zahlungsende.enddatum_bgs - all_ber_zahlungsende.startdatum_bgs) / 30.25)) <> 0) THEN (all_ber_zahlungsende.lead_gebuehr / TRUNC((all_ber_zahlungsende.enddatum_bgs - all_ber_zahlungsende.startdatum_bgs) / 30.25)) ELSE 0 END) as betrag_rate,
		--berechne anteil des umsatzes pro massnahme
		(CASE WHEN (all_ber_zahlungsende.massnahmen_gebuehr <> 0 AND all_ber_zahlungsende.lead_gebuehr <> 0) THEN (all_ber_zahlungsende.massnahmen_gebuehr / all_ber_zahlungsende.lead_gebuehr) ELSE 0 END) as massnahme_anteil_umsatz
	FROM all_ber_zahlungsende
	),
-- berechne umsatz
all_ber_umsatz AS (
SELECT 	all_ber_raten.lead_id,
		all_ber_raten.lead_status,
		all_ber_raten.startdatum_bgs,
		all_ber_raten.enddatum_bgs,
		all_ber_raten.startdatum_massnahme,
		all_ber_raten.massnahmen_id_sales,
		all_ber_raten.massnahmen_titel,
		all_ber_raten.massnahmen_gebuehr,
		all_ber_raten.massnahme_anteil_umsatz,
		all_ber_raten.kurs_id,
		all_ber_raten.kurs_status,
		all_ber_raten.kurs_titel,
		all_ber_raten.startdatum_kurs,
		all_ber_raten.enddatum_kurs,
		all_ber_raten.calcende,
		(CASE WHEN all_ber_raten.abbruchtag = all_ber_raten.enddatum_bgs THEN NULL ELSE all_ber_raten.abbruchtag END) as abbruchtag,
		all_ber_raten.name_dozent,
		all_ber_raten.dozent_id,
		all_ber_raten.kurs_fachgruppe,
		all_ber_raten.kurs_fachbereich,
		all_ber_raten.gebuehren_pruefung,
		all_ber_raten.tage_im_kurs,
		all_ber_raten.tage_im_kurs_geplant,
		all_ber_raten.tage_in_massnahme_geplant,
		all_ber_raten.raten_geplant,
		all_ber_raten.zahlungsende,
		all_ber_raten.raten,
		all_ber_raten.betrag_rate,
		-- berechne den korrigierten umsatz
		(all_ber_raten.raten * all_ber_raten.betrag_rate) as umsatz,
		-- berechne geplanten umsatz
		(all_ber_raten.raten_geplant * all_ber_raten.betrag_rate) as umsatz_geplant
	FROM all_ber_raten 
	)
SELECT 	*,
		-- berechne umsatz pro Massnahme (anhand verhältniss der massnahme zum umsatz)
		(all_ber_umsatz.massnahme_anteil_umsatz * all_ber_umsatz.umsatz) as umsatz_massnahme,
		-- berechne umsatz pro tag (auf massnahmen ebene)
		(CASE WHEN(all_ber_umsatz.umsatz <> 0 AND all_ber_umsatz.tage_in_massnahme_geplant <> 0) THEN (all_ber_umsatz.massnahme_anteil_umsatz * all_ber_umsatz.umsatz) / all_ber_umsatz.tage_in_massnahme_geplant ELSE 0 END) as umsatz_pro_tag,
		-- berechne geplanten umsatz pro Tag
		(CASE WHEN(all_ber_umsatz.umsatz_geplant <> 0 AND all_ber_umsatz.tage_in_massnahme_geplant <> 0) THEN (all_ber_umsatz.massnahme_anteil_umsatz * all_ber_umsatz.umsatz_geplant) / all_ber_umsatz.tage_in_massnahme_geplant ELSE 0 END) as umsatz_pro_tag_geplant
	FROM all_ber_umsatz;
	
-- SET OWNER TO READ_ONLY
ALTER TABLE kc.kunden_kurs_umsatz_pro_tag
    OWNER TO read_only;


	