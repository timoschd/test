-- CREATE TRIGGER FUNCTION
CREATE OR REPLACE FUNCTION kc.upsert_massnahmen_teilnehmer()
RETURNS trigger AS
    $BODY$
    BEGIN


    -- DELETE conflicts
    DELETE FROM kc.massnahmen_teilnehmer_zuordnung
    WHERE lead_id IN (SELECT app_item_id FROM podio.sales_management_leads 
            WHERE last_event_on > (SELECT max(last_event_on) FROM kc.massnahmen_teilnehmer_zuordnung)
            );
    -- UPSERT of newer entries
    INSERT INTO kc.massnahmen_teilnehmer_zuordnung
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
		   WHERE massnahmen_id_sales IN (SELECT massnahmen_id_sales FROM kc.massnahmen) 
           AND  (last_event_on > (SELECT max(last_event_on) FROM kc.massnahmen_teilnehmer_zuordnung) OR lead_id NOT IN (SELECT lead_id FROM kc.massnahmen_teilnehmer_zuordnung))

    ON CONFLICT (lead_id, massnahmen_id_sales)
    DO NOTHING;

    RETURN NULL;
    END;

    $BODY$
LANGUAGE plpgsql;

--Upsert function for teilnehmer and massnahmen_teilnehmer
CREATE OR REPLACE FUNCTION kc.upsert_teilnehmer_and_massnahmen_teilnehmer()
RETURNS trigger AS
    $BODY$
    BEGIN
	perform upsert_teilnehmer();
	perform upsert_massnahmen_teilnehmer();

    RETURN NULL;
    END;

    $BODY$
LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trig_upsert_teilnehmer_and_massnahmen_teilnehmer ON podio.sales_management_leads;

-- trigger on base podio table with function
CREATE TRIGGER trig_upsert_teilnehmer_and_massnahmen_teilnehmer
    AFTER INSERT OR UPDATE ON podio.sales_management_leads
    FOR EACH STATEMENT
    EXECUTE PROCEDURE kc.upsert_teilnehmer_and_massnahmen_teilnehmer();



-- check triggers
SELECT * FROM information_schema.triggers;







