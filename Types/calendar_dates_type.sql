CREATE TYPE public.calendar_dates_type AS (
    data_origin TEXT,
    service_id TEXT,
    date date,
    exception_type_data TEXT,
    internal_id uuid,
    last_updated timestamp with time zone,
    import_id uuid
);