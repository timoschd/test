--Create trigger function for update union_ldc
CREATE OR REPLACE FUNCTION sc.refresh_union_ldc()
RETURNS TRIGGER AS
    $BODY$
    BEGIN

	-- refresh union_ldc
    REFRESH MATERIALIZED VIEW sc.union_ldc_materialized;

	RETURN NULL;
    END;

    $BODY$
LANGUAGE plpgsql;

-- drop trigger
DROP TRIGGER IF EXISTS trig_union_leads ON sc.leads;

-- trigger on base sc leads
CREATE TRIGGER trig_union_leads
    AFTER INSERT OR UPDATE ON sc.leads
    FOR EACH STATEMENT
    EXECUTE PROCEDURE sc.refresh_union_ldc();

-- drop trigger
DROP TRIGGER IF EXISTS trig_union_deals ON sc.deals;

-- trigger on base sc deals
CREATE TRIGGER trig_union_deals
    AFTER INSERT OR UPDATE ON sc.deals
    FOR EACH STATEMENT
    EXECUTE PROCEDURE sc.refresh_union_ldc();

-- drop trigger
DROP TRIGGER IF EXISTS trig_union_closings ON sc.closings;

-- trigger on base sc closings
CREATE TRIGGER trig_union_closings
    AFTER INSERT OR UPDATE ON sc.closings
    FOR EACH STATEMENT
    EXECUTE PROCEDURE sc.refresh_union_ldc();