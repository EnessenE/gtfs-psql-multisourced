DROP PROCEDURE IF EXISTS filedetector_mark_pending(text) ;
DROP PROCEDURE IF EXISTS filedetector_mark_pending(text, text) ;
DROP PROCEDURE IF EXISTS filedetector_mark_pending(text, text, uuid) ;

CREATE OR REPLACE PROCEDURE public.filedetector_mark_pending(__dataorigin text, __state text, __new_uuid uuid, __etag text)
LANGUAGE 'plpgsql'
AS $BODY$
BEGIN
    UPDATE supplier_configurations
    SET 
       last_checked = now(),
       last_check = now(),
       download_pending = true,
       state = __state,
       queued_import_id = __new_uuid,
       e_tag = __etag
    WHERE 
        lower(name) = lower(__dataorigin);
END;
$BODY$;

