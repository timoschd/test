-- Create Table for all tickets ohne zuordnung
CREATE TABLE intern.tickets_ohne_zuordnung AS SELECT
	id::bigint AS ticket_id,
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
FROM zoho.desk_tickets WHERE quelle NOT IN ('Teilnehmer', 'Mitarbeiter') AND teilnehmer = '';
