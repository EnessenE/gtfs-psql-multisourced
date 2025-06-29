-- Table: public.routes

-- DROP TABLE IF EXISTS public.routes;

CREATE TABLE IF NOT EXISTS public.routes
(
    data_origin character varying(100) COLLATE pg_catalog."default" NOT NULL,
    id text COLLATE pg_catalog."default" NOT NULL,
    agency_id text COLLATE pg_catalog."default" DEFAULT 'Unknown'::text,
    short_name text COLLATE pg_catalog."default",
    long_name text COLLATE pg_catalog."default",
    description text COLLATE pg_catalog."default",
    type integer NOT NULL,
    url text COLLATE pg_catalog."default",
    color text COLLATE pg_catalog."default",
    text_color text COLLATE pg_catalog."default",
    internal_id uuid NOT NULL,
    last_updated timestamp with time zone NOT NULL,
    import_id uuid DEFAULT '00000000-0000-0000-0000-000000000000'::uuid,
    CONSTRAINT pk_routes PRIMARY KEY (data_origin, id)
);



ALTER TABLE IF EXISTS public.routes
    OWNER to postgres;
-- Index: ix_routes_agency_id

-- DROP INDEX IF EXISTS public.ix_routes_agency_id;

CREATE INDEX idx_routes_id_data_origin ON routes(id, data_origin);


CREATE INDEX IF NOT EXISTS ix_routes_agency_id
    ON public.routes USING btree
    (agency_id COLLATE pg_catalog."default" ASC NULLS LAST);
    
-- Index: ix_routes_id

-- DROP INDEX IF EXISTS public.ix_routes_id;

CREATE INDEX IF NOT EXISTS ix_routes_id
    ON public.routes USING btree
    (id COLLATE pg_catalog."default" ASC NULLS LAST);
    
-- Index: ix_routes_id_data_origin

-- DROP INDEX IF EXISTS public.ix_routes_id_data_origin;

CREATE INDEX IF NOT EXISTS ix_routes_id_data_origin
    ON public.routes USING btree
    (id COLLATE pg_catalog."default" ASC NULLS LAST, data_origin COLLATE pg_catalog."default" ASC NULLS LAST);
    
-- Index: ix_routes_import_id_data_origin

-- DROP INDEX IF EXISTS public.ix_routes_import_id_data_origin;

CREATE INDEX IF NOT EXISTS ix_routes_import_id_data_origin
    ON public.routes USING btree
    (import_id ASC NULLS LAST, data_origin COLLATE pg_catalog."default" ASC NULLS LAST);
    
-- Index: ix_routes_internal_id

-- DROP INDEX IF EXISTS public.ix_routes_internal_id;

CREATE INDEX IF NOT EXISTS ix_routes_internal_id
    ON public.routes USING btree
    (internal_id ASC NULLS LAST);
    
-- Index: ix_routes_long_name

-- DROP INDEX IF EXISTS public.ix_routes_long_name;

CREATE INDEX IF NOT EXISTS ix_routes_long_name
    ON public.routes USING btree
    (long_name COLLATE pg_catalog."default" ASC NULLS LAST);
    
-- Index: ix_routes_short_name

-- DROP INDEX IF EXISTS public.ix_routes_short_name;

CREATE INDEX IF NOT EXISTS ix_routes_short_name
    ON public.routes USING btree
    (short_name COLLATE pg_catalog."default" ASC NULLS LAST);
    