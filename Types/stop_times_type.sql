CREATE TYPE public.stop_times_type AS (
    data_origin TEXT,
    trip_id TEXT,
    stop_id TEXT,
    stop_sequence INT,
    arrival_time TIME,
    departure_time TIME,
    stop_headsign TEXT,
    pickup_type INT,
    drop_off_type INT,
    shape_dist_travelled DOUBLE PRECISION,
    timepoint_type INT,
    internal_id TEXT,
    last_updated timestamp with time zone,
    import_id TEXT
);