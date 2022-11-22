-- delete view
DROP VIEW IF EXISTS sc.leads;
-- create view
CREATE VIEW sc.leads AS (
	SELECT 
		"Leads"."Id"::bigint,
		"Leads"."Lead Status"::text as lead_status,
		NULL::text as deal_stufe,
		"Leads"."Created Time"::date as datum,
		"Leads"."Art der Maßnahme"::text as art_der_massnahme,
		"Leads"."Owner Name"::text as lead_besitzer,
		NULL::text as deal_besitzer,
		NULL::numeric as betrag,
		NULL::integer as closing_dauer,
		NULL::boolean as deal_geclosed,
		'Lead' as typ,
		-- calc first day of week (from created time)
		date_trunc('week', "Leads"."Created Time"::date) as weekstart,
		to_char("Leads"."Created Time"::date, 'IYYY-IW') as woche,
		to_char("Leads"."Created Time"::date, 'IYYY-MM') as monat
	FROM zoho."Leads");
-- set owner 
ALTER TABLE sc.leads OWNER TO read_only;