CREATE TYPE public.calendar_dates_type AS (
    data_origin TEXT,
    service_id TEXT,
    date DATE,
    exception_type INT,
    internal_id TEXT,
    last_updated timestamp with time zone,
    import_id TEXT
);