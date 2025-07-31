drop function if exists filedetector_get_all_suppliers();

CREATE OR REPLACE FUNCTION public.filedetector_get_all_suppliers()
RETURNS TABLE (
    name text,
    retrieval_type int,
    data_type int,
    polling_rate interval,
    url text,
    last_updated timestamptz,
    download_pending boolean,
    import_id uuid,
    latest_succesfull_import_id uuid,
    last_attempt timestamptz,
    e_tag text,
    last_checked timestamptz,
    last_check_failure timestamptz,
    state text,
    last_import_start timestamptz,
    last_import_success timestamptz,
    last_import_failure timestamptz,
    last_duration time,
    queued_import_id uuid
)
LANGUAGE sql
AS $$
    select name,
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
    last_checked,
    last_check_failure,
    state,
    last_import_start,
    last_import_success,
    last_import_failure,
    last_duration,
    queued_import_id
    FROM supplier_configurations
    $$;
