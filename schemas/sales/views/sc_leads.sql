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
		cast("Leads"."Created Time" as date) 
			- cast(date_Part('isodow', cast("Leads"."Created Time" as date)) as integer) 
			+ 1 as weekstart,
		date_part('day', cast("Leads"."Created Time" as date)) as tag,
		date_part('isoweek', cast("Leads"."Created Time" as date)) as woche,
		date_part('month', cast("Leads"."Created Time" as date)) as monat,
		date_part('isoyear', cast("Leads"."Created Time" as date)) as jahr
	FROM zoho."Leads");
-- set owner 
ALTER TABLE sc.leads OWNER TO read_only;