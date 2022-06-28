-- create table with kurses added to corresponding massnahmen
CREATE TABLE kc.massnahme_kurs_zuordnung AS
WITH temptable AS
	(SELECT app_item_id_formatted AS massnahmen_id_sales,
			titel AS massnahme_titel,
			json_array_elements(json_formnplanning::JSON->'CmpDetails') AS lehrgangsdetails,
			last_event_on
		FROM podio.sales_management_courses)
SELECT	massnahmen_id_sales,
		massnahme_titel,
		(lehrgangsdetails::JSON->>'CmpID')::integer AS kurs_id,
		lehrgangsdetails::JSON->>'Component' AS kurs_titel,
		last_event_on
	FROM temptable;
   
-- Set indices
ALTER TABLE kc.massnahme_kurs_zuordnung ADD PRIMARY KEY (massnahmen_id_sales, kurs_id);
CREATE INDEX ON kc.massnahme_kurs_zuordnung (massnahmen_id_sales);
CREATE INDEX ON kc.massnahme_kurs_zuordnung (kurs_id);


-- Set forgein constraints
ALTER TABLE kc.massnahme_kurs_zuordnung
ADD CONSTRAINT fk_massnahme
FOREIGN KEY (massnahmen_id_sales)
REFERENCES kc.massnahmen (massnahmen_id_sales)
DEFERRABLE INITIALLY DEFERRED;

ALTER TABLE kc.massnahme_kurs_zuordnung
ADD CONSTRAINT fk_kurs
FOREIGN KEY (kurs_id)
REFERENCES kc.kurse (kurs_id)
DEFERRABLE INITIALLY DEFERRED;




-- Set table owner
ALTER TABLE kc.massnahme_kurs_zuordnung OWNER TO read_only;

