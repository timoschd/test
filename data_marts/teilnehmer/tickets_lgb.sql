--CREATE TABLE for tickets
CREATE TABLE tc.tickets_lgb AS
SELECT app_item_id AS ticket_id,
	lgb_ticket_id::integer,
	created_on::date AS startdatum,
	(cast(ticket_geschlossen_wann AS JSON)->>'start_date')::date AS enddatum,
	cast(ticket_status AS JSON)->>'text' AS status,
	ticket_laufzeit_in_stunden::numeric,
	cast(bearbeiter AS JSON)->>'name' as bearbeiter,
	cast(prioritat as json)->>'text' as prioritaet,
	cast(herkunft as json)->>'text' as herkunft,
	cast(beschwerde as json)->>'text' as beschwerde,
	ticketart->>'text' AS ticketart,
	cast(first_level_ticket as json)->>'text' as first_level_ticket,
	COALESCE(customer_support, anmeldung, prufungsmanagement, techsupport, beschwerde, weitere_kategorien) as kategorie,
	cast(customer_support as json)->>'text' as customer_support,
	cast(anmeldung as json)->>'text' as anmeldung,
	cast(prufungsmanagement as json)->>'text' as prufungsmanagement,
	cast(techsupport as json)->>'text' as techsupport,
	cast(weitere_kategorien as json)->>'text' as weitere_kategorien,
	last_event_on
FROM podio.backoffice_lgb_tickets;

-- Set Key
ALTER TABLE tc.tickets_lgb
    ADD PRIMARY KEY (ticket_id);

-- Set Owner
ALTER TABLE tc.tickets_lgb
    OWNER TO read_only;