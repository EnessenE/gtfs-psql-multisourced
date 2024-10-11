drop table if exists trip_updates_stop_times;

CREATE TABLE trip_updates_stop_times (
    data_origin text,
    internal_id uuid,
    last_updated timestamp WITH time zone,
    stop_sequence int,
    trip_id text,
    stop_id text,
    arrival_delay int,
    arrival_time timestamp with time zone,
    arrival_uncertainty int,
    departure_delay int,
    departure_time timestamp with time zone,
    departure_uncertainty int,
    schedule_relationship text,
    CONSTRAINT trip_updates_stop_times_pkey PRIMARY KEY (data_origin, trip_id, stop_id)
);


CREATE INDEX IF NOT EXISTS ix_trip_updates_stop_times_trip_id_data_origin
    ON public.trip_updates_stop_times USING btree
    (trip_id COLLATE pg_catalog."default" ASC NULLS LAST, data_origin COLLATE pg_catalog."default" ASC NULLS LAST)
    TABLESPACE pg_default;

CREATE INDEX IF NOT EXISTS ix_trip_updates_stop_times_trip_id_data_origin_stop_id
    ON public.trip_updates_stop_times USING btree
    (trip_id COLLATE pg_catalog."default" ASC NULLS LAST, data_origin COLLATE pg_catalog."default" ASC NULLS LAST, stop_id COLLATE pg_catalog."default" ASC NULLS LAST)
    TABLESPACE pg_default;