CREATE TYPE public.routes_type AS (
    data_origin TEXT,
    id TEXT,
    agency_id TEXT,
    short_name TEXT,
    long_name TEXT,
    description TEXT,
    route_type_data integer,
    url TEXT,
    color TEXT,
    text_color TEXT,
    internal_id uuid,
    last_updated timestamp with time zone,
    import_id uuid
);