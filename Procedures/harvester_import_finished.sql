DROP PROCEDURE IF EXISTS harvester_import_finished(text) ;
DROP PROCEDURE IF EXISTS harvester_import_finished(text, text) ;

CREATE OR REPLACE PROCEDURE public.harvester_import_finished(__dataorigin text)
LANGUAGE 'plpgsql'
AS $BODY$
BEGIN
    UPDATE supplier_configurations
    SET 
       last_import_success = now(),
       download_pending = false
    WHERE 
        lower(name) = lower(__dataorigin);
END;
$BODY$;

ALTER PROCEDURE public.harvester_import_finished(text) OWNER TO dennis;

