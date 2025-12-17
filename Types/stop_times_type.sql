DROP TYPE IF EXISTS public.stop_times_type CASCADE;

CREATE TYPE public.stop_times_type AS (
    data_origin                  text,
    trip_id                      text,
    stop_id                      text,
    stop_sequence_data           double precision,
    arrival_time_data            time without time zone,
    departure_time_data          time without time zone,
    days_since_start_arrival     integer,
    days_since_start_departure   integer,
    stop_headsign                text,
    pickup_type_data             integer,
    drop_off_type_data           integer,
    shape_dist_travelled         double precision,
    timepoint_type_data          integer,
    last_updated                 timestamptz,
    import_id                    uuid
);
