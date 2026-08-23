DROP PROCEDURE IF EXISTS harvester_import_finished(text) ;
DROP PROCEDURE IF EXISTS harvester_import_finished(text, text) ;

CREATE OR REPLACE PROCEDURE public.harvester_import_finished(__dataorigin text)
LANGUAGE 'plpgsql'
AS $BODY$
BEGIN
    UPDATE supplier_configurations
    SET 
       last_import_success = now(),
       download_pending = false,
       latest_succesfull_import_id = (select queued_import_id from supplier_configurations where lower(name) = lower(__dataorigin) limit 1)
    WHERE 
        lower(name) = lower(__dataorigin);
END;
$BODY$;

ALTER PROCEDURE public.harvester_import_finished(text) OWNER TO dennis;

 