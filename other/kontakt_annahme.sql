-- CREATE extension for customer_data_platform
CREATE EXTENSION IF NOT EXISTS postgres_fdw WITH SCHEMA lead_tracking;
-- CREATE server for data_warehouse
CREATE SERVER podio_data FOREIGN DATA WRAPPER postgres_fdw OPTIONS( dbname 'data_warehouse' );
-- CREATE USER-MAPPING for podio_data -> rwx_user
CREATE USER MAPPING FOR rwx_user SERVER podio_data OPTIONS ( user 'rwx_user', password '' );
-- CREATE FOREIGN TABLE kontakt_annahme
CREATE FOREIGN TABLE lead_tracking.kontakt_annahme (app_item_id integer,
													kontakt json,
													leads json,
													eingegangen_um json,
													lead_owner json,
													aktion json,
													unqualifiziert_detail text,
													art_der_anfrage json,
													account_art text,
													email text,
													calculation_2 text,
													last_event_on timestamp) 
SERVER podio_data OPTIONS(schema_name 'podio', table_name 'sales_management_kontakt_annahme');
-- SHOW table kontakt_annahme
SELECT * FROM lead_tracking.kontakt_annahme LIMIT 10;
-- CREATE TABLE in SCHEMA lead_tracking
CREATE TABLE lead_tracking.kontakt_annahme AS
SELECT app_item_id,
 	cast(kontakt AS JSON) ->> 'app_item_id' AS kontakt_id,
 	cast(leads AS JSON) ->> 'app_item_id' AS lead_id,
 	cast(eingegangen_um AS JSON) ->> 'start_date' AS eingangsdatum,
 	cast(lead_owner AS JSON) ->> 'name' AS lead_besitzer,
 	cast(aktion AS JSON) ->> 'text' AS anfrage_status,
 	cast(unqualifiziert_detail AS JSON) ->> 'text' AS unqualifiziert_detail,
 	cast(art_der_anfrage AS JSON) ->> 'text' AS herkunft,
 	cast(account_art AS JSON) ->> 'text' AS account_art,
 	email,
 	calculation_2 AS telefon,
 	last_event_on
FROM lead_tracking.podio_kontakt_annahme