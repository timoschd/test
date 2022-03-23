 -- Create Table massnahmen
Create TABLE kc.massnahmen AS
WITH massnahmen_sales AS
	(SELECT app_item_id AS massnahmen_id_sales_int, -- id ohne CRSE
 			app_item_id_formatted AS massnahmen_id_sales, -- formatted id (bisher in pbi als massnahmen_id_sales)
 			last_event_on AS last_event_on_sales
		FROM podio.sales_management_courses),
	massnahmen_organisation AS
	(SELECT massnahmen_organisation_courses.app_item_id,
			massnahmen_organisation_courses.app_item_id_formatted AS massnahmen_id, -- massnahmen id mit CRSE
 			(massnahmen_organisation_courses.courses_sales_management::JSON ->> 'app_item_id')::integer AS m_id_sales, -- sales massnahmen id für join
 			massnahmen_organisation_courses.titel AS massnahmen_titel,
			massnahmen_organisation_courses.gesamt_status AS massnahme_status,
			massnahmen_organisation_courses.course_status AS erweiterter_status,
			massnahmen_organisation_courses.massnahmen_nr_2,
			massnahmen_organisation_courses.uw AS wochen,
			massnahmen_organisation_courses.ue_2 AS unterrichtseinheiten,
			massnahmen_organisation_courses.dkz_nummer,
			(massnahmen_organisation_courses.gultig_bis_2::JSON ->> 'start_date')::date AS gueltig_bis,
			massnahmen_organisation_courses.calcgebuehren::numeric AS gebuehren,
			massnahmen_organisation_courses.massnahmenbogen_item_id::integer,
			massnahmen_organisation_courses.massnahmenbogen_titel,
			last_event_on
		FROM podio.massnahmen_organisation_courses)
SELECT *
FROM massnahmen_sales
LEFT JOIN massnahmen_organisation ON massnahmen_sales.massnahmen_id_sales_int = massnahmen_organisation.m_id_sales;

		   
  -- Create primary key & not null 
CREATE UNIQUE INDEX ON kc.massnahmen (massnahmen_id);
CREATE UNIQUE INDEX ON kc.massnahmen (massnahmen_id_sales_int);
  
 
ALTER TABLE IF EXISTS kc.massnahmen
    ADD PRIMARY KEY (massnahmen_id_sales);
	


-- Set table owner
ALTER TABLE kc.massnahmen OWNER TO read_only;



