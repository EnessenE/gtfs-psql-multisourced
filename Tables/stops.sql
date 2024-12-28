-- Table: public.stops

-- DROP TABLE IF EXISTS public.stops;

CREATE TABLE IF NOT EXISTS public.stops
(
    data_origin character varying(100) COLLATE pg_catalog."default" NOT NULL,
    id text COLLATE pg_catalog."default" NOT NULL,
    code text COLLATE pg_catalog."default",
    name text COLLATE pg_catalog."default",
    description text COLLATE pg_catalog."default",
    latitude double precision NOT NULL,
    longitude double precision NOT NULL,
    geo_location geometry,
    zone text COLLATE pg_catalog."default",
    url text COLLATE pg_catalog."default",
    location_type integer,
    parent_station text COLLATE pg_catalog."default",
    timezone text COLLATE pg_catalog."default",
    wheelchair_boarding text COLLATE pg_catalog."default",
    level_id text COLLATE pg_catalog."default",
    platform_code text COLLATE pg_catalog."default",
    stop_type integer NOT NULL,
    internal_id uuid NOT NULL,
    last_updated timestamp with time zone NOT NULL,
    import_id uuid DEFAULT '00000000-0000-0000-0000-000000000000'::uuid,
    CONSTRAINT pk_stops PRIMARY KEY (data_origin, id)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.stops
    OWNER to postgres;
-- Index: example1_gpx

-- DROP INDEX IF EXISTS public.example1_gpx;

CREATE INDEX IF NOT EXISTS example1_gpx
    ON public.stops USING gist
    (geography(geo_location))
    TABLESPACE pg_default;
-- Index: ix_stops_id

-- DROP INDEX IF EXISTS public.ix_stops_id;

CREATE INDEX IF NOT EXISTS ix_stops_id
    ON public.stops USING btree
    (id COLLATE pg_catalog."default" ASC NULLS LAST)
    TABLESPACE pg_default;
-- Index: ix_stops_id_data_origin

-- DROP INDEX IF EXISTS public.ix_stops_id_data_origin;

CREATE INDEX IF NOT EXISTS ix_stops_id_data_origin
    ON public.stops USING btree
    (id COLLATE pg_catalog."default" ASC NULLS LAST, data_origin COLLATE pg_catalog."default" ASC NULLS LAST)
    TABLESPACE pg_default;
-- Index: ix_stops_id_data_origin_stop_type

-- DROP INDEX IF EXISTS public.ix_stops_id_data_origin_stop_type;

CREATE INDEX IF NOT EXISTS ix_stops_id_data_origin_stop_type
    ON public.stops USING btree
    (id COLLATE pg_catalog."default" ASC NULLS LAST, data_origin COLLATE pg_catalog."default" ASC NULLS LAST, stop_type ASC NULLS LAST)
    TABLESPACE pg_default;

-- DROP INDEX IF EXISTS public.ix_stops_id_parent_station;

CREATE INDEX IF NOT EXISTS ix_stops_id_parent_station
    ON public.stops USING btree
    (id COLLATE pg_catalog."default" ASC NULLS LAST, parent_station COLLATE pg_catalog."default" ASC NULLS LAST)
    TABLESPACE pg_default;
-- Index: ix_stops_id_stop_type

-- DROP INDEX IF EXISTS public.ix_stops_id_stop_type;

CREATE INDEX IF NOT EXISTS ix_stops_id_stop_type
    ON public.stops USING btree
    (id COLLATE pg_catalog."default" ASC NULLS LAST, stop_type ASC NULLS LAST)
    TABLESPACE pg_default;
-- Index: ix_stops_import_id_data_origin

-- DROP INDEX IF EXISTS public.ix_stops_import_id_data_origin;

CREATE INDEX IF NOT EXISTS ix_stops_import_id_data_origin
    ON public.stops USING btree
    (import_id ASC NULLS LAST, data_origin COLLATE pg_catalog."default" ASC NULLS LAST)
    TABLESPACE pg_default;
-- Index: ix_stops_internal_id

-- DROP INDEX IF EXISTS public.ix_stops_internal_id;

CREATE INDEX IF NOT EXISTS ix_stops_internal_id
    ON public.stops USING btree
    (internal_id ASC NULLS LAST)
    TABLESPACE pg_default;
-- Index: ix_stops_internal_id_stop_type

-- DROP INDEX IF EXISTS public.ix_stops_internal_id_stop_type;

CREATE INDEX IF NOT EXISTS ix_stops_internal_id_stop_type
    ON public.stops USING btree
    (internal_id ASC NULLS LAST, stop_type ASC NULLS LAST)
    TABLESPACE pg_default;
-- Index: ix_stops_name

-- DROP INDEX IF EXISTS public.ix_stops_name_stop_type;

CREATE INDEX IF NOT EXISTS ix_stops_name_stop_type
    ON public.stops USING btree
    (name COLLATE pg_catalog."default" ASC NULLS LAST, stop_type ASC NULLS LAST)
    TABLESPACE pg_default;
-- Index: ix_stops_parent_station

-- DROP INDEX IF EXISTS public.ix_stops_parent_station;

CREATE INDEX IF NOT EXISTS ix_stops_parent_station
    ON public.stops USING btree
    (parent_station COLLATE pg_catalog."default" ASC NULLS LAST)
    TABLESPACE pg_default;
-- Index: ix_stops_stop_type

-- DROP INDEX IF EXISTS public.ix_stops_stop_type;

CREATE INDEX IF NOT EXISTS ix_stops_stop_type
    ON public.stops USING btree
    (stop_type ASC NULLS LAST)
    TABLESPACE pg_default;
-- Index: stops_hash_stop_type

-- DROP INDEX IF EXISTS public.stops_hash_stop_type;

CREATE INDEX IF NOT EXISTS stops_hash_stop_type
    ON public.stops USING hash
    (stop_type)
    TABLESPACE pg_default;


CREATE INDEX ix_stops_name ON stops USING GIST (name gist_trgm_ops);
