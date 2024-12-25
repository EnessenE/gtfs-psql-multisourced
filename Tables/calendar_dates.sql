-- Table: public.calendar_dates

-- DROP TABLE IF EXISTS public.calendar_dates;

CREATE TABLE IF NOT EXISTS public.calendar_dates
(
    data_origin character varying(100) COLLATE pg_catalog."default" NOT NULL,
    service_id text COLLATE pg_catalog."default" NOT NULL,
    date timestamp with time zone NOT NULL,
    exception_type integer NOT NULL,
    internal_id uuid NOT NULL,
    last_updated timestamp with time zone NOT NULL,
    import_id uuid DEFAULT '00000000-0000-0000-0000-000000000000'::uuid,
    CONSTRAINT pk_calendar_dates PRIMARY KEY (data_origin, date, service_id)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.calendar_dates
    OWNER to postgres;
-- Index: ix_calendar_dates_date

-- DROP INDEX IF EXISTS public.ix_calendar_dates_date;

CREATE INDEX IF NOT EXISTS ix_calendar_dates_date
    ON public.calendar_dates USING btree
    (date ASC NULLS LAST)
    TABLESPACE pg_default;
-- Index: ix_calendar_dates_date_data_origin

-- DROP INDEX IF EXISTS public.ix_calendar_dates_date_data_origin;

CREATE INDEX IF NOT EXISTS ix_calendar_dates_date_data_origin
    ON public.calendar_dates USING btree
    (date ASC NULLS LAST, data_origin COLLATE pg_catalog."default" ASC NULLS LAST)
    TABLESPACE pg_default;
-- Index: ix_calendar_dates_import_id_data_origin

-- DROP INDEX IF EXISTS public.ix_calendar_dates_import_id_data_origin;

CREATE INDEX IF NOT EXISTS ix_calendar_dates_import_id_data_origin
    ON public.calendar_dates USING btree
    (import_id ASC NULLS LAST, data_origin COLLATE pg_catalog."default" ASC NULLS LAST)
    TABLESPACE pg_default;
-- Index: ix_calendar_dates_internal_id

-- DROP INDEX IF EXISTS public.ix_calendar_dates_internal_id;

CREATE INDEX IF NOT EXISTS ix_calendar_dates_internal_id
    ON public.calendar_dates USING btree
    (internal_id ASC NULLS LAST)
    TABLESPACE pg_default;
-- Index: ix_calendar_dates_service_id

-- DROP INDEX IF EXISTS public.ix_calendar_dates_service_id;

CREATE INDEX IF NOT EXISTS ix_calendar_dates_service_id
    ON public.calendar_dates USING btree
    (service_id COLLATE pg_catalog."default" ASC NULLS LAST)
    TABLESPACE pg_default;
-- Index: ix_calendar_dates_service_id_data_origin

-- DROP INDEX IF EXISTS public.ix_calendar_dates_service_id_data_origin;

CREATE INDEX IF NOT EXISTS ix_calendar_dates_service_id_data_origin
    ON public.calendar_dates USING btree
    (service_id COLLATE pg_catalog."default" ASC NULLS LAST, data_origin COLLATE pg_catalog."default" ASC NULLS LAST)
    TABLESPACE pg_default;