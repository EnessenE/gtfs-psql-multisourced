CREATE TYPE public.shapes_type AS (
    internal_id uuid,
    data_origin TEXT,
    id TEXT,
    sequence INT,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    geo_location TEXT,
    distance_travelled DOUBLE PRECISION,
    last_updated timestamp with time zone,
    import_id uuid
);