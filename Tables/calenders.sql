-- Table: public.calendars

-- DROP TABLE IF EXISTS public.calendars;

CREATE TABLE IF NOT EXISTS public.calendars
(
    data_origin character varying(100) NOT NULL,
    service_id text NOT NULL,
    monday boolean NOT NULL,
    tuesday boolean NOT NULL,
    wednesday boolean NOT NULL,
    thursday boolean NOT NULL,
    friday boolean NOT NULL,
    saturday boolean NOT NULL,
    sunday boolean NOT NULL,
    start_date date NOT NULL,
    end_date date NOT NULL,
    internal_id uuid NOT NULL,
    last_updated timestamp with time zone NOT NULL,
    import_id uuid DEFAULT '00000000-0000-0000-0000-000000000000'::uuid,
    CONSTRAINT pk_calendars PRIMARY KEY (data_origin, service_id)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.calendars
    OWNER to postgres;
-- Index: ix_calendars_import_id_data_origin

-- DROP INDEX IF EXISTS public.ix_calendars_import_id_data_origin;

CREATE INDEX IF NOT EXISTS ix_calendars_import_id_data_origin
    ON public.calendars USING btree
    (import_id ASC NULLS LAST, data_origin ASC NULLS LAST)
    TABLESPACE pg_default;
-- Index: ix_calendars_internal_id

-- DROP INDEX IF EXISTS public.ix_calendars_internal_id;

CREATE INDEX IF NOT EXISTS ix_calendars_internal_id
    ON public.calendars USING btree
    (internal_id ASC NULLS LAST)
    TABLESPACE pg_default;
-- Index: ix_calendars_service_id_data_origin

-- DROP INDEX IF EXISTS public.ix_calendars_service_id_data_origin;

CREATE INDEX IF NOT EXISTS ix_calendars_service_id_data_origin
    ON public.calendars USING btree
    (service_id ASC NULLS LAST, data_origin ASC NULLS LAST)
    TABLESPACE pg_default;