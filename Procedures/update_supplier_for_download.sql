-- PROCEDURE: public.merge_stop(text, text)
-- DROP PROCEDURE IF EXISTS public.merge_stop(text, text);
CREATE OR REPLACE PROCEDURE public.update_supplier_for_download(IN target text, IN last_update timestamp with time zone, IN pending boolean)
LANGUAGE 'plpgsql'
AS $BODY$
BEGIN
    UPDATE supplier_configurations
    SET 
        last_updated = last_update,
        download_pending = pending
    WHERE 
        name = target;
END;
$BODY$;

ALTER PROCEDURE public.update_supplier_for_download(text,  timestamp with time zone, boolean) OWNER TO dennis;

