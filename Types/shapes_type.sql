CREATE TYPE public.shapes_type AS (
    internal_id uuid,
    data_origin TEXT,
    id TEXT,
    sequence_data DOUBLE PRECISION,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    distance_travelled DOUBLE PRECISION,
    last_updated timestamp with time zone,
    import_id uuid
);