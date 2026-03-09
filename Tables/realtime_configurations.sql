-- Table: public.realtime_configurations

-- DROP TABLE IF EXISTS public.realtime_configurations;

CREATE TABLE IF NOT EXISTS public.realtime_configurations
(
    supplier_configuration_name text COLLATE pg_catalog."default" NOT NULL,
    type text NOT NULL default('mixed'),
    polling_rate interval NOT NULL,
    last_attempt timestamp with time zone,
    url text COLLATE pg_catalog."default" NOT NULL,
    enabled boolean DEFAULT true,
    header text COLLATE pg_catalog."default",
    header_secret text COLLATE pg_catalog."default",
    credits text COLLATE pg_catalog."default",
    CONSTRAINT realtime_configuration_pkey PRIMARY KEY (supplier_configuration_name, url)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.realtime_configurations
    OWNER to postgres;

GRANT ALL ON TABLE public.realtime_configurations TO pgagent;

GRANT ALL ON TABLE public.realtime_configurations TO postgres;