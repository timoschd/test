--Create trigger function for insert newer leads
CREATE OR REPLACE FUNCTION sc.upsert_union_leads()
RETURNS TRIGGER AS
    $BODY$
    BEGIN

	-- delete old entries
    DELETE FROM sc.union_test
    WHERE "Id" IN (SELECT "Id" FROM sc.Leads WHERE last_event_on > (SELECT max(last_event_on) FROM sc.union_test WHERE typ = 'Lead')); 

	-- insert new leads 
    INSERT INTO sc.union_test
        SELECT  
		        *
    	FROM sc.leads
		WHERE "Id" NOT IN (SELECT "Id" FROM sc.union_test WHERE typ = 'Lead')

    ON CONFLICT ("Id", typ)
    DO NOTHING;

	RETURN NULL;
    END;

    $BODY$
LANGUAGE plpgsql;
-- drop trigger
DROP TRIGGER IF EXISTS trig_union_leads ON sc.leads;

-- trigger on base podio table with function
CREATE TRIGGER trig_union_leads
    AFTER INSERT OR UPDATE ON sc.leads
    FOR EACH STATEMENT
    EXECUTE PROCEDURE sc.upsert_union_leads();

--#################################################################################
--Create trigger function for insert newer deals
CREATE OR REPLACE FUNCTION sc.upsert_union_deals()
RETURNS TRIGGER AS
    $BODY$
    BEGIN

	-- delete old entries
    DELETE FROM sc.union_test
    WHERE "Id" IN (SELECT "Id" FROM sc.deals WHERE last_event_on > (SELECT max(last_event_on) FROM sc.union_test WHERE typ = 'Deal')); 

	-- insert new deals 
    INSERT INTO sc.union_test
        SELECT  
		        *
    	FROM sc.deals
		WHERE "Id" NOT IN (SELECT "Id" FROM sc.union_test WHERE typ = 'Deal')

    ON CONFLICT ("Id", typ)
    DO NOTHING;

	RETURN NULL;
    END;

    $BODY$
LANGUAGE plpgsql;
-- drop trigger
DROP TRIGGER IF EXISTS trig_union_deals ON sc.deals;

-- trigger on base podio table with function
CREATE TRIGGER trig_union_deals
    AFTER INSERT OR UPDATE ON sc.deals
    FOR EACH STATEMENT
    EXECUTE PROCEDURE sc.upsert_union_deals();

--##################################################################################################
--Create trigger function for insert newer closings
CREATE OR REPLACE FUNCTION sc.upsert_union_closings()
RETURNS TRIGGER AS
    $BODY$
    BEGIN

	-- delete old entries
    DELETE FROM sc.union_test
    WHERE "Id" IN (SELECT "Id" FROM sc.closings WHERE last_event_on > (SELECT max(last_event_on) FROM sc.union_test WHERE typ = 'Closing')); 

	-- insert new closings 
    INSERT INTO sc.union_test
        SELECT  
		        *
    	FROM sc.closings
		WHERE "Id" NOT IN (SELECT "Id" FROM sc.union_test WHERE typ = 'Closing')

    ON CONFLICT ("Id", typ)
    DO NOTHING;

	RETURN NULL;
    END;

    $BODY$
LANGUAGE plpgsql;
-- drop trigger
DROP TRIGGER IF EXISTS trig_union_closings ON sc.closings;

-- trigger on base podio table with function
CREATE TRIGGER trig_union_closings
    AFTER INSERT OR UPDATE ON sc.closings
    FOR EACH STATEMENT
    EXECUTE PROCEDURE sc.upsert_union_closings();