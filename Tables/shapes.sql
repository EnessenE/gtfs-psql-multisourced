-- Table: public.shapes

-- DROP TABLE IF EXISTS public.shapes;

CREATE TABLE public.shapes
(
    data_origin character varying(100) NOT NULL,
    id text NOT NULL,
    sequence bigint NOT NULL,
    latitude double precision NOT NULL,
    longitude double precision NOT NULL,
    geo_location geometry,
    distance_travelled double precision,
    last_updated timestamp with time zone NOT NULL,
    import_id uuid DEFAULT '00000000-0000-0000-0000-000000000000'::uuid,
    CONSTRAINT pk_shapes PRIMARY KEY (id, data_origin, sequence, import_id)
)
TABLESPACE pg_default;


ALTER TABLE IF EXISTS public.shapes
    OWNER to postgres;
-- Index: ix_shapes_id_data_origin

-- DROP INDEX IF EXISTS public.ix_shapes_id_data_origin;

CREATE INDEX ix_shapes_id_data_origin
    ON public.shapes USING btree
    (id ASC NULLS LAST, data_origin ASC NULLS LAST)
    TABLESPACE pg_default;
-- Index: ix_shapes_import_id_data_origin

-- DROP INDEX IF EXISTS public.ix_shapes_import_id_data_origin;

CREATE INDEX ix_shapes_import_id_data_origin
    ON public.shapes USING btree
    (import_id ASC NULLS LAST, data_origin ASC NULLS LAST)
    TABLESPACE pg_default;

CREATE INDEX IF NOT EXISTS ix_shapes_geo_location
    ON public.shapes USING gist (geo_location)
    TABLESPACE pg_default;

-- Btree index on latitude+longitude for fast bbox range queries
-- (used by get_map_shapes_in_bounds; works even if geo_location is unpopulated)
CREATE INDEX IF NOT EXISTS ix_shapes_lat_lon
    ON public.shapes USING btree (latitude, longitude)
    TABLESPACE pg_default;
-- Index: ix_shapes_internal_id
