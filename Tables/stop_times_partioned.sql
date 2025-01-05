-- Table: public.stop_times

-- DROP TABLE IF EXISTS public.stop_times;

CREATE TABLE IF NOT EXISTS public.stop_times2
(
    data_origin character varying(100) COLLATE pg_catalog."default" NOT NULL,
    trip_id text COLLATE pg_catalog."default" NOT NULL,
    stop_id text COLLATE pg_catalog."default" NOT NULL,
    stop_sequence bigint NOT NULL,
    arrival_time time without time zone,
    departure_time time without time zone,
    stop_headsign text COLLATE pg_catalog."default",
    pickup_type integer,
    drop_off_type integer,
    shape_dist_travelled double precision,
    timepoint_type integer NOT NULL,
    internal_id uuid NOT NULL,
    last_updated timestamp with time zone NOT NULL,
    import_id uuid DEFAULT '00000000-0000-0000-0000-000000000000'::uuid,
    CONSTRAINT pk_stop_times2 PRIMARY KEY (data_origin, import_id, internal_id) 
) PARTITION BY RANGE (data_origin, import_id);

CREATE TABLE IF NOT EXISTS public.stop_times2_default PARTITION OF public.stop_times2
DEFAULT;

ALTER TABLE stop_times2
ADD CONSTRAINT unique_stop_times2 UNIQUE (data_origin, trip_id, stop_id, stop_sequence, import_id);

CREATE UNIQUE INDEX ix_unique_stop_times2 ON stop_times2 (data_origin, trip_id, stop_id, stop_sequence, import_id);

CREATE INDEX IF NOT EXISTS ix_stop_times2_pk
    ON public.stop_times2 USING btree
    (internal_id ASC NULLS LAST);

ALTER TABLE IF EXISTS public.stop_times2
    OWNER to postgres;
-- Index: ix_stop_times2_arrival_time_departure_time

-- DROP INDEX IF EXISTS public.ix_stop_times2_arrival_time_departure_time;

CREATE INDEX IF NOT EXISTS ix_stop_times2_arrival_time_departure_time
    ON public.stop_times2 USING btree
    (arrival_time ASC NULLS LAST, departure_time ASC NULLS LAST);
-- Index: ix_stop_times2_import_id_data_origin

-- DROP INDEX IF EXISTS public.ix_stop_times2_import_id_data_origin;


CREATE INDEX IF NOT EXISTS ix_stop_times2_stop_id
    ON public.stop_times2 USING btree
    (stop_id COLLATE pg_catalog."default" ASC NULLS LAST);
-- Index: ix_stop_times2_trip_id_data_origin

-- DROP INDEX IF EXISTS public.ix_stop_times2_trip_id_data_origin;

CREATE INDEX IF NOT EXISTS ix_stop_times2_trip_id_data_origin
    ON public.stop_times2 USING btree
    (trip_id COLLATE pg_catalog."default" ASC NULLS LAST, data_origin COLLATE pg_catalog."default" ASC NULLS LAST);