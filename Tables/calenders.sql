-- Table: public.calenders

-- DROP TABLE IF EXISTS public.calenders;

CREATE TABLE IF NOT EXISTS public.calenders
(
    data_origin character varying(100) COLLATE pg_catalog."default" NOT NULL,
    service_id text COLLATE pg_catalog."default" NOT NULL,
    mask smallint NOT NULL,
    monday boolean NOT NULL,
    tuesday boolean NOT NULL,
    wednesday boolean NOT NULL,
    thursday boolean NOT NULL,
    friday boolean NOT NULL,
    saturday boolean NOT NULL,
    sunday boolean NOT NULL,
    start_date timestamp with time zone NOT NULL,
    end_date timestamp with time zone NOT NULL,
    internal_id uuid NOT NULL,
    last_updated timestamp with time zone NOT NULL,
    import_id uuid DEFAULT '00000000-0000-0000-0000-000000000000'::uuid,
    CONSTRAINT pk_calenders PRIMARY KEY (data_origin, service_id)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.calenders
    OWNER to postgres;
-- Index: ix_calenders_import_id_data_origin

-- DROP INDEX IF EXISTS public.ix_calenders_import_id_data_origin;

CREATE INDEX IF NOT EXISTS ix_calenders_import_id_data_origin
    ON public.calenders USING btree
    (import_id ASC NULLS LAST, data_origin COLLATE pg_catalog."default" ASC NULLS LAST)
    TABLESPACE pg_default;
-- Index: ix_calenders_internal_id

-- DROP INDEX IF EXISTS public.ix_calenders_internal_id;

CREATE INDEX IF NOT EXISTS ix_calenders_internal_id
    ON public.calenders USING btree
    (internal_id ASC NULLS LAST)
    TABLESPACE pg_default;
-- Index: ix_calenders_service_id_data_origin

-- DROP INDEX IF EXISTS public.ix_calenders_service_id_data_origin;

CREATE INDEX IF NOT EXISTS ix_calenders_service_id_data_origin
    ON public.calenders USING btree
    (service_id COLLATE pg_catalog."default" ASC NULLS LAST, data_origin COLLATE pg_catalog."default" ASC NULLS LAST)
    TABLESPACE pg_default;