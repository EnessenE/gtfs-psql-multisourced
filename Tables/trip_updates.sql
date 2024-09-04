CREATE TABLE trip_updates(
    data_origin text,
    id text,
    internal_id uuid,
    last_updated timestamp with time zone,
    delay int,
    measurement_time timestamp with time zone,
    CONSTRAINT trip_updates_pkey PRIMARY KEY (data_origin, id)
);

