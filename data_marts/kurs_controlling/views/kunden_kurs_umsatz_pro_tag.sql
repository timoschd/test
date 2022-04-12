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
		massnahme_kurs_zuordnung.kurs_titel as ktitel,
		massnahme_kurs_zuordnung.kurs_fachbereich as kfb
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
		kmk_gesamt.ktitel,
		kmk_gesamt.kfb
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
		 -- 6 verschiedene fälle für falsches bzw kein abbruchdatum
		 WHEN teilnehmer_kurs_zuordnung.status = 'Abbruch vor LG-Start' AND teilnehmer_kurs_zuordnung.abbruch_datum IS NULL THEN (teilnehmer_kurs_zuordnung.startdatum - 1)
		 WHEN teilnehmer_kurs_zuordnung.status = 'Abbruch vor LG-Start' AND teilnehmer_kurs_zuordnung.abbruch_datum > teilnehmer_kurs_zuordnung.startdatum THEN (teilnehmer_kurs_zuordnung.startdatum - 1)		
		 WHEN teilnehmer_kurs_zuordnung.status = 'Abbruch nach LG-Start' AND teilnehmer_kurs_zuordnung.abbruch_datum IS NULL THEN (teilnehmer_kurs_zuordnung.startdatum + 1)                                         
		 WHEN teilnehmer_kurs_zuordnung.status = 'Abbruch nach LG-Start' AND teilnehmer_kurs_zuordnung.abbruch_datum < teilnehmer_kurs_zuordnung.startdatum THEN (teilnehmer_kurs_zuordnung.startdatum + 1)                                         		
		 WHEN teilnehmer_kurs_zuordnung.status = 'Abbruch nach aktuellem Lehrgang' AND teilnehmer_kurs_zuordnung.abbruch_datum IS NULL THEN (teilnehmer_kurs_zuordnung.enddatum + 1)
		 WHEN teilnehmer_kurs_zuordnung.status = 'Abbruch nach aktuellem Lehrgang' AND teilnehmer_kurs_zuordnung.abbruch_datum < teilnehmer_kurs_zuordnung.enddatum THEN (teilnehmer_kurs_zuordnung.enddatum + 1)
		 ELSE teilnehmer_kurs_zuordnung.enddatum
		 END) as calcende,
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
		kmk_gesamt_eindeutig.kurs_id,
		kmk_gesamt_eindeutig.ktitel as kurs_titel,
		kmk_gesamt_eindeutig.kfb as fachbereich,
		teilnehmer_gesamt.kstatus as kurs_status,
		teilnehmer_gesamt.kstart as startdatum_kurs,
		teilnehmer_gesamt.kende as enddatum_kurs,
		teilnehmer_gesamt.kabbruch as abbruchdatum,
		teilnehmer_gesamt.calcende as calc_enddatum,
		-- wenn calcende vor start oder calcende nach ende
		(CASE 
		 WHEN teilnehmer_gesamt.calcende < teilnehmer_gesamt.kstart THEN 0
		 WHEN teilnehmer_gesamt.calcende > teilnehmer_gesamt.kende THEN (teilnehmer_gesamt.kende - teilnehmer_gesamt.kstart)
		 ELSE (teilnehmer_gesamt.calcende - teilnehmer_gesamt.kstart) 
		 END) as tage_im_kurs,
		teilnehmer_gesamt.ktutor as name_dozent,
		teilnehmer_gesamt.ktid as dozent_id,
		-- wenn status irgendwas mit abbruch
		(CASE WHEN teilnehmer_gesamt.kstatus LIKE '%Abbruch%'
		 -- dann (wenn abbruchdate + 2 monate > bgs ende)
		 THEN (CASE WHEN teilnehmer_gesamt.calcende + ('1 month'::interval * 2) > kmk_gesamt_eindeutig.bgs_ende
			   -- (nimm bgs ende)
			   THEN kmk_gesamt_eindeutig.bgs_ende
			   -- (sonst nimm abbruchdate + 2monate)
			   ELSE teilnehmer_gesamt.calcende + ('1 month'::interval * 2) END)
		 -- wenn nicht abbruch dann bgs enddatum
		 ELSE kmk_gesamt_eindeutig.bgs_ende END)::date as zahlungsende	
		--as monatsraten,
		--kmk_gesamt_eindeutig.mgebuehr / as rate
	FROM kmk_gesamt_eindeutig
	FULL JOIN teilnehmer_gesamt ON kmk_gesamt_eindeutig.lead_id = teilnehmer_gesamt.lead_id AND kmk_gesamt_eindeutig.kurs_id = teilnehmer_gesamt.kurs_id
	),
all_mit_raten AS (
SELECT 	*,
		ROUND((zahlungsende - startdatum_bgs) / 30.25) as raten,
		(CASE WHEN ROUND((zahlungsende - startdatum_bgs) / 30.25) > 0
		 THEN (massnahmen_gebuehr / ROUND((zahlungsende - startdatum_bgs) / 30.25))
		 ELSE 0
		 END) as betrag
	FROM kmk_mit_tn
	)
SELECT 	*,
		(all_mit_raten.raten * all_mit_raten.betrag) as umsatz,
		(CASE WHEN all_mit_raten.tage_im_kurs > 0
		 THEN ((all_mit_raten.raten * all_mit_raten.betrag) / all_mit_raten.tage_im_kurs)
		 ELSE 0
		 END) as umsatz_pro_tag
	FROM all_mit_raten
	
-- SET OWNER TO READ_ONLY
ALTER TABLE kc.kunden_kurs_umsatz_pro_tag
    OWNER TO read_only;
	
	
	
	