--CREATE TABLE for tickets

CREATE TABLE tc.tickets_zoho AS --ids

SELECT id AS ticket_id,
	request_id,
	substring(lead, ('\d+$'))::integer AS lead_id_podio,
	substring(fulfillment_übersicht, ('\d+$'))::integer AS teilnehmer_id_backoffice_podio,
	substring(teilnehmer, ('\d+$'))::integer AS teilnehmer_id_tutoren_podio, --ticket daten
 ticket_owner_name AS bearbeiter,
	erstellungszeit AS erstellungsdatum,
	fälligkeitsdatum,
	status,
	priorität,
	sprache,
	quelle, --problem
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
	vd___unterkategorien, --kontaktdaten
 kanal,
	kontakt_id AS kontakt_id_zoho, --zeitdaten
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
FROM zoho.tickets;

-- Set Key

ALTER TABLE tc.tickets_zoho ADD PRIMARY KEY (ticket_id);


ALTER TABLE tc.tickets_zoho ADD CONSTRAINT fk_kunden
FOREIGN KEY (lead_id_podio) REFERENCES kc.kunden (lead_id)
DEFERRABLE INITIALLY DEFERRED;


--ALTER TABLE tc.tickets_zoho -- #TODO
-- ADD CONSTRAINT fk_teilnehmer
--FOREIGN KEY (teilnehmer_id_tutoren_podio) REFERENCES tc.teilnehmer (teilnehmer_id_tutoren)
--DEFERRABLE INITIALLY DEFERRED;

-- Set Owner

ALTER TABLE tc.tickets_zoho OWNER TO read_only;