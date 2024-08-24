
CREATE TABLE IF NOT EXISTS public.alerts
(
    data_origin character varying(100) COLLATE pg_catalog."default" NOT NULL,
    internal_id uuid NOT NULL,
    last_updated timestamp with time zone NOT NULL,

    active_periods uuid NULL,
    cause text NULL,
    effect text NULL,
    url uuid NULL,
    header_text uuid NULL,
    description_text uuid NULL,
    tts_header_text uuid NULL,
    tts_description_text uuid NULL,
    severity_level text NULL,
    CONSTRAINT pk_alerts PRIMARY KEY (data_origin, internal_id)
)