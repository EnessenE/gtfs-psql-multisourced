CREATE TYPE public.calendar_dates_type AS (
    data_origin TEXT,
    service_id TEXT,
    date timestamp with time zone,
    exception_type_data INT,
    internal_id uuid,
    last_updated timestamp with time zone,
    import_id uuid
);