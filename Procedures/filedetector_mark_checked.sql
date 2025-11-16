DROP PROCEDURE IF EXISTS filedetector_mark_checked(text) ;
DROP PROCEDURE IF EXISTS filedetector_mark_checked(text, text) ;
DROP PROCEDURE IF EXISTS filedetector_mark_checked(text, text, uuid) ;

CREATE OR REPLACE PROCEDURE public.filedetector_mark_checked(__dataorigin text)
LANGUAGE 'plpgsql'
AS $BODY$
BEGIN
    UPDATE supplier_configurations
    SET 
       last_checked = now(),
       last_check = now()
    WHERE 
        lower(name) = lower(__dataorigin);
END;
$BODY$;

