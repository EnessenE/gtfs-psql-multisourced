drop function if exists filedetector_get_all_suppliers();

CREATE OR REPLACE FUNCTION public.filedetector_get_all_suppliers()
RETURNS TABLE (
    name text,
    retrievaltype int,
    datatype int,
    polling_rate interval,
    url text,
    last_updated timestamp with time zone,
    download_pending boolean,
    import_id uuid,
    latest_succesfull_import_id uuid,
    last_attempt timestamp with time zone,
    e_tag text,
    last_check timestamp with time zone,
    last_check_failure timestamp with time zone,
    state text,
    last_import_start timestamp with time zone,
    last_import_success timestamp with time zone,
    last_import_failure timestamp with time zone,
    last_duration time,
    delay_import_by time,
    queued_import_id uuid,
    header_key text,
    header_value text
)
LANGUAGE sql
AS $$
    select 
        name,
        retrieval_type,
        data_type,
        polling_rate,
        url,
        last_updated,
        download_pending,
        import_id,
        latest_succesfull_import_id,
        last_attempt,
        e_tag,
        last_check,
        last_check_failure,
        state,
        last_import_start,
        last_import_success,
        last_import_failure,
        last_duration,
        delay_import_by,
        queued_import_id,
        header_key,
        header_value
    FROM supplier_configurations
    $$;
