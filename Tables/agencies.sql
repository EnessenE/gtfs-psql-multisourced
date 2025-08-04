-- Table: public.agencies

-- DROP TABLE IF EXISTS public.agencies;

CREATE TABLE IF NOT EXISTS public.agencies
(
    data_origin character varying(100) NOT NULL,
    id text NOT NULL,
    name text,
    url text,
    timezone text,
    language_code text,
    phone text,
    fare_url text,
    email text,
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
    (id ASC NULLS LAST)
    TABLESPACE pg_default;
-- Index: ix_agencies_id_data_origin

-- DROP INDEX IF EXISTS public.ix_agencies_id_data_origin;

CREATE INDEX IF NOT EXISTS ix_agencies_id_data_origin
    ON public.agencies USING btree
    (id ASC NULLS LAST, data_origin ASC NULLS LAST)
    TABLESPACE pg_default;
-- Index: ix_agencies_id_name

-- DROP INDEX IF EXISTS public.ix_agencies_id_name;

CREATE INDEX IF NOT EXISTS ix_agencies_id_name
    ON public.agencies USING btree
    (id ASC NULLS LAST, name ASC NULLS LAST)
    TABLESPACE pg_default;
-- Index: ix_agencies_import_id_data_origin

-- DROP INDEX IF EXISTS public.ix_agencies_import_id_data_origin;

CREATE INDEX IF NOT EXISTS ix_agencies_import_id_data_origin
    ON public.agencies USING btree
    (import_id ASC NULLS LAST, data_origin ASC NULLS LAST)
    TABLESPACE pg_default;
-- Index: ix_agencies_internal_id

-- DROP INDEX IF EXISTS public.ix_agencies_internal_id;

CREATE INDEX IF NOT EXISTS ix_agencies_internal_id
    ON public.agencies USING btree
    (internal_id ASC NULLS LAST)
    TABLESPACE pg_default;