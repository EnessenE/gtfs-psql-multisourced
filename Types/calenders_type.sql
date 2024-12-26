CREATE TYPE public.calenders_type AS (
    data_origin TEXT,
    service_id TEXT,
    monday BOOLEAN,
    tuesday BOOLEAN,
    wednesday BOOLEAN,
    thursday BOOLEAN,
    friday BOOLEAN,
    saturday BOOLEAN,
    sunday BOOLEAN,
    start_date timestamp with time zone,
    end_date timestamp with time zone,
    internal_id uuid,
    last_updated timestamp with time zone,
    import_id uuid
);