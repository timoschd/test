-- -- create trigger fuinctions for teilnehmer table to update entries from raw dataMarts


-- get entries in podio table that are newer than entries in kc table (via timestamp compare)

CREATE OR REPLACE FUNCTION kc.upsert_kunden()
RETURNS void AS
    $BODY$
    BEGIN

    -- UPSERT of newer entries
    DELETE FROM kc.kunden 
    WHERE lead_id IN 
        (SELECT app_item_id AS lead_id FROM podio.sales_management_leads 
            WHERE last_event_on > (SELECT max(last_event_on) FROM kc.kunden)
        );

    INSERT INTO kc.kunden
        SELECT app_item_id AS lead_id,
        	sales_management_leads.auftragsberechnungen::JSON ->> 'app_item_id'::text AS auftragsberechnungen_id,
	        (sales_management_leads.auftragsdatum::JSON ->>'start_date')::date as auftragsdatum,
        	sales_management_leads.kontakt_backoffice::JSON ->> 'app_item_id'::text AS kontakt_id,
        	sales_management_leads.angebots_produkte::JSON ->> 'app_item_id'::text AS angbots_produkt_id,
        	kategorien::JSON ->> 'text' AS abrechnungs_kategorie,
        	(startdatum::JSON ->> 'start_date')::date AS startdatum,
        	bildungsgutscheinnummer,
        	sales_management_leads.account_backoffice::JSON ->> 'title'::text AS agentur_stelle,
        	(startdatum_bildungsgutschein::JSON ->> 'start_date')::date AS startdatum_bildungsgutschein,
           	((startdatum_bildungsgutschein::JSON ->> 'start_date')::date + ('1 month'::interval * anzahl_monate_bgs::numeric::int)) as enddatum_bildungsgutzschein,
        	(sales_management_leads.status2::JSON ->> 'text'::text) as status,
        	sales_management_leads.berufsklassifikation::JSON ->> 'title'::text AS berufsklassifikation,
        	zeiteinsatz::JSON ->> 'text' AS zeiteinsatz,
        	anzahl_monate_bgs::numeric::int,
        	calclehrgangsgebuehren AS gebuehren_gesamt,
        	last_event_on
        FROM podio.sales_management_leads
		WHERE (last_event_on > (SELECT max(last_event_on) FROM kc.kunden) OR lead_id NOT IN (SELECT lead_id FROM kc.kunden))

    ON CONFLICT (lead_id)
    DO NOTHING;

    END;

    $BODY$
LANGUAGE plpgsql;

-- CREATE TRIGGER FUNCTION
CREATE OR REPLACE FUNCTION kc.upsert_massnahmen_kunden()
RETURNS void AS
    $BODY$
    BEGIN


    -- DELETE conflicts
    DELETE FROM kc.massnahmen_kunden_zuordnung
    WHERE lead_id IN (SELECT app_item_id FROM podio.sales_management_leads 
            WHERE last_event_on > (SELECT max(last_event_on) FROM kc.massnahmen_kunden_zuordnung)
            );
    -- UPSERT of newer entries
    INSERT INTO kc.massnahmen_kunden_zuordnung
     WITH temptable AS (
        SELECT sales_management_leads.app_item_id as lead_id,
			(sales_management_leads.startdatum::json ->> 'start_date'::text)::date AS teilnehmer_startdatum,
            sales_management_leads.zeiteinsatz::json ->> 'text'::text AS teilnehmer_zeiteinsatz,
            json_array_elements(sales_management_leads.json_coursedetails::json -> 'Massnahmen'::text) AS massnahmendetails,
            last_event_on
           FROM podio.sales_management_leads
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
		   WHERE (last_event_on > (SELECT max(last_event_on) FROM kc.massnahmen_kunden_zuordnung) OR lead_id NOT IN (SELECT lead_id FROM kc.massnahmen_kunden_zuordnung))

    ON CONFLICT (lead_id, massnahmen_id_sales)
    DO NOTHING;

    END;

    $BODY$
LANGUAGE plpgsql;

--Upsert function for teilnehmer and massnahmen_teilnehmer to fix execution order
CREATE OR REPLACE FUNCTION kc.upsert_kunden_and_massnahmen_kunden()
RETURNS TRIGGER AS
    $BODY$
    BEGIN
	perform kc.upsert_kunden();
	perform kc.upsert_massnahmen_kunden();

    RETURN NULL;
    END;

    $BODY$
LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trig_upsert_kunden_and_massnahmen_kunden ON podio.sales_management_leads;

-- trigger on base podio table with function
CREATE TRIGGER trig_upsert_kunden_and_massnahmen_kunden
    AFTER INSERT OR UPDATE ON podio.sales_management_leads
    FOR EACH STATEMENT
    EXECUTE PROCEDURE kc.upsert_kunden_and_massnahmen_kunden();
