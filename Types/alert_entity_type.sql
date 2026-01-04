CREATE TYPE public.alert_entity_type AS (
    data_origin text,
    id text,
    last_updated timestamp with time zone,
    agency_id text,
    route_id text,
    trip_id text,
    stop_id text
);

