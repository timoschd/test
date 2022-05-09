--Create Table Bücher-Kurs-Zuordnung
Create TABLE kc.buecher_kurs_zuordnung AS
SELECT
	app_item_id as buch_id_qm,
	item_id as buch_id,
	titel as buch_titel,
	lgb_title as lgb_titel,
	kategorien->>'text' as kategorie,
	cast(json_book as json)->>'author' as autor,
	(auflage_2::numeric)::integer as auflage,
	(jahr_2::numeric)::integer as jahr,
	isbn_2 as isbn,
	kosten_fachliteratur::numeric as buch_kosten,
	(cast(gultig_ab as json)->>'start_date')::date as buch_gultig_ab,
	(cast(gultig_bis as json)->>'start_date')::date as buch_gultig_bis,
	unnest(string_to_array(qm_ffmt_cmt_ids,','::text))::integer as kurs_id_qm,
	(fulfillment_components_id::numeric)::integer as kurs_id_boffice,
	lizenzkosten as buch_lizenzkosten,--kein cast auf nummeric möglich -> bsp:(730,00€ zzgl. MwSt.), buch_nr: 474
	(cast(lizenz_gultigkeit as json)->>'start_date')::date as lizenz_gueltig_ab,
	(cast(lizenz_gultig_bis as json)->>'start_date')::date as lizenz_gueltig_bis,
	cast(lizenzbereiche as json)->>'text' as lizenzbereiche,
	cast(lizenzart as json)->>'text' as lizenzart,
	lizenz_anmerkung as anmerkungen_zur_lizenz,
	last_event_on
FROM podio.qs_bucherliste;

-- SET INDICIES & Create PRIMARY KEY 
ALTER TABLE kc.buecher_kurs_zuordnung ADD PRIMARY KEY (buch_id_qm, kurs_id_qm);

CREATE INDEX ON kc.buecher_kurs_zuordnung (buch_id_qm);
CREATE INDEX ON kc.buecher_kurs_zuordnung (buch_id);
ALTER TABLE kc.buecher_kurs_zuordnung ADD COLUMN id SERIAL;


-- Set forgein constraints
ALTER TABLE kc.buecher_kurs_zuordnung
ADD CONSTRAINT fk_kurs
FOREIGN KEY (kurs_id_qm)
REFERENCES kc.kurse (kurs_id_qm)
DEFERRABLE INITIALLY DEFERRED;

-- Set table owner
ALTER TABLE kc.buecher_kurs_zuordnung OWNER TO read_only;