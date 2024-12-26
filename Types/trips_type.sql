CREATE TYPE public.trips_type AS (
    data_origin TEXT,
    id TEXT,
    route_id TEXT,
    service_id TEXT,
    headsign TEXT,
    short_name TEXT,
    direction_type int,
    block_id TEXT,
    shape_id TEXT,
    accessibility_type_data INT,
    internal_id uuid,
    last_updated timestamp with time zone,
    import_id uuid
);