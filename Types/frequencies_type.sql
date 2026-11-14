DROP TYPE IF EXISTS public.frequencies_type CASCADE;

CREATE TYPE public.frequencies_type AS (
    data_origin TEXT,
    trip_id TEXT,
    start_time_data TIME,
    end_time_data TIME,
    headway_secs INT,
    exact_times_data INT,
    internal_id uuid,
    last_updated timestamp with time zone,
    import_id uuid
);
