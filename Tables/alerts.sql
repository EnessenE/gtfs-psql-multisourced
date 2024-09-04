
CREATE TABLE IF NOT EXISTS public.alerts
(
    data_origin character varying(100) COLLATE pg_catalog."default" NOT NULL,
    internal_id uuid NOT NULL,
    created timestamp with time zone NOT NULL default (timezone('utc', now())),
    last_updated timestamp with time zone NOT NULL,
    id text,
    is_deleted boolean default 'false',

    active_periods uuid NULL,
    cause text NULL,
    effect text NULL,
    url text NULL,
    header_text text NULL,
    description_text text NULL,
    tts_header_text text NULL,
    tts_description_text text NULL,
    severity_level text NULL,
    CONSTRAINT pk_alerts PRIMARY KEY (data_origin, id)
);

-- DROP INDEX IF EXISTS public.ix_alerts_id;

CREATE INDEX IF NOT EXISTS ix_alerts_id
    ON public.alerts USING btree
    (id COLLATE pg_catalog."default" ASC NULLS LAST)
    TABLESPACE pg_default;
-- Index: ix_alerts_id_data_origin

-- DROP INDEX IF EXISTS public.ix_alerts_id_data_origin;

CREATE INDEX IF NOT EXISTS ix_alerts_id_data_origin
    ON public.alerts USING btree
    (id COLLATE pg_catalog."default" ASC NULLS LAST, data_origin COLLATE pg_catalog."default" ASC NULLS LAST)
    TABLESPACE pg_default;
-- Index: ix_alerts_id_data_origin_stop_type