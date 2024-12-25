CREATE TYPE public.calendar_dates_type AS TABLE (
    data_origin TEXT,
    service_id TEXT,
    date DATE,
    exception_type INT,
    internal_id TEXT,
    last_updated TIMESTAMPTZ,
    import_id TEXT
);