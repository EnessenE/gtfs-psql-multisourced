-- Table: public.shapes
--
-- Shape points per feed. Slimmed down: no geo_location column (it duplicated
-- latitude/longitude and nothing read it) and no duplicate/unused indexes.
-- The primary key on (id, data_origin, sequence, import_id) also serves as the
-- ON CONFLICT arbiter for upsert_shapes, so no separate unique index is needed.
-- ix_shapes_lat_lon is kept: get_map_shapes_in_bounds / get_routes_near_point
-- do bounding-box lookups on latitude/longitude.

-- DROP TABLE IF EXISTS public.shapes;

CREATE TABLE public.shapes
(
    data_origin character varying(100) NOT NULL,
    id text NOT NULL,
    sequence bigint NOT NULL,
    latitude double precision NOT NULL,
    longitude double precision NOT NULL,
    distance_travelled double precision,
    last_updated timestamp with time zone NOT NULL,
    import_id uuid DEFAULT '00000000-0000-0000-0000-000000000000'::uuid,
    CONSTRAINT pk_shapes PRIMARY KEY (id, data_origin, sequence, import_id)
)
TABLESPACE pg_default;


ALTER TABLE IF EXISTS public.shapes
    OWNER to postgres;

-- Index: ix_shapes_lat_lon (bounding-box lookups)

-- DROP INDEX IF EXISTS public.ix_shapes_lat_lon;

CREATE INDEX ix_shapes_lat_lon
    ON public.shapes USING btree
    (latitude ASC NULLS LAST, longitude ASC NULLS LAST)
    TABLESPACE pg_default;

-- Index: ix_shapes_import_id_data_origin (used by move_to_new_import's cleanup DELETE)

-- DROP INDEX IF EXISTS public.ix_shapes_import_id_data_origin;

CREATE INDEX ix_shapes_import_id_data_origin
    ON public.shapes USING btree
    (import_id ASC NULLS LAST, data_origin ASC NULLS LAST)
    TABLESPACE pg_default;
