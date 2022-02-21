 -- Create Table massnahmen_teilnehmer_zuordnung
 Create TABLE kc.massnahmen_kunden_zuordnung AS
 WITH temptable AS (
        SELECT sales_management_leads.app_item_id as lead_id,
			(sales_management_leads.startdatum::json ->> 'start_date'::text)::date AS teilnehmer_startdatum,
            sales_management_leads.zeiteinsatz::json ->> 'text'::text AS teilnehmer_zeiteinsatz,
            json_array_elements(sales_management_leads.json_coursedetails::json -> 'Massnahmen'::text) AS massnahmendetails,
            last_event_on
           FROM podio.sales_management_leads
         WHERE sales_management_leads.auftragsdatum IS NOT NULL
		    AND (sales_management_leads.status2::json ->> 'text'::text) <> 'STORNO'::text
		    AND ((startdatum_bildungsgutschein::json ->> 'start_date')::date + ('1 month'::interval * anzahl_monate_bgs::numeric::int) >= '2019-01-01'::date  -- filter entries to all Teilnehmer that participated in 2019 or later
		        OR (startdatum_bildungsgutschein::json ->> 'start_date')::date IS NULL OR anzahl_monate_bgs::numeric::int IS NULL)	
          ), 
		temptable_2 AS (
        SELECT temptable.lead_id,
			temptable.teilnehmer_startdatum,
            temptable.teilnehmer_zeiteinsatz,
            temptable.massnahmendetails ->> 'Titel'::text AS massnahmen_titel,
            temptable.massnahmendetails ->> 'ID'::text AS massnahmen_id_sales,
            (temptable.massnahmendetails ->> 'Ber_Gebühr'::text)::double precision AS massnahmen_gebuhr_nach_bgs,
            round((temptable.massnahmendetails ->> 'Dauer'::text)::numeric)::integer AS massnahmen_dauer_in_wochen,
            row_number() OVER (PARTITION BY temptable.lead_id) AS massnahmen_reihenfolge,
            temptable.last_event_on
           FROM temptable
           ), 
		temptable_3 AS (
        SELECT temptable_2.lead_id,
			temptable_2.teilnehmer_startdatum,
            temptable_2.teilnehmer_zeiteinsatz,
            temptable_2.massnahmen_titel,
            temptable_2.massnahmen_id_sales,
            temptable_2.massnahmen_gebuhr_nach_bgs,
            temptable_2.massnahmen_dauer_in_wochen,
            temptable_2.massnahmen_reihenfolge,
            sum(temptable_2.massnahmen_dauer_in_wochen) OVER (PARTITION BY temptable_2.lead_id ORDER BY temptable_2.massnahmen_reihenfolge) AS massnahmen_dauer_in_wochen_cumsum,
            temptable_2.last_event_on
           FROM temptable_2
           )
		SELECT temptable_3.lead_id,
			temptable_3.teilnehmer_startdatum,
			temptable_3.teilnehmer_zeiteinsatz,
			temptable_3.massnahmen_titel,
			temptable_3.massnahmen_id_sales,
			temptable_3.massnahmen_gebuhr_nach_bgs,
			temptable_3.massnahmen_dauer_in_wochen,
			temptable_3.massnahmen_reihenfolge,
			temptable_3.massnahmen_dauer_in_wochen_cumsum,
			temptable_3.teilnehmer_startdatum + (7 * temptable_3.massnahmen_dauer_in_wochen_cumsum::integer - 7 * temptable_3.massnahmen_dauer_in_wochen) AS massnahmen_startdatum,
            temptable_3.last_event_on
		   FROM temptable_3
		   WHERE massnahmen_id_sales IN (SELECT massnahmen_id_sales FROM kc.massnahmen);
		
-- Set indices & PRIMARY KEY
ALTER TABLE kc.massnahmen_kunden_zuordnung ADD PRIMARY KEY (lead_id, massnahmen_id_sales );

CREATE INDEX ON kc.massnahmen_kunden_zuordnung (lead_id);

CREATE INDEX ON kc.massnahmen_kunden_zuordnung (massnahmen_id_sales);

-- Set FOREIGN KEY
ALTER TABLE kc.massnahmen_kunden_zuordnung
ADD CONSTRAINT fk_lead
FOREIGN KEY (lead_id)
REFERENCES kc.kunden (lead_id)
DEFERRABLE INITIALLY DEFERRED;


ALTER TABLE kc.massnahmen_kunden_zuordnung
ADD CONSTRAINT fk_massnahme
FOREIGN KEY (massnahmen_id_sales) 
REFERENCES kc.massnahmen (massnahmen_id_sales)
DEFERRABLE INITIALLY DEFERRED;

-- Set table owner
ALTER TABLE kc.massnahmen_kunden_zuordnung OWNER TO read_only;
