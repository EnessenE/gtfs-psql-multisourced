DROP PROCEDURE IF EXISTS harvester_mark_supplier_failed(text) ;

CREATE OR REPLACE PROCEDURE public.harvester_mark_supplier_failed(_target text)
LANGUAGE 'plpgsql'
AS $BODY$
BEGIN
    UPDATE supplier_configurations
    SET 
        last_import_failure = now(),
        state = 'FAILED'
    WHERE 
        lower(name) = lower(_target);
END;
$BODY$;

ALTER PROCEDURE public.harvester_mark_supplier_failed(text) OWNER TO dennis;

