drop type stop_times_type cascade;

CREATE TYPE public.stop_times_type AS (
    data_origin TEXT,
    trip_id TEXT,
    stop_id TEXT,
    stop_sequence_data double precision,
    arrival_time_data TIME,
    departure_time_data TIME,
    stop_headsign TEXT,
    pickup_type_data INT,
    drop_off_type_data INT,
    shape_dist_travelled DOUBLE PRECISION,
    days_since_start_arrival int,
    days_since_start_departure int,
    timepoint_type_data INT,
    internal_id uuid,
    last_updated timestamp with time zone,
    import_id uuid
);