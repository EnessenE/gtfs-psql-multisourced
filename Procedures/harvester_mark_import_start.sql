DROP PROCEDURE IF EXISTS harvester_mark_import_start(text) ;
DROP PROCEDURE IF EXISTS harvester_mark_import_start(text, text) ;

CREATE OR REPLACE PROCEDURE public.harvester_mark_import_start(__dataorigin text)
LANGUAGE 'plpgsql'
AS $BODY$
BEGIN
    UPDATE supplier_configurations
    SET 
       last_import_start = now()
    WHERE 
        lower(name) = lower(__dataorigin);
END;
$BODY$;

ALTER PROCEDURE public.harvester_mark_import_start(text) OWNER TO dennis;

