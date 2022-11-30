--Create trigger function for insert newer upcoming_deals
CREATE OR REPLACE FUNCTION sc.upsert_leads()
RETURNS TRIGGER AS
    $BODY$
    BEGIN

	-- delete old entries
    DELETE FROM sc.leads
	WHERE "Id" IN (SELECT "Id" FROM zoho."Leads" WHERE "Modified Time" > (SELECT max(last_event_on) FROM sc.leads)); 

	-- insert new leads 
    INSERT INTO sc.leads
        SELECT 
		    "Id"::bigint,
    		"Lead Status"::text as lead_status,
	    	NULL::text as deal_stufe,   
	    	NULL::integer as deal_stage,
    		"Created Time"::date as datum,
		    "Art der Maßnahme"::text as art_der_massnahme,
		    "Owner Name"::text as lead_besitzer,
		    NULL::text as deal_besitzer,
	    	NULL::numeric as betrag,
    		NULL::boolean as aufnahme_older_7_days,
    		NULL::integer as closing_dauer,
    		NULL::boolean as deal_geclosed,
    		'Lead' as typ,
    		-- calc first day of week (from created time)
    		date_trunc('week', "Created Time"::date) as weekstart,
    		to_char("Created Time"::date, 'IYYY-IW') as woche,
    		to_char("Created Time"::date, 'IYYY-MM') as monat,
			"Modified Time" as last_event_on
    	FROM zoho."Leads"
		WHERE "Id" NOT IN (SELECT "Id" FROM sc.leads)

    ON CONFLICT ("Id")
    DO NOTHING;

	RETURN NULL;
    END;

    $BODY$
LANGUAGE plpgsql;
-- drop trigger
DROP TRIGGER IF EXISTS trig_leads_sc ON zoho."Leads";

-- trigger on base podio table with function
CREATE TRIGGER trig_leads_sc
    AFTER INSERT OR UPDATE ON zoho."Leads"
    FOR EACH STATEMENT
    EXECUTE PROCEDURE sc.upsert_leads();
