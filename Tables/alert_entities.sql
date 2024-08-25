
CREATE TABLE IF NOT EXISTS public.alert_entities
(
    data_origin character varying(100) COLLATE pg_catalog."default" NOT NULL,
    internal_id uuid NOT NULL,
    created timestamp with time zone NOT NULL default (select timezone('utc', now())),
    last_updated timestamp with time zone NOT NULL,
    agency_id text NULL,
    route_id text NULL,
    trip_id text NULL,
    stop_id text NULL,
    CONSTRAINT pk_alert_entities PRIMARY KEY (data_origin, internal_id)
)


