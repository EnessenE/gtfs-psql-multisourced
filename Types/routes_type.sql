CREATE TYPE public.routes_type AS TABLE (
    data_origin TEXT,
    id TEXT,
    agency_id TEXT,
    short_name TEXT,
    long_name TEXT,
    description TEXT,
    type INT,
    url TEXT,
    color TEXT,
    text_color TEXT,
    internal_id TEXT,
    last_updated TIMESTAMPTZ,
    import_id TEXT
);