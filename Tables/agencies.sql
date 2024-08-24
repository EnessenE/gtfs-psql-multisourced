-- Table: public.agencies

-- DROP TABLE IF EXISTS public.agencies;

CREATE TABLE IF NOT EXISTS public.agencies
(
    data_origin character varying(100) COLLATE pg_catalog."default" NOT NULL,
    id text COLLATE pg_catalog."default" NOT NULL,
    name text COLLATE pg_catalog."default",
    url text COLLATE pg_catalog."default",
    timezone text COLLATE pg_catalog."default",
    language_code text COLLATE pg_catalog."default",
    phone text COLLATE pg_catalog."default",
    fare_url text COLLATE pg_catalog."default",
    email text COLLATE pg_catalog."default",
    internal_id uuid NOT NULL,
    last_updated timestamp with time zone NOT NULL,
    import_id uuid DEFAULT '00000000-0000-0000-0000-000000000000'::uuid,
    CONSTRAINT pk_agencies PRIMARY KEY (data_origin, id)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.agencies
    OWNER to postgres;
-- Index: ix_agencies_id

-- DROP INDEX IF EXISTS public.ix_agencies_id;

CREATE INDEX IF NOT EXISTS ix_agencies_id
    ON public.agencies USING btree
    (id COLLATE pg_catalog."default" ASC NULLS LAST)
    TABLESPACE pg_default;
-- Index: ix_agencies_id_data_origin

-- DROP INDEX IF EXISTS public.ix_agencies_id_data_origin;

CREATE INDEX IF NOT EXISTS ix_agencies_id_data_origin
    ON public.agencies USING btree
    (id COLLATE pg_catalog."default" ASC NULLS LAST, data_origin COLLATE pg_catalog."default" ASC NULLS LAST)
    TABLESPACE pg_default;
-- Index: ix_agencies_id_name

-- DROP INDEX IF EXISTS public.ix_agencies_id_name;

CREATE INDEX IF NOT EXISTS ix_agencies_id_name
    ON public.agencies USING btree
    (id COLLATE pg_catalog."default" ASC NULLS LAST, name COLLATE pg_catalog."default" ASC NULLS LAST)
    TABLESPACE pg_default;
-- Index: ix_agencies_import_id_data_origin

-- DROP INDEX IF EXISTS public.ix_agencies_import_id_data_origin;

CREATE INDEX IF NOT EXISTS ix_agencies_import_id_data_origin
    ON public.agencies USING btree
    (import_id ASC NULLS LAST, data_origin COLLATE pg_catalog."default" ASC NULLS LAST)
    TABLESPACE pg_default;
-- Index: ix_agencies_internal_id

-- DROP INDEX IF EXISTS public.ix_agencies_internal_id;

CREATE INDEX IF NOT EXISTS ix_agencies_internal_id
    ON public.agencies USING btree
    (internal_id ASC NULLS LAST)
    TABLESPACE pg_default;