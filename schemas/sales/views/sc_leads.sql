-- delete view
DROP VIEW IF EXISTS sc.leads CASCADE;

-- create view
CREATE VIEW sc.leads AS (
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
		to_char("Created Time"::date, 'IYYY-MM') as monat
	FROM zoho."Leads");
	
-- set owner 
ALTER TABLE sc.leads OWNER TO read_only;