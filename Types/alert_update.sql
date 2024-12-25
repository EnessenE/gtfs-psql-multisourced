CREATE TYPE public.alert_update AS (
    id text,
    data_origin TEXT,
    internal_id UUID,
    last_updated timestamp with time zone,
    effect TEXT,
    cause TEXT,
    severity_level TEXT,
    url TEXT,
    header_text TEXT,
    description_text TEXT
);
