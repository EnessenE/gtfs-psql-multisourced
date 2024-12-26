CREATE TYPE public.agencies_type AS (
    data_origin TEXT,
    id TEXT,
    name TEXT,
    url TEXT,
    timezone TEXT,
    language_code TEXT,
    phone TEXT,
    fare_url TEXT,
    email TEXT,
    internal_id uuid,
    last_updated timestamp with time zone,
    import_id uuid
);