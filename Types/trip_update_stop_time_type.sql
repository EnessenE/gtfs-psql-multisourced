CREATE TYPE trip_update_stop_time_type AS (
    data_origin text,
    internal_id uuid,
    last_updated timestamp WITH time zone,
    stop_sequence int,
    stop_id text,
    arrival_delay int,
    arrival_time time WITHOUT time zone,
    arrival_uncertainty int,
    departure_delay int,
    departure_time time WITHOUT time zone,
    departure_uncertainty int,
    schedule_relationship text
);
