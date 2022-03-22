-- CREATE TRIGGER FUNCTION
CREATE OR REPLACE FUNCTION tc.upsert_tickets_zoho()
RETURNS trigger AS
    $BODY$
    BEGIN


    -- DELETE conflicts
    DELETE FROM tc.tickets_zoho
    WHERE ticket_id IN (SELECT id AS ticket_id FROM zoho.tickets);
    -- UPSERT of newer entries
    INSERT INTO tc.tickets_zoho
    SELECT id AS ticket_id,
	request_id,
	substring(lead, ('\d+$'))::integer AS lead_id_podio,
	substring(fulfillment_übersicht, ('\d+$'))::integer AS teilnehmer_id_backoffice_podio,
	substring(teilnehmer, ('\d+$'))::integer AS teilnehmer_id_tutoren_podio, 
--ticket daten
	ticket_owner_name AS bearbeiter,
	erstellungszeit AS erstellungsdatum,
	fälligkeitsdatum,
	status,
	priorität,
	sprache,
	quelle, 
--problem
	department_name AS abteilung,
	klassifizierungen,
	kategorie,
	hauptkategorien,
	unterkategorie_1,
	unterkategorie,
	pm___hauptkategorien,
	pm___unterkategorien,
	lgs___hauptkategorien,
	as___hauptkategorien,
	as___unterkategorien,
	vd___hauptkategorien,
	vd___unterkategorien,
--kontaktdaten
	kanal,
	kontakt_id AS kontakt_id_zoho, 
--zeitdaten
	anzahl_threads,
	"assign_time_(hrs)",
	"requester_wait_time_(hrs)",
	"first_reply_time_(hrs)",
	ticket_age_in_days,
	resolution_time,
	gesamtzeitaufwand,
	customer_response_time,
	ticket_abschlusszeit,
	request_reopen_time,
	assigned_time,
	first_assigned_time,
	agent_antwortzeit,
	lösungszeit_in_geschäftszeiten,
	erste_reaktionszeit_in_geschäftszeiten,
	gesamtreaktionszeit_in_geschäftszeiten,
	anzahl_reaktionen,
	ticket_handling_mode
FROM zoho.tickets
WHERE id NOT IN (SELECT ticket_id FROM tc.tickets_zoho)

    ON CONFLICT (ticket_id) 
    DO NOTHING;

    RETURN NULL;
    END;

    $BODY$
LANGUAGE plpgsql;


-- DROP TRIGGER
DROP TRIGGER IF EXISTS trig_upsert_tickets_zoho ON zoho.tickets;

-- CREATE TRIGGER for UPDATE FUNCTION
CREATE TRIGGER trig_upsert_tickets_zoho
    AFTER INSERT OR UPDATE ON zoho.tickets
    FOR EACH STATEMENT
    EXECUTE PROCEDURE tc.upsert_tickets_zoho();