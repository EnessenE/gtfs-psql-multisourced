-- Table: public.shapes

-- DROP TABLE IF EXISTS public.shapes;

CREATE TABLE IF NOT EXISTS public.shapes
(
    internal_id uuid NOT NULL,
    data_origin character varying(100) COLLATE pg_catalog."default" NOT NULL,
    id text COLLATE pg_catalog."default" NOT NULL,
    sequence bigint NOT NULL,
    latitude double precision NOT NULL,
    longitude double precision NOT NULL,
    geo_location geometry,
    distance_travelled double precision,
    last_updated timestamp with time zone NOT NULL,
    import_id uuid DEFAULT '00000000-0000-0000-0000-000000000000'::uuid,
    CONSTRAINT pk_shapes PRIMARY KEY (data_origin, id, sequence)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.shapes
    OWNER to postgres;
-- Index: ix_shapes_id_data_origin

-- DROP INDEX IF EXISTS public.ix_shapes_id_data_origin;

CREATE INDEX IF NOT EXISTS ix_shapes_id_data_origin
    ON public.shapes USING btree
    (id COLLATE pg_catalog."default" ASC NULLS LAST, data_origin COLLATE pg_catalog."default" ASC NULLS LAST)
    TABLESPACE pg_default;
-- Index: ix_shapes_id_data_origin_sequence

-- DROP INDEX IF EXISTS public.ix_shapes_id_data_origin_sequence;

CREATE INDEX IF NOT EXISTS ix_shapes_id_data_origin_sequence
    ON public.shapes USING btree
    (id COLLATE pg_catalog."default" ASC NULLS LAST, data_origin COLLATE pg_catalog."default" ASC NULLS LAST, sequence ASC NULLS LAST)
    TABLESPACE pg_default;
-- Index: ix_shapes_import_id_data_origin

-- DROP INDEX IF EXISTS public.ix_shapes_import_id_data_origin;

CREATE INDEX IF NOT EXISTS ix_shapes_import_id_data_origin
    ON public.shapes USING btree
    (import_id ASC NULLS LAST, data_origin COLLATE pg_catalog."default" ASC NULLS LAST)
    TABLESPACE pg_default;
-- Index: ix_shapes_internal_id

-- DROP INDEX IF EXISTS public.ix_shapes_internal_id;

CREATE INDEX IF NOT EXISTS ix_shapes_internal_id
    ON public.shapes USING btree
    (internal_id ASC NULLS LAST)
    TABLESPACE pg_default;