CREATE TYPE public.trips_type AS (
    data_origin TEXT,
    id TEXT,
    route_id TEXT,
    service_id TEXT,
    headsign TEXT,
    short_name TEXT,
    direction TEXT,
    block_id TEXT,
    shape_id TEXT,
    accessibility_type INT,
    internal_id TEXT,
    last_updated timestamp with time zone,
    import_id TEXT
);