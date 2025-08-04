DROP PROCEDURE IF EXISTS filedetector_mark_failed(text) ;
DROP PROCEDURE IF EXISTS filedetector_mark_failed(text, text) ;

CREATE OR REPLACE PROCEDURE public.filedetector_mark_failed(__dataorigin text, __state text)
LANGUAGE 'plpgsql'
AS $BODY$
BEGIN
    UPDATE supplier_configurations
    SET 
       last_check_failure = now(),
       last_check = now(),
       last_checked = now(),
       state = __state
    WHERE 
        lower(name) = lower(__dataorigin);
END;
$BODY$;


