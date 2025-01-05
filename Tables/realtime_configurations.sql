-- Table: public.realtime_configurations

-- DROP TABLE IF EXISTS public.realtime_configurations;

CREATE TABLE IF NOT EXISTS public.realtime_configurations
(
    supplier_configuration_name text COLLATE pg_catalog."default" NOT NULL,
    polling_rate interval NOT NULL,
    last_attempt timestamp with time zone NULL,
    enabled boolean DEFAULT true,
    url text NOT NULL,
    header_secret text NULL,
    secret text NULL,
    CONSTRAINT realtime_configuration_pkey PRIMARY KEY (supplier_configuration_name, url)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.realtime_configurations
    OWNER to postgres;