CREATE TYPE public.stop_times_type AS (
    data_origin TEXT,
    trip_id TEXT,
    stop_id TEXT,
    stop_sequence_data double precision,
    arrival_time TIME,
    departure_time TIME,
    stop_headsign TEXT,
    pickup_type_data INT,
    drop_off_type_data INT,
    shape_dist_travelled DOUBLE PRECISION,
    timepoint_type_data INT,
    internal_id uuid,
    last_updated timestamp with time zone,
    import_id uuid
);