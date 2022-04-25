DROP VIEW IF EXISTS kc.kunden_kurs_umsatz_pro_tag;
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
	 	teilnehmer_kurs_zuordnung.kurs_id_backoffice as kurs_id,
		teilnehmer_kurs_zuordnung.status as kstatus,
		teilnehmer_kurs_zuordnung.startdatum as kstart,
		teilnehmer_kurs_zuordnung.enddatum as kende,
		teilnehmer_kurs_zuordnung.abbruch_datum as kabbruch,
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
		teilnehmer_kurs_zuordnung.tutor_id as ktid
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
		(kmk_gesamt_eindeutig.mgebuehr / (COUNT(kmk_gesamt_eindeutig.kurs_id) OVER (PARTITION BY kmk_gesamt_eindeutig.lead_id, kmk_gesamt_eindeutig.mid))) as kurs_gebuehr,
		kmk_gesamt_eindeutig.kurs_id,
		kmk_gesamt_eindeutig.ktitel as kurs_titel,
		teilnehmer_gesamt.kstatus as kurs_status,
		teilnehmer_gesamt.kstart as startdatum_kurs,
		teilnehmer_gesamt.kende as enddatum_kurs,
		teilnehmer_gesamt.kabbruch as abbruchdatum,
		(CASE 
		 WHEN teilnehmer_gesamt.calcabbruch IS NULL
		 THEN kmk_gesamt_eindeutig.bgs_ende
		 ELSE teilnehmer_gesamt.calcabbruch
		 END) as calcabbruch, 
		 -- wenn abbruch und abbruch vor kursende dann abbruchdatum sonst kursende 
		 (CASE
		  WHEN teilnehmer_gesamt.calcabbruch IS NOT NULL AND teilnehmer_gesamt.calcabbruch < teilnehmer_gesamt.kende
		  THEN teilnehmer_gesamt.calcabbruch
		  ELSE teilnehmer_gesamt.kende
		  END) as calcende,
		(teilnehmer_gesamt.kende - teilnehmer_gesamt.kstart) as tage_im_kurs_geplant,
		teilnehmer_gesamt.ktutor as name_dozent,
		teilnehmer_gesamt.ktid as dozent_id
	FROM kmk_gesamt_eindeutig
	FULL JOIN teilnehmer_gesamt ON kmk_gesamt_eindeutig.lead_id = teilnehmer_gesamt.lead_id AND kmk_gesamt_eindeutig.kurs_id = teilnehmer_gesamt.kurs_id
	),

-- berechne abbruchtag
all_ber_abbruchtag AS (
SELECT 	*,
		(min(kmk_mit_tn.calcabbruch) OVER(PARTITION BY kmk_mit_tn.lead_id)) as abbruchtag
	FROM kmk_mit_tn
),

--berechne zahlungsende
all_ber_zahlungsende AS (
SELECT 	*,
		-- wenn calcende vor start oder calcende nach ende = tatsächliche Tage im kurs
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
		(sum(all_ber_abbruchtag.kurs_gebuehr) OVER(PARTITION BY all_ber_abbruchtag.lead_id )) as lead_gebuehr
	FROM all_ber_abbruchtag
),
-- berechne raten
all_ber_raten AS(
SELECT 	*,
		SUM(all_ber_zahlungsende.tage_im_kurs_geplant) OVER(PARTITION BY all_ber_zahlungsende.lead_id, all_ber_zahlungsende.massnahmen_id_sales) as tage_in_massnahme_geplant,
		ROUND((all_ber_zahlungsende.zahlungsende - all_ber_zahlungsende.startdatum_bgs) / 30.25) as raten,
		ROUND((all_ber_zahlungsende.enddatum_bgs - all_ber_zahlungsende.startdatum_bgs) / 30.25) as raten_geplant,
		(CASE WHEN (all_ber_zahlungsende.lead_gebuehr <> 0 AND (ROUND((all_ber_zahlungsende.enddatum_bgs - all_ber_zahlungsende.startdatum_bgs) / 30.25)) <> 0) THEN (all_ber_zahlungsende.lead_gebuehr / ROUND((all_ber_zahlungsende.enddatum_bgs - all_ber_zahlungsende.startdatum_bgs) / 30.25)) ELSE 0 END) as betrag_rate,
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
		all_ber_raten.abbruchtag,
		all_ber_raten.name_dozent,
		all_ber_raten.dozent_id,
		all_ber_raten.tage_im_kurs,
		all_ber_raten.tage_im_kurs_geplant,
		all_ber_raten.tage_in_massnahme_geplant,
		all_ber_raten.raten_geplant,
		all_ber_raten.zahlungsende,
		all_ber_raten.raten,
		all_ber_raten.betrag_rate,
		(all_ber_raten.raten * all_ber_raten.betrag_rate) as umsatz,
		(all_ber_raten.raten_geplant * all_ber_raten.betrag_rate) as umsatz_geplant
	FROM all_ber_raten 
	)
SELECT 	*,
		(all_ber_umsatz.massnahme_anteil_umsatz * all_ber_umsatz.umsatz) as umsatz_massnahme,
		(CASE WHEN(all_ber_umsatz.umsatz <> 0 AND all_ber_umsatz.tage_in_massnahme_geplant <> 0) THEN (all_ber_umsatz.massnahme_anteil_umsatz * all_ber_umsatz.umsatz) / all_ber_umsatz.tage_in_massnahme_geplant ELSE 0 END) as umsatz_pro_tag
	FROM all_ber_umsatz;
	
-- SET OWNER TO READ_ONLY
ALTER TABLE kc.kunden_kurs_umsatz_pro_tag
    OWNER TO read_only;


	