CREATE TYPE public.frequencies_type AS (
    data_origin TEXT,
    trip_id TEXT,
    start_time TIME,
    end_time TIME,
    headway_secs INT,
    exact_times INT,
    internal_id TEXT,
    last_updated timestamp with time zone,
    import_id TEXT
);