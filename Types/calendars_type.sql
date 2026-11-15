CREATE TYPE public.calendars_type AS (
    data_origin TEXT,
    service_id TEXT,
    monday BOOLEAN,
    tuesday BOOLEAN,
    wednesday BOOLEAN,
    thursday BOOLEAN,
    friday BOOLEAN,
    saturday BOOLEAN,
    sunday BOOLEAN,
    start_date date,
    end_date date,
    internal_id uuid,
    last_updated timestamp with time zone,
    import_id uuid
);