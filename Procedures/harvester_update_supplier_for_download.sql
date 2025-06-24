DROP PROCEDURE update_supplier_for_download(text,timestamp with time zone,boolean) ;

CREATE OR REPLACE PROCEDURE public.harvester_update_status(_)
LANGUAGE 'plpgsql'
AS $BODY$
BEGIN
    UPDATE supplier_configurations
    SET 
        last_updated = last_update,
        download_pending = false,
        latest_succesfull_import_id = supplier_configurations.import_id
    WHERE 
        lower(name) = lower(target);
END;
$BODY$;

ALTER PROCEDURE public.update_supplier_for_download(text,  timestamp with time zone, boolean) OWNER TO dennis;

