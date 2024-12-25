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
    start_date DATE,
    end_date DATE,
    internal_id TEXT,
    last_updated TIMESTAMP,
    import_id TEXT
);