--CREATE TRIGGER FUNCTION
CREATE OR REPLACE FUNCTION kc.upsert_dozenten()
RETURNS trigger AS
    $BODY$
    BEGIN

--Insert new entries
INSERT INTO kc.dozenten
SELECT 	mitarbeiterdaten.id::integer as id,
		CONCAT(mitarbeiterdaten.last_name, ', ',mitarbeiterdaten.first_name) as name,
		mitarbeiterdaten.beschäftigungsart::text as vertragsstatus,
		mitarbeiterdaten.fachgruppe::text as fachgruppe,
		mitarbeiterdaten.email::text as mail,
		mitarbeiterdaten.last_modified::date as aktiv_ab,
		mitarbeiterdaten.termination_date::date as aktiv_bis,
		mitarbeiterdaten.last_modified::timestamp as bearbeitet_am,
		mitarbeiterdaten.fix_salary::numeric as gehalt_fix,
		mitarbeiterdaten.hourly_salary::numeric as gehalt_stunde,
		NULL as stunden,
		(qs_dozenteninformationen.verbindung::json->>'app_item_id')::integer as podio_id
	FROM personio.mitarbeiterdaten
	LEFT JOIN podio.qs_dozenteninformationen ON mitarbeiterdaten.email = qs_dozenteninformationen.e_mail
	WHERE last_modified > (SELECT max(bearbeitet_am) FROM kc.dozenten) OR 
	email NOT IN (SELECT mail FROM kc.dozenten)
		
	ON CONFLICT (mail, aktiv_ab)
	DO NOTHING;
	
-- update aktiv bis
UPDATE kc.dozenten 
	SET aktiv_bis = COALESCE(dozenten.aktiv_bis, datum)
	FROM (SELECT item_id, 
		   	lead(bearbeitet_am) OVER (PARTITION BY mail ORDER BY bearbeitet_am) as datum 
		   FROM kc.dozenten) AS b
	WHERE dozenten.item_id = b.item_id;
	
RETURN NULL;
END;

    $BODY$
LANGUAGE plpgsql;

-- drop trigger
DROP TRIGGER IF EXISTS trig_upsert_dozenten ON personio.mitarbeiterdaten; 

-- Create Trigger
CREATE TRIGGER trig_upsert_dozenten
	AFTER INSERT OR UPDATE ON personio.mitarbeiterdaten
	FOR EACH STATEMENT
	EXECUTE PROCEDURE kc.upsert_dozenten();

