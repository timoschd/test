CREATE VIEW sc.leads AS (
	SELECT 
		"Leads"."Id",
		"Leads"."Lead Status" as lead_status,
		NULL as deal_stufe,
		"Leads"."Created Time" as datum,
		"Leads"."Art der Maßnahme" as art_der_massnahme,
		"Leads"."Owner Name" as lead_besitzer,
		NULL as deal_besitzer,
		NULL as betrag,
		NULL as closing_dauer,
		NULL as daal_geclosed,
		'Lead' as typ,
		-- calc first day of week (from created time)
		cast("Leads"."Created Time" as date) 
			- cast(date_Part('isodow', cast("Leads"."Created Time" as date)) as integer) 
			+ 1 as weekstart
	FROM zoho."Leads")
	