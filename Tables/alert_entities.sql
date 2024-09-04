CREATE TABLE IF NOT EXISTS public.alert_entities(
    data_origin character varying(100) NOT NULL,
    internal_id uuid NOT NULL,
    created timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now()),
    last_updated timestamp with time zone NOT NULL,
    agency_id text,
    route_id text,
    trip_id text,
    stop_id text,
    CONSTRAINT pk_alert_entities PRIMARY KEY (data_origin, internal_id)
);

-- Index: ix_alert_entities_id_data_origin
-- DROP INDEX IF EXISTS public.ix_alert_entities_id_data_origin;
CREATE INDEX IF NOT EXISTS ix_alert_entities_id_data_origin ON public.alert_entities USING btree(internal_id ASC NULLS LAST, data_origin ASC NULLS LAST) TABLESPACE pg_default;

-- Index: ix_alert_entities_id_data_origin_stop_type
