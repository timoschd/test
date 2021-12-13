 -- Create Table massnahmen_teilnehmer_zuordnung
 Create TABLE kc.massnahmen_teilnehmer_zuordnung AS
 WITH temptable AS (
        SELECT sales_management_leads.app_item_id as lead_id,
			sales_management_leads.kontakte_nachname as teilnehmer_nachname,
			sales_management_leads.kontakte_vorname as teilnehmer_vorname,
            (sales_management_leads.startdatum::json ->> 'start_date'::text)::date AS teilnehmer_startdatum,
            sales_management_leads.zeiteinsatz::json ->> 'text'::text AS teilnehmer_zeiteinsatz,
            json_array_elements(sales_management_leads.json_coursedetails::json -> 'Massnahmen'::text) AS massnahmendetails
           FROM podio.sales_management_leads
          WHERE sales_management_leads.auftragsdatum IS NOT NULL AND sales_management_leads.created_on >= '2019-01-01'::date AND (sales_management_leads.status2::json ->> 'text'::text) <> 'STORNO'::text), 
		temptable_2 AS (
        SELECT temptable.lead_id,
			temptable.teilnehmer_vorname,
			temptable.teilnehmer_nachname,
            temptable.teilnehmer_startdatum,
            temptable.teilnehmer_zeiteinsatz,
            temptable.massnahmendetails ->> 'Titel'::text AS massnahmen_titel,
            temptable.massnahmendetails ->> 'ID'::text AS massnahmen_id,
            (temptable.massnahmendetails ->> 'Ber_Gebühr'::text)::double precision AS massnahmen_ber_gebuhr,
            round((temptable.massnahmendetails ->> 'Dauer'::text)::numeric)::integer AS massnahmen_dauer_in_wochen,
            row_number() OVER (PARTITION BY temptable.lead_id) AS massnahmen_reihenfolge
           FROM temptable), 
		temptable_3 AS (
        SELECT temptable_2.lead_id,
			temptable_2.teilnehmer_vorname,
			temptable_2.teilnehmer_nachname,
            temptable_2.teilnehmer_startdatum,
            temptable_2.teilnehmer_zeiteinsatz,
            temptable_2.massnahmen_titel,
            temptable_2.massnahmen_id,
            temptable_2.massnahmen_ber_gebuhr,
            temptable_2.massnahmen_dauer_in_wochen,
            temptable_2.massnahmen_reihenfolge,
            sum(temptable_2.massnahmen_dauer_in_wochen) OVER (PARTITION BY temptable_2.lead_id ORDER BY temptable_2.massnahmen_reihenfolge) AS massnahmen_dauer_in_wochen_cumsum
           FROM temptable_2)
		SELECT temptable_3.lead_id,
			temptable_3.teilnehmer_vorname,
			temptable_3.teilnehmer_nachname,
			temptable_3.teilnehmer_startdatum,
			temptable_3.teilnehmer_zeiteinsatz,
			temptable_3.massnahmen_titel,
			temptable_3.massnahmen_id,
			temptable_3.massnahmen_ber_gebuhr,
			temptable_3.massnahmen_dauer_in_wochen,
			temptable_3.massnahmen_reihenfolge,
			temptable_3.massnahmen_dauer_in_wochen_cumsum,
			temptable_3.teilnehmer_startdatum + (7 * temptable_3.massnahmen_dauer_in_wochen_cumsum::integer - 7 * temptable_3.massnahmen_dauer_in_wochen) AS massnahmen_startdatum
		   FROM temptable_3;
		
 -- Set indices & PRIMARY KEY
 ALTER TABLE kc.massnahmen_teilnehmer_zuordnung ADD COLUMN id SERIAL PRIMARY KEY;
 CREATE INDEX ON kc.massnahmen_teilnehmer_zuordnung (lead_id);

 -- Set FOREIGN KEY
 ALTER TABLE kc.massnahmen_teilnehmer_zuordnung
 ADD CONSTRAINT fk_lead
 FOREIGN KEY (lead_id)
 REFERENCES kc.teilnehmer (lead_id);
 
 ALTER TABLE kc.massnahmen_teilnehmer_zuordnung
 ADD CONSTRAINT fk_massnahme
 FOREIGN KEY (massnahmen_id)
 REFERENCES kc.massnahmen (massnahme_id);