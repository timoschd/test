--CREATE TABLE for tickets

CREATE TABLE tc.tickets_zoho AS --ids

SELECT
	id AS ticket_id::int,
	request_id,
	substring(lead, ('\d+$'))::integer AS lead_id_podio,
	substring(fulfillment_übersicht, ('\d+$'))::integer AS teilnehmer_id_backoffice_podio,
	substring(teilnehmer, ('\d+$'))::integer AS teilnehmer_id_tutoren_podio, --ticket daten
 ticket_owner_name AS bearbeiter,
	erstellungszeit::timestamp AS erstellungsdatum,
	modifiziert_zeit::timestamp,	
	fälligkeitsdatum as faelligkeitsdatum,
	status,
	priorität as prioritaet,
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
	customer_response_time::timestamp,
    CASE WHEN anzahl_threads = '' THEN NULL ELSE anzahl_threads::numeric END,
	CASE WHEN "assign_time_(hrs)" = '' THEN NULL ELSE "assign_time_(hrs)"::numeric END as assign_time_hrs,
	CASE WHEN "requester_wait_time_(hrs)" = '' THEN NULL ELSE "requester_wait_time_(hrs)"::numeric END as requester_wait_time_in_hrs,
	CASE WHEN "first_reply_time_(hrs)" = '' THEN NULL ELSE "first_reply_time_(hrs)"::numeric END as first_reply_time_in_hrs,
	CASE WHEN ticket_age_in_days = '' THEN NULL ELSE ticket_age_in_days::numeric END,
	CASE WHEN resolution_time = '' THEN NULL ELSE resolution_time::numeric END,
	CASE WHEN gesamtzeitaufwand = '' THEN NULL ELSE gesamtzeitaufwand::numeric END,
	CASE WHEN lösungszeit_in_geschäftszeiten = '' THEN NULL ELSE lösungszeit_in_geschäftszeiten::numeric END as loesungszeit_in_geschaeftszeiten, 
	CASE WHEN erste_reaktionszeit_in_geschäftszeiten = '' THEN NULL ELSE erste_reaktionszeit_in_geschäftszeiten::numeric END as erste_reaktionszeit_in_geschaeftszeiten,
	CASE WHEN gesamtreaktionszeit_in_geschäftszeiten = '' THEN NULL ELSE gesamtreaktionszeit_in_geschäftszeiten::numeric END as gesamtreaktionszeit_in_geschaeftszeiten,
	CASE WHEN anzahl_reaktionen = '' THEN NULL ELSE anzahl_reaktionen::numeric END,
    CASE WHEN ticket_abschlusszeit = '' THEN NULL ELSE ticket_abschlusszeit::timestamp END,
	CASE WHEN request_reopen_time = '' THEN NULL ELSE request_reopen_time::timestamp END,
	CASE WHEN assigned_time = '' THEN NULL ELSE assigned_time::timestamp END,
	CASE WHEN first_assigned_time = '' THEN NULL ELSE first_assigned_time::timestamp END,
	CASE WHEN agent_antwortzeit = '' THEN NULL ELSE agent_antwortzeit::timestamp END,
	ticket_handling_mode
FROM zoho.desk_tickets
WHERE substring(teilnehmer, ('\d+$'))::integer IN (SELECT teilnehmer_id_tutoren FROM tc.teilnehmer);

-- Set Key

ALTER TABLE tc.tickets_zoho ADD PRIMARY KEY (ticket_id);


ALTER TABLE tc.tickets_zoho ADD CONSTRAINT fk_kunden
FOREIGN KEY (lead_id_podio) REFERENCES kc.kunden (lead_id)
DEFERRABLE INITIALLY DEFERRED;


ALTER TABLE tc.tickets_zoho -- #TODO
ADD CONSTRAINT fk_teilnehmer
FOREIGN KEY (teilnehmer_id_tutoren_podio)
REFERENCES tc.teilnehmer (teilnehmer_id_tutoren)
DEFERRABLE INITIALLY DEFERRED;

--rules for tickets
ALTER TABLE tc.tickets_zoho
ADD CONSTRAINT tickets_zeiten
CHECK (anzahl_threads >= 0 AND
	assign_time_in_hrs >= 0 AND
	requester_wait_time_in_hrs >= 0 AND
	first_reply_time_in_hrs >= 0 AND
	ticket_age_in_days >= 0 AND
	resolution_time >= 0 AND
	gesamtzeitaufwand >= 0 AND
	(customer_response_time >= '2015-01-01' AND customer_response_time <= CURRENT_DATE) AND
	(cast(ticket_abschlusszeit as date) >= '2015-01-01' AND cast(ticket_abschlusszeit as date) <= CURRENT_DATE) AND
	(cast(request_reopen_time as date) >= '2015-01-01' AND cast(request_reopen_time as date) <= CURRENT_DATE) AND
	(cast(assigned_time as date) >= '2015-01-01' AND cast(assigned_time as date) <= CURRENT_DATE) AND
	(cast(first_assigned_time as date) >= '2015-01-01' AND cast(first_assigned_time as date) <= CURRENT_DATE) AND
	(cast(agent_antwortzeit as date) >= '2015-01-01' AND cast(agent_antwortzeit as date) <= CURRENT_DATE) AND
	loesungszeit_in_geschaeftszeiten >= 0 AND
	erste_reaktionszeit_in_geschaeftszeiten >= 0 AND
	gesamtreaktionszeit_in_geschaeftszeiten >= 0 AND
	anzahl_reaktionen >= 0);

-- Set Owner

ALTER TABLE tc.tickets_zoho OWNER TO read_only;