-- -- create trigger fuinctions for teilnehmer table to update entries from raw dataMarts


-- get entries in podio table that are newer than entries in kc table (via timestamp compare)

CREATE OR REPLACE FUNCTION kc.upsert_teilnehmer()
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
	        sales_management_leads.kontakt_backoffice::JSON ->> 'app_item_id'::text AS kontakt_id,
        	sales_management_leads.angebots_produkte::JSON ->> 'app_item_id'::text AS angbots_produkt_id,
        	kategorien::JSON ->> 'text' AS abrechnungs_kategorie,
            (startdatum::JSON ->> 'start_date')::date AS startdatum,
        	bildungsgutscheinnummer,
        	sales_management_leads.account_backoffice::JSON ->> 'title'::text AS agentur_stelle,
	        (startdatum_bildungsgutschein::JSON ->> 'start_date')::date AS startdatum_bildungsgutschein,
	        sales_management_leads.berufsklassifikation::JSON ->> 'title'::text AS berufsklassifikation,
	        zeiteinsatz::JSON ->> 'text' AS zeiteinsatz,
        	anzahl_monate_bgs::numeric::int,
        	calclehrgangsgebuehren AS gebuehren_gesamt,
	        last_event_on
        FROM podio.sales_management_leads
            WHERE sales_management_leads.auftragsdatum IS NOT NULL
                AND (sales_management_leads.status2::json ->> 'text'::text) <> 'STORNO'::text
                AND ((startdatum_bildungsgutschein::json ->> 'start_date')::date + ('1 month'::interval * anzahl_monate_bgs::numeric::int) >= '2019-01-01'::date
                OR (startdatum_bildungsgutschein::json ->> 'start_date')::date IS NULL OR anzahl_monate_bgs::numeric::int IS NULL)
            AND (last_event_on > (SELECT max(last_event_on) FROM kc.kunden)	OR app_item_id NOT IN (SELECT lead_id FROM kc.kunden))
        order by startdatum desc

    ON CONFLICT (lead_id)
    DO NOTHING;

    END;

    $BODY$
LANGUAGE plpgsql;

--Upsert function for teilnehmer and massnahmen_teilnehmer to fix execution order
CREATE OR REPLACE FUNCTION kc.upsert_teilnehmer_and_massnahmen_teilnehmer()
RETURNS TRIGGER AS
    $BODY$
    BEGIN
	perform kc.upsert_teilnehmer();
	perform kc.upsert_massnahmen_teilnehmer();

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







