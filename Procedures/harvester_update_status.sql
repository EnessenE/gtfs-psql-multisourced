DROP PROCEDURE IF EXISTS harvester_update_status(text) ;
DROP PROCEDURE IF EXISTS harvester_update_status(text, text) ;

CREATE OR REPLACE PROCEDURE public.harvester_update_status(__dataorigin text, __state text)
LANGUAGE 'plpgsql'
AS $BODY$
BEGIN
    UPDATE supplier_configurations
    SET 
       last_import_start = now(),
       state = __state
    WHERE 
        lower(name) = lower(__dataorigin);
END;
$BODY$;

ALTER PROCEDURE public.harvester_update_status(text, text) OWNER TO dennis;

