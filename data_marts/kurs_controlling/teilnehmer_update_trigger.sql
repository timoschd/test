-- -- create trigger fuinctions for teilnehmer table to update entries from raw dataMarts


-- get entries in podio table that are newer than entries in kc table (via timestamp compare)


CREATE FUNCTION kc.upsert_teilnehmer()
RETURNS trigger AS
$BODY$
BEGIN


-- UPSERT of newer entries
DELETE FROM kc.teilnehmer 
WHERE lead_id IN (SELECT app_item_id AS lead_id FROM podio.sales_management_leads 
        WHERE last_event_on > (SELECT max(last_event_on) FROM kc.teilnehmer)
        );

INSERT INTO kc.teilnehmer
SELECT 
app_item_id as lead_id,
kategorien::json ->> 'text' as abrechnungs_kategorie,
(startdatum::json ->> 'start_date')::date as startdatum, 
bildungsgutscheinnummer,
(startdatum_bildungsgutschein::json ->> 'start_date')::date as startdatum_bildungsgutschein,
zeiteinsatz::json ->> 'text' as zeiteinsatz,
anzahl_monate_bgs::numeric::int,
calclehrgangsgebuehren as gebuehren_gesamt,
last_event_on

FROM podio.sales_management_leads
	WHERE sales_management_leads.auftragsdatum IS NOT NULL
		AND (sales_management_leads.status2::json ->> 'text'::text) <> 'STORNO'::text
		AND ((startdatum_bildungsgutschein::json ->> 'start_date')::date + ('1 month'::interval * anzahl_monate_bgs::numeric::int) >= '2019-01-01'::date
		OR (startdatum_bildungsgutschein::json ->> 'start_date')::date IS NULL OR anzahl_monate_bgs::numeric::int IS NULL)
    AND last_event_on > (SELECT max(last_event_on) FROM kc.teilnehmer)		
order by startdatum desc

ON CONFLICT (lead_id)
DO NOTHING;

END;
$BODY$
LANGUAGE plpgsql;





-- trigger on base podio table with function
CREATE TRIGGER kc.trig_upsert_teilnehmer
    AFTER INSERT OR UPDATE ON podio.sales_management_leads
    FOR EACH STATEMENT
    EXECUTE PROCEDURE kc.upsert_teilnehmer();




