-- Table: public.trips

-- DROP TABLE IF EXISTS public.trips;

CREATE TABLE IF NOT EXISTS public.trips
(
    data_origin character varying(100) COLLATE pg_catalog."default" NOT NULL,
    id text COLLATE pg_catalog."default" NOT NULL,
    route_id text COLLATE pg_catalog."default",
    service_id text COLLATE pg_catalog."default",
    headsign text COLLATE pg_catalog."default",
    short_name text COLLATE pg_catalog."default",
    direction integer,
    block_id text COLLATE pg_catalog."default",
    shape_id text COLLATE pg_catalog."default",
    accessibility_type integer,
    internal_id uuid NOT NULL,
    last_updated timestamp with time zone NOT NULL,
    import_id uuid DEFAULT '00000000-0000-0000-0000-000000000000'::uuid,
    CONSTRAINT pk_trips PRIMARY KEY (internal_id)
)


ALTER TABLE trips
ADD CONSTRAINT unique_trips UNIQUE (data_origin, id, import_id);

CREATE UNIQUE INDEX ix_unique_trips ON trips (data_origin, id, import_id);


TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.trips
    OWNER to postgres;
-- Index: ix_trips_id

-- DROP INDEX IF EXISTS public.ix_trips_id;

CREATE INDEX IF NOT EXISTS ix_trips_id
    ON public.trips USING btree
    (id COLLATE pg_catalog."default" ASC NULLS LAST)
    TABLESPACE pg_default;
-- Index: ix_trips_id_data_origin

-- DROP INDEX IF EXISTS public.ix_trips_id_data_origin;

CREATE INDEX IF NOT EXISTS ix_trips_id_data_origin
    ON public.trips USING btree
    (id COLLATE pg_catalog."default" ASC NULLS LAST, data_origin COLLATE pg_catalog."default" ASC NULLS LAST)
    TABLESPACE pg_default;
-- Index: ix_trips_import_id_data_origin

-- DROP INDEX IF EXISTS public.ix_trips_import_id_data_origin;

CREATE INDEX IF NOT EXISTS ix_trips_import_id_data_origin
    ON public.trips USING btree
    (import_id ASC NULLS LAST, data_origin COLLATE pg_catalog."default" ASC NULLS LAST)
    TABLESPACE pg_default;
-- Index: ix_trips_internal_id

-- DROP INDEX IF EXISTS public.ix_trips_internal_id;

CREATE INDEX IF NOT EXISTS ix_trips_internal_id
    ON public.trips USING btree
    (internal_id ASC NULLS LAST)
    TABLESPACE pg_default;
-- Index: ix_trips_route_id

-- DROP INDEX IF EXISTS public.ix_trips_route_id;

CREATE INDEX IF NOT EXISTS ix_trips_route_id
    ON public.trips USING btree
    (route_id COLLATE pg_catalog."default" ASC NULLS LAST)
    TABLESPACE pg_default;
-- Index: ix_trips_service_id

-- DROP INDEX IF EXISTS public.ix_trips_service_id;

CREATE INDEX IF NOT EXISTS ix_trips_service_id
    ON public.trips USING btree
    (service_id COLLATE pg_catalog."default" ASC NULLS LAST)
    TABLESPACE pg_default;
-- Index: ix_trips_service_id_data_origin

-- DROP INDEX IF EXISTS public.ix_trips_service_id_data_origin;

CREATE INDEX IF NOT EXISTS ix_trips_service_id_data_origin
    ON public.trips USING btree
    (service_id COLLATE pg_catalog."default" ASC NULLS LAST, data_origin COLLATE pg_catalog."default" ASC NULLS LAST)
    TABLESPACE pg_default;
-- Index: ix_trips_shape_id

-- DROP INDEX IF EXISTS public.ix_trips_shape_id;

CREATE INDEX IF NOT EXISTS ix_trips_shape_id
    ON public.trips USING btree
    (shape_id COLLATE pg_catalog."default" ASC NULLS LAST)
    TABLESPACE pg_default;