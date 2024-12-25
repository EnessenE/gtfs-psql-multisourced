DROP PROCEDURE update_supplier_for_download(text,timestamp with time zone,boolean) ;

CREATE OR REPLACE PROCEDURE public.update_supplier_for_download(IN target text, IN last_update timestamp with time zone, IN successfully_downloaded boolean)
LANGUAGE 'plpgsql'
AS $BODY$
BEGIN
    if successfully_downloaded = true then
        UPDATE supplier_configurations
        SET 
            last_updated = last_update,
            download_pending = false,
            latest_succesfull_import_id = supplier_configurations.import_id
        WHERE 
            lower(name) = lower(target);
    elsif successfully_downloaded = false then
        UPDATE supplier_configurations
        SET 
            last_attempt = last_update,
            download_pending = false
        WHERE 
            lower(name) = lower(target);
    end if;
END;
$BODY$;

ALTER PROCEDURE public.update_supplier_for_download(text,  timestamp with time zone, boolean) OWNER TO dennis;

