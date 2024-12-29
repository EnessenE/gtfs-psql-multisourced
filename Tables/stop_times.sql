-- Table: public.stop_times

-- DROP TABLE IF EXISTS public.stop_times;

CREATE TABLE IF NOT EXISTS public.stop_times
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
    CONSTRAINT pk_stop_times PRIMARY KEY (internal_id)
);


ALTER TABLE stop_times
ADD CONSTRAINT unique_stop_times UNIQUE (data_origin, trip_id, stop_id, stop_sequence, import_id);

CREATE UNIQUE INDEX ix_unique_stop_times ON stop_times (data_origin, trip_id, stop_id, stop_sequence, import_id);


ALTER TABLE IF EXISTS public.stop_times
    OWNER to postgres;
-- Index: ix_stop_times_arrival_time_departure_time

-- DROP INDEX IF EXISTS public.ix_stop_times_arrival_time_departure_time;

CREATE INDEX IF NOT EXISTS ix_stop_times_arrival_time_departure_time
    ON public.stop_times USING btree
    (arrival_time ASC NULLS LAST, departure_time ASC NULLS LAST)
    TABLESPACE pg_default;
-- Index: ix_stop_times_import_id_data_origin

-- DROP INDEX IF EXISTS public.ix_stop_times_import_id_data_origin;

CREATE INDEX IF NOT EXISTS ix_stop_times_import_id_data_origin
    ON public.stop_times USING btree
    (import_id ASC NULLS LAST, data_origin COLLATE pg_catalog."default" ASC NULLS LAST)
    TABLESPACE pg_default;
-- Index: ix_stop_times_internal_id

-- DROP INDEX IF EXISTS public.ix_stop_times_stop_id;

CREATE INDEX IF NOT EXISTS ix_stop_times_stop_id
    ON public.stop_times USING btree
    (stop_id COLLATE pg_catalog."default" ASC NULLS LAST)
    TABLESPACE pg_default;
-- Index: ix_stop_times_trip_id_data_origin

-- DROP INDEX IF EXISTS public.ix_stop_times_trip_id_data_origin;

CREATE INDEX IF NOT EXISTS ix_stop_times_trip_id_data_origin
    ON public.stop_times USING btree
    (trip_id COLLATE pg_catalog."default" ASC NULLS LAST, data_origin COLLATE pg_catalog."default" ASC NULLS LAST)
    TABLESPACE pg_default;


CREATE UNIQUE INDEX idx_stop_times_unique 
ON public.stop_times (data_origin, trip_id, stop_id, stop_sequence);
