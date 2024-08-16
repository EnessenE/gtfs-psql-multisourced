-- PROCEDURE: public.merge_stop(text, text)
-- DROP PROCEDURE IF EXISTS public.merge_stop(text, text);
CREATE OR REPLACE PROCEDURE public.update_supplier_for_download(IN target text, IN last_update timestamp with time zone, IN success boolean)
LANGUAGE 'plpgsql'
AS $BODY$
BEGIN
    UPDATE supplier_configurations
    SET 
        last_updated = last_update,
        download_pending = pending
    WHERE 
        lower(name) = lower(target);


    if success = true then
        UPDATE supplier_configurations
        SET 
            last_updated = last_update,
            download_pending = false,
            latest_succesfull_import_id = supplier_configurations.import_id
        WHERE 
            lower(name) = lower(target);
    elsif success = false then
        UPDATE supplier_configurations
        SET 
            last_updated = last_update,
            download_pending = false
        WHERE 
            lower(name) = lower(target);
    endif;
END;
$BODY$;

ALTER PROCEDURE public.update_supplier_for_download(text,  timestamp with time zone, boolean) OWNER TO dennis;

