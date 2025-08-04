-- Table: public.stops

-- DROP TABLE IF EXISTS public.stops;

CREATE TABLE IF NOT EXISTS public.stops
(
    data_origin character varying(100) NOT NULL,
    id text NOT NULL,
    code text,
    name text,
    description text,
    latitude double precision NOT NULL,
    longitude double precision NOT NULL,
    geo_location geometry,
    zone text,
    url text,
    location_type integer,
    parent_station text,
    timezone text,
    wheelchair_boarding text,
    level_id text,
    platform_code text,
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

CREATE INDEX idx_stops_internal_id_data_origin 
ON stops(internal_id, data_origin);


-- DROP INDEX IF EXISTS public.example1_gpx;

CREATE INDEX IF NOT EXISTS example1_gpx
    ON public.stops USING gist
    (geography(geo_location))
    TABLESPACE pg_default;
-- Index: ix_stops_id

-- DROP INDEX IF EXISTS public.ix_stops_id;

CREATE INDEX IF NOT EXISTS ix_stops_id
    ON public.stops USING btree
    (id ASC NULLS LAST)
    TABLESPACE pg_default;
-- Index: ix_stops_id_data_origin

-- DROP INDEX IF EXISTS public.ix_stops_id_data_origin;

CREATE INDEX IF NOT EXISTS ix_stops_id_data_origin
    ON public.stops USING btree
    (id ASC NULLS LAST, data_origin ASC NULLS LAST)
    TABLESPACE pg_default;
-- Index: ix_stops_id_data_origin_stop_type

-- DROP INDEX IF EXISTS public.ix_stops_id_data_origin_stop_type;

CREATE INDEX IF NOT EXISTS ix_stops_id_data_origin_stop_type
    ON public.stops USING btree
    (id ASC NULLS LAST, data_origin ASC NULLS LAST, stop_type ASC NULLS LAST)
    TABLESPACE pg_default;

-- DROP INDEX IF EXISTS public.ix_stops_id_parent_station;

CREATE INDEX IF NOT EXISTS ix_stops_id_parent_station
    ON public.stops USING btree
    (id ASC NULLS LAST, parent_station ASC NULLS LAST)
    TABLESPACE pg_default;
-- Index: ix_stops_id_stop_type

-- DROP INDEX IF EXISTS public.ix_stops_id_stop_type;

CREATE INDEX IF NOT EXISTS ix_stops_id_stop_type
    ON public.stops USING btree
    (id ASC NULLS LAST, stop_type ASC NULLS LAST)
    TABLESPACE pg_default;
-- Index: ix_stops_import_id_data_origin

-- DROP INDEX IF EXISTS public.ix_stops_import_id_data_origin;

CREATE INDEX IF NOT EXISTS ix_stops_import_id_data_origin
    ON public.stops USING btree
    (import_id ASC NULLS LAST, data_origin ASC NULLS LAST)
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
    (name ASC NULLS LAST, stop_type ASC NULLS LAST)
    TABLESPACE pg_default;
-- Index: ix_stops_parent_station

-- DROP INDEX IF EXISTS public.ix_stops_parent_station;

CREATE INDEX IF NOT EXISTS ix_stops_parent_station
    ON public.stops USING btree
    (parent_station ASC NULLS LAST)
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
    


CREATE INDEX  IF NOT EXISTS ix_stops_name ON stops USING GIST (name gist_trgm_ops);
