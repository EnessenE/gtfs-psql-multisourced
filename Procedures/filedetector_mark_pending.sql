DROP PROCEDURE IF EXISTS filedetector_mark_pending(text) ;
DROP PROCEDURE IF EXISTS filedetector_mark_pending(text, text) ;

CREATE OR REPLACE PROCEDURE public.filedetector_mark_pending(__dataorigin text, __state text)
LANGUAGE 'plpgsql'
AS $BODY$
BEGIN
    UPDATE supplier_configurations
    SET 
       last_checked = now(),
       download_pending = true,
       state = __state
    WHERE 
        lower(name) = lower(__dataorigin);
END;
$BODY$;

ALTER PROCEDURE public.filedetector_mark_pending(text, text) OWNER TO dennis;

