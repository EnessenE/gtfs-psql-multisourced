-- drop table if exists trip_updates;
CREATE TABLE trip_updates(
    data_origin text,
    id text,
    trip_id text,
    internal_id uuid,
    last_updated timestamp with time zone,
    delay int,
    schedule_relationship text,
    vehicle_id text,
    vehicle_label text,
    vehicle_license_plate text,
    vehicle_wheelchair_accessible text,
    measurement_time timestamp with time zone,
    CONSTRAINT trip_updates_pkey PRIMARY KEY (data_origin, id)
);


CREATE INDEX IF NOT EXISTS ix_trip_updates_trip_id_data_origin  ON public.trip_updates USING btree (trip_id ASC NULLS LAST, data_origin);